
"use client";

import { useCallback, useEffect, useState } from "react";

type Course = {
  id: number;
  title: string;
  description: string;
  language: string;
  is_active: boolean;
};

const API_URL = "http://127.0.0.1:8000/api/courses/";

export default function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [language, setLanguage] = useState("en");
  const [isActive, setIsActive] = useState(true);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const loadCourses = useCallback(async () => {
    const token = sessionStorage.getItem("admin_token");

    if (!token) {
      window.location.href = "/login?next=/courses";
      return;
    }

    try {
      const response = await fetch(`${API_URL}manage/`, {
        headers: { Authorization: `Token ${token}` },
      });

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login?next=/courses";
        return;
      }

      if (!response.ok) {
        throw new Error(`Unable to load courses (${response.status}).`);
      }

      const data = await response.json();
      setCourses(Array.isArray(data) ? data : data.results ?? []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load courses.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadCourses();
  }, [loadCourses]);

  function resetForm() {
    setEditingId(null);
    setTitle("");
    setDescription("");
    setLanguage("en");
    setIsActive(true);
  }

  function startEditing(course: Course) {
    setEditingId(course.id);
    setTitle(course.title);
    setDescription(course.description);
    setLanguage(course.language);
    setIsActive(course.is_active);
    setError("");
    setSuccess("");
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setSuccess("");
    setSaving(true);

    const token = sessionStorage.getItem("admin_token");

    if (!token) {
      window.location.href = "/login?next=/courses";
      return;
    }

    try {
      const editing = editingId !== null;
      const url = editing
        ? `${API_URL}${editingId}/manage/`
        : `${API_URL}create/`;

      const response = await fetch(url, {
        method: editing ? "PATCH" : "POST",
        headers: {
          Authorization: `Token ${token}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({
          title: title.trim(),
          description: description.trim(),
          language: language.trim(),
          is_active: isActive,
        }),
      });

      const data = await response.json();

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login?next=/courses";
        return;
      }

      if (!response.ok) {
        throw new Error(
          data.title?.[0] ??
          data.language?.[0] ??
          data.detail ??
          data.message ??
          `Request failed (${response.status}).`
        );
      }

      setSuccess(
        data.message ??
          (editing ? "Course updated successfully." : "Course created successfully.")
      );
      resetForm();
      await loadCourses();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Request failed.");
    } finally {
      setSaving(false);
    }
  }

  async function toggleCourse(course: Course) {
    setError("");
    setSuccess("");

    const token = sessionStorage.getItem("admin_token");

    if (!token) {
      window.location.href = "/login?next=/courses";
      return;
    }

    try {
      const response = await fetch(`${API_URL}${course.id}/manage/`, {
        method: "PATCH",
        headers: {
          Authorization: `Token ${token}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({ is_active: !course.is_active }),
      });

      const data = await response.json();

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login?next=/courses";
        return;
      }

      if (!response.ok) {
        throw new Error(data.detail ?? "Unable to update course status.");
      }

      setSuccess(data.message ?? "Course status updated.");
      await loadCourses();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to update course.");
    }
  }

  return (
    <main className="min-h-screen bg-slate-100 p-6 text-slate-900 md:p-10">
      <div className="mx-auto max-w-7xl space-y-8">
        <a href="/" className="text-sm text-blue-600 hover:underline">
          &larr; Back to Dashboard
        </a>

        <header>
          <h1 className="text-3xl font-bold">Courses</h1>
          <p className="mt-2 text-slate-600">
            Create, edit, activate and deactivate courses.
          </p>
        </header>

        <section className="rounded-xl bg-white p-6 shadow-sm">
          <h2 className="mb-5 text-xl font-semibold">
            {editingId !== null ? `Edit Course #${editingId}` : "Create Course"}
          </h2>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label htmlFor="title" className="mb-1 block text-sm font-medium">
                Course title
              </label>
              <input
                id="title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
                maxLength={200}
                className="w-full rounded-lg border border-slate-300 px-3 py-2"
                placeholder="Enter course title"
              />
            </div>

            <div>
              <label htmlFor="description" className="mb-1 block text-sm font-medium">
                Description
              </label>
              <textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                rows={3}
                className="w-full rounded-lg border border-slate-300 px-3 py-2"
                placeholder="Describe the course"
              />
            </div>

            <div>
              <label htmlFor="language" className="mb-1 block text-sm font-medium">
                Language code
              </label>
              <input
                id="language"
                value={language}
                onChange={(e) => setLanguage(e.target.value)}
                required
                maxLength={10}
                className="w-full rounded-lg border border-slate-300 px-3 py-2"
                placeholder="en, hi, mr"
              />
              <p className="mt-1 text-xs text-slate-500">
                Use a language code such as en, hi or mr.
              </p>
            </div>

            <label className="flex items-center gap-3 text-sm">
              <input
                type="checkbox"
                checked={isActive}
                onChange={(e) => setIsActive(e.target.checked)}
                className="h-4 w-4"
              />
              Course is active
            </label>

            {error && (
              <p role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-700">
                {error}
              </p>
            )}

            {success && (
              <p role="status" className="rounded-lg bg-green-50 p-3 text-sm text-green-700">
                {success}
              </p>
            )}

            <div className="flex flex-wrap gap-3">
              <button
                type="submit"
                disabled={saving}
                className="rounded-lg bg-blue-600 px-5 py-2.5 font-medium text-white hover:bg-blue-700 disabled:opacity-60"
              >
                {saving
                  ? "Saving..."
                  : editingId !== null
                    ? "Save Changes"
                    : "Create Course"}
              </button>

              {editingId !== null && (
                <button
                  type="button"
                  onClick={resetForm}
                  className="rounded-lg border border-slate-300 px-5 py-2.5"
                >
                  Cancel Edit
                </button>
              )}
            </div>
          </form>
        </section>

        <section className="rounded-xl bg-white p-6 shadow-sm">
          <div className="mb-5 flex items-center justify-between">
            <h2 className="text-xl font-semibold">All Courses</h2>
            <span className="rounded-full bg-blue-50 px-3 py-1 text-sm text-blue-700">
              Total: {courses.length}
            </span>
          </div>

          {loading ? (
            <p className="text-slate-500">Loading courses...</p>
          ) : courses.length === 0 ? (
            <p className="text-slate-500">No courses found.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b bg-slate-50 text-slate-600">
                  <tr>
                    <th className="p-3">ID</th>
                    <th className="p-3">Title</th>
                    <th className="p-3">Language</th>
                    <th className="p-3">Description</th>
                    <th className="p-3">Status</th>
                    <th className="p-3">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {courses.map((course) => (
                    <tr key={course.id} className="border-b last:border-0">
                      <td className="p-3">{course.id}</td>
                      <td className="p-3 font-medium">{course.title}</td>
                      <td className="p-3">{course.language}</td>
                      <td className="max-w-sm p-3">{course.description || "—"}</td>
                      <td className="p-3">
                        <span className={
                          course.is_active
                            ? "rounded-full bg-green-50 px-2 py-1 text-green-700"
                            : "rounded-full bg-slate-100 px-2 py-1 text-slate-600"
                        }>
                          {course.is_active ? "Active" : "Inactive"}
                        </span>
                      </td>
                      <td className="p-3">
                        <div className="flex flex-wrap gap-2">
                          <button
                            type="button"
                            onClick={() => startEditing(course)}
                            className="rounded-md border border-slate-300 px-3 py-1.5 hover:bg-slate-50"
                          >
                            Edit
                          </button>
                          <button
                            type="button"
                            onClick={() => void toggleCourse(course)}
                            className="rounded-md border border-slate-300 px-3 py-1.5 hover:bg-slate-50"
                          >
                            {course.is_active ? "Deactivate" : "Activate"}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
