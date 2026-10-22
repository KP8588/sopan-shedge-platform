
"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";

type Course = {
  id: number;
  title: string;
  is_active: boolean;
};

type Trainer = {
  id: number;
  username: string;
  email: string;
  role: string;
};

type Classroom = {
  id: number;
  course: number;
  title: string;
  trainer: number;
  scheduled_at: string;
  duration_minutes: number;
  meeting_url: string;
  is_active: boolean;
};

const API_URL = "http://127.0.0.1:8000/api";
const EMPTY_FORM = {
  title: "",
  course: "",
  trainer: "",
  scheduled_at: "",
  duration_minutes: "60",
  meeting_url: "",
  is_active: true,
};

function toLocalDateTime(value: string) {
  const date = new Date(value);
  const local = new Date(
    date.getTime() - date.getTimezoneOffset() * 60000
  );
  return local.toISOString().slice(0, 16);
}

export default function ClassroomsPage() {
  const [classrooms, setClassrooms] = useState<Classroom[]>([]);
  const [courses, setCourses] = useState<Course[]>([]);
  const [trainers, setTrainers] = useState<Trainer[]>([]);
  const [form, setForm] = useState(EMPTY_FORM);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const loadData = useCallback(async () => {
    const token = sessionStorage.getItem("admin_token");

    if (!token) {
      window.location.href = "/login?next=/classrooms";
      return;
    }

    const headers = {
      Authorization: `Token ${token}`,
      Accept: "application/json",
    };

    try {
      const [classResponse, courseResponse, trainerResponse] =
        await Promise.all([
          fetch(`${API_URL}/classrooms/manage/`, { headers }),
          fetch(`${API_URL}/courses/manage/`, { headers }),
          fetch(`${API_URL}/auth/users/`, { headers }),
        ]);

      if (
        [classResponse, courseResponse, trainerResponse].some(
          (response) => response.status === 401 || response.status === 403
        )
      ) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login?next=/classrooms";
        return;
      }

      if (!classResponse.ok || !courseResponse.ok || !trainerResponse.ok) {
        throw new Error(
          "Unable to load classrooms, courses, or trainers. Check the backend APIs."
        );
      }

      const [classData, courseData, trainerData] = await Promise.all([
        classResponse.json(),
        courseResponse.json(),
        trainerResponse.json(),
      ]);

      setClassrooms(
        Array.isArray(classData) ? classData : classData.results ?? []
      );
      setCourses(
        (Array.isArray(courseData) ? courseData : courseData.results ?? [])
          .filter((course: Course) => course.is_active)
      );
      setTrainers(
        (Array.isArray(trainerData) ? trainerData : trainerData.results ?? [])
          .filter((trainer: Trainer) => trainer.role === "TRAINER")
      );
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Unable to load dashboard data."
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  function resetForm() {
    setForm(EMPTY_FORM);
    setEditingId(null);
  }

  function startEditing(classroom: Classroom) {
    setEditingId(classroom.id);
    setForm({
      title: classroom.title,
      course: String(classroom.course),
      trainer: String(classroom.trainer),
      scheduled_at: toLocalDateTime(classroom.scheduled_at),
      duration_minutes: String(classroom.duration_minutes),
      meeting_url: classroom.meeting_url || "",
      is_active: classroom.is_active,
    });
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
      window.location.href = "/login?next=/classrooms";
      setSaving(false);
      return;
    }

    try {
      const editing = editingId !== null;
      const url = editing
        ? `${API_URL}/classrooms/${editingId}/manage/`
        : `${API_URL}/classrooms/manage/`;

      const payload = {
        title: form.title.trim(),
        course: Number(form.course),
        trainer: Number(form.trainer),
        scheduled_at: new Date(form.scheduled_at).toISOString(),
        duration_minutes: Number(form.duration_minutes),
        meeting_url: form.meeting_url.trim(),
        is_active: form.is_active,
      };

      const response = await fetch(url, {
        method: editing ? "PATCH" : "POST",
        headers: {
          Authorization: `Token ${token}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify(payload),
      });

      const data = await response.json();

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login?next=/classrooms";
        return;
      }

      if (!response.ok) {
        const details =
          data.detail ??
          data.course?.[0] ??
          data.trainer?.[0] ??
          data.scheduled_at?.[0] ??
          data.title?.[0] ??
          data.duration_minutes?.[0] ??
          "Unable to save classroom. Check all fields.";

        throw new Error(
          typeof details === "string" ? details : JSON.stringify(details)
        );
      }

      setSuccess(
        data.message ??
          (editing
            ? "Classroom updated successfully."
            : "Classroom created successfully.")
      );

      resetForm();
      await loadData();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Unable to save classroom."
      );
    } finally {
      setSaving(false);
    }
  }

  async function toggleClassroom(classroom: Classroom) {
    setError("");
    setSuccess("");

    const token = sessionStorage.getItem("admin_token");

    if (!token) {
      window.location.href = "/login?next=/classrooms";
      return;
    }

    try {
      const response = await fetch(
        `${API_URL}/classrooms/${classroom.id}/manage/`,
        {
          method: "PATCH",
          headers: {
            Authorization: `Token ${token}`,
            "Content-Type": "application/json",
            Accept: "application/json",
          },
          body: JSON.stringify({ is_active: !classroom.is_active }),
        }
      );

      const data = await response.json();

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login?next=/classrooms";
        return;
      }

      if (!response.ok) {
        throw new Error(data.detail ?? "Unable to update classroom status.");
      }

      setSuccess(data.message ?? "Classroom status updated.");
      await loadData();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Unable to update classroom."
      );
    }
  }

  function courseName(id: number) {
    return courses.find((course) => course.id === id)?.title ?? `Course #${id}`;
  }

  function trainerName(id: number) {
    return (
      trainers.find((trainer) => trainer.id === id)?.username ??
      `Trainer #${id}`
    );
  }

  return (
    <main className="min-h-screen bg-slate-100 p-6 text-slate-900 md:p-10">
      <div className="mx-auto max-w-7xl space-y-8">
        <Link href="/" className="text-sm text-blue-600 hover:underline">
          &larr; Back to Dashboard
        </Link>

        <header>
          <h1 className="text-3xl font-bold">Classroom Management</h1>
          <p className="mt-2 text-slate-600">
            Schedule classes, assign courses and trainers, and manage class
            availability.
          </p>
        </header>

        <section className="rounded-xl bg-white p-6 shadow-sm">
          <h2 className="mb-5 text-xl font-semibold">
            {editingId !== null
              ? `Edit Classroom #${editingId}`
              : "Create Classroom"}
          </h2>

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label htmlFor="title" className="mb-1 block text-sm font-medium">
                Classroom title
              </label>
              <input
                id="title"
                value={form.title}
                onChange={(e) =>
                  setForm({ ...form, title: e.target.value })
                }
                required
                maxLength={200}
                className="w-full rounded-lg border border-slate-300 px-3 py-2"
                placeholder="e.g. General Studies Live Class"
              />
            </div>

            <div className="grid gap-5 md:grid-cols-2">
              <div>
                <label htmlFor="course" className="mb-1 block text-sm font-medium">
                  Course
                </label>
                <select
                  id="course"
                  value={form.course}
                  onChange={(e) =>
                    setForm({ ...form, course: e.target.value })
                  }
                  required
                  className="w-full rounded-lg border border-slate-300 px-3 py-2"
                >
                  <option value="">Select a course</option>
                  {courses.map((course) => (
                    <option key={course.id} value={course.id}>
                      {course.title}
                    </option>
                  ))}
                </select>
                {courses.length === 0 && (
                  <p className="mt-1 text-xs text-amber-700">
                    Create or activate a course first.
                  </p>
                )}
              </div>

              <div>
                <label htmlFor="trainer" className="mb-1 block text-sm font-medium">
                  Trainer
                </label>
                <select
                  id="trainer"
                  value={form.trainer}
                  onChange={(e) =>
                    setForm({ ...form, trainer: e.target.value })
                  }
                  required
                  className="w-full rounded-lg border border-slate-300 px-3 py-2"
                >
                  <option value="">Select a trainer</option>
                  {trainers.map((trainer) => (
                    <option key={trainer.id} value={trainer.id}>
                      {trainer.username}
                    </option>
                  ))}
                </select>
                {trainers.length === 0 && (
                  <p className="mt-1 text-xs text-amber-700">
                    Create a trainer account first.
                  </p>
                )}
              </div>
            </div>

            <div className="grid gap-5 md:grid-cols-2">
              <div>
                <label htmlFor="scheduled_at" className="mb-1 block text-sm font-medium">
                  Date and time
                </label>
                <input
                  id="scheduled_at"
                  type="datetime-local"
                  value={form.scheduled_at}
                  onChange={(e) =>
                    setForm({ ...form, scheduled_at: e.target.value })
                  }
                  required
                  className="w-full rounded-lg border border-slate-300 px-3 py-2"
                />
              </div>

              <div>
                <label htmlFor="duration" className="mb-1 block text-sm font-medium">
                  Duration (minutes)
                </label>
                <input
                  id="duration"
                  type="number"
                  min={1}
                  max={1440}
                  value={form.duration_minutes}
                  onChange={(e) =>
                    setForm({ ...form, duration_minutes: e.target.value })
                  }
                  required
                  className="w-full rounded-lg border border-slate-300 px-3 py-2"
                />
              </div>
            </div>

            <div>
              <label htmlFor="meeting_url" className="mb-1 block text-sm font-medium">
                Meeting URL (optional)
              </label>
              <input
                id="meeting_url"
                type="url"
                value={form.meeting_url}
                onChange={(e) =>
                  setForm({ ...form, meeting_url: e.target.value })
                }
                className="w-full rounded-lg border border-slate-300 px-3 py-2"
                placeholder="https://..."
              />
            </div>

            <label className="flex items-center gap-3 text-sm">
              <input
                type="checkbox"
                checked={form.is_active}
                onChange={(e) =>
                  setForm({ ...form, is_active: e.target.checked })
                }
                className="h-4 w-4"
              />
              Classroom is active
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
                disabled={saving || courses.length === 0 || trainers.length === 0}
                className="rounded-lg bg-blue-600 px-5 py-2.5 font-medium text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {saving
                  ? "Saving..."
                  : editingId !== null
                    ? "Save Changes"
                    : "Create Classroom"}
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
            <h2 className="text-xl font-semibold">All Classrooms</h2>
            <span className="rounded-full bg-blue-50 px-3 py-1 text-sm text-blue-700">
              Total: {classrooms.length}
            </span>
          </div>

          {loading ? (
            <p className="text-slate-500">Loading classrooms...</p>
          ) : classrooms.length === 0 ? (
            <p className="text-slate-500">No classrooms found.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b bg-slate-50 text-slate-600">
                  <tr>
                    <th className="p-3">ID</th>
                    <th className="p-3">Classroom</th>
                    <th className="p-3">Course</th>
                    <th className="p-3">Trainer</th>
                    <th className="p-3">Schedule</th>
                    <th className="p-3">Duration</th>
                    <th className="p-3">Status</th>
                    <th className="p-3">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {classrooms.map((classroom) => (
                    <tr key={classroom.id} className="border-b last:border-0">
                      <td className="p-3">{classroom.id}</td>
                      <td className="p-3 font-medium">
                        {classroom.title}
                        {classroom.meeting_url && (
                          <a
                            href={classroom.meeting_url}
                            target="_blank"
                            rel="noreferrer"
                            className="mt-1 block text-xs text-blue-600 hover:underline"
                          >
                            Open meeting link
                          </a>
                        )}
                      </td>
                      <td className="p-3">{courseName(classroom.course)}</td>
                      <td className="p-3">{trainerName(classroom.trainer)}</td>
                      <td className="p-3">
                        {new Date(classroom.scheduled_at).toLocaleString()}
                      </td>
                      <td className="p-3">{classroom.duration_minutes} min</td>
                      <td className="p-3">
                        <span
                          className={
                            classroom.is_active
                              ? "rounded-full bg-green-50 px-2 py-1 text-green-700"
                              : "rounded-full bg-slate-100 px-2 py-1 text-slate-600"
                          }
                        >
                          {classroom.is_active ? "Active" : "Inactive"}
                        </span>
                      </td>
                      <td className="p-3">
                        <div className="flex flex-wrap gap-2">
                          <button
                            type="button"
                            onClick={() => startEditing(classroom)}
                            className="rounded-md border border-slate-300 px-3 py-1.5 hover:bg-slate-50"
                          >
                            Edit
                          </button>
                          <button
                            type="button"
                            onClick={() => void toggleClassroom(classroom)}
                            className="rounded-md border border-slate-300 px-3 py-1.5 hover:bg-slate-50"
                          >
                            {classroom.is_active ? "Deactivate" : "Activate"}
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
