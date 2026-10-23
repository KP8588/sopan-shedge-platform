"use client";

import { useCallback, useEffect, useState, type FormEvent } from "react";
import Link from "next/link";

type Student = {
  id: number;
  username: string;
  email: string;
  role: string;
  phone: string;
  preferred_language: string;
  is_active: boolean;
};

type StudentDraft = {
  username: string;
  email: string;
  password: string;
  phone: string;
  preferred_language: string;
};

const API_URL = "http://127.0.0.1:8000/api/auth";

const emptyDraft: StudentDraft = {
  username: "",
  email: "",
  password: "",
  phone: "",
  preferred_language: "en",
};

const languageNames: Record<string, string> = {
  en: "English",
  hi: "Hindi",
  mr: "Marathi",
};

function getErrorMessage(data: unknown): string {
  if (data && typeof data === "object") {
    const value = data as Record<string, unknown>;

    if (typeof value.detail === "string") return value.detail;
    if (typeof value.message === "string") return value.message;

    for (const [field, message] of Object.entries(value)) {
      if (Array.isArray(message) && typeof message[0] === "string") {
        return `${field}: ${message[0]}`;
      }
      if (typeof message === "string") return `${field}: ${message}`;
    }
  }

  return "The request failed. Please try again.";
}

export default function StudentsPage() {
  const [students, setStudents] = useState<Student[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<number | null>(null);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [formOpen, setFormOpen] = useState(false);
  const [editingStudent, setEditingStudent] = useState<Student | null>(null);
  const [draft, setDraft] = useState<StudentDraft>(emptyDraft);
  const [saving, setSaving] = useState(false);

  const loadStudents = useCallback(async () => {
    const token = sessionStorage.getItem("admin_token");

    if (!token) {
      window.location.href = "/login?next=/students";
      return;
    }

    try {
      setError("");

      const response = await fetch(`${API_URL}/students/`, {
        headers: {
          Authorization: `Token ${token}`,
          Accept: "application/json",
        },
      });

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login?next=/students";
        return;
      }

      if (!response.ok) {
        throw new Error(`Unable to load students (HTTP ${response.status}).`);
      }

      const data = await response.json();
      setStudents(Array.isArray(data) ? data : data.results ?? []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to load students.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadStudents();
  }, [loadStudents]);

  function openCreateForm() {
    setEditingStudent(null);
    setDraft(emptyDraft);
    setError("");
    setSuccess("");
    setFormOpen(true);
  }

  function openEditForm(student: Student) {
    setEditingStudent(student);
    setDraft({
      username: student.username,
      email: student.email ?? "",
      password: "",
      phone: student.phone ?? "",
      preferred_language: student.preferred_language || "en",
    });
    setError("");
    setSuccess("");
    setFormOpen(true);
  }

  async function saveStudent(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const token = sessionStorage.getItem("admin_token");
    if (!token) {
      window.location.href = "/login?next=/students";
      return;
    }

    setSaving(true);
    setError("");
    setSuccess("");

    const isEditing = editingStudent !== null;
    const endpoint = isEditing
      ? `${API_URL}/students/${editingStudent.id}/manage/`
      : `${API_URL}/students/create/`;

    const payload = isEditing
      ? {
          email: draft.email.trim(),
          phone: draft.phone.trim(),
          preferred_language: draft.preferred_language,
        }
      : {
          username: draft.username.trim(),
          email: draft.email.trim(),
          password: draft.password,
          phone: draft.phone.trim(),
          preferred_language: draft.preferred_language,
        };

    try {
      const response = await fetch(endpoint, {
        method: isEditing ? "PATCH" : "POST",
        headers: {
          Authorization: `Token ${token}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify(payload),
      });

      const data = await response.json().catch(() => ({}));

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login?next=/students";
        return;
      }

      if (!response.ok) {
        throw new Error(getErrorMessage(data));
      }

      setFormOpen(false);
      setEditingStudent(null);
      setDraft(emptyDraft);
      setSuccess(
        isEditing ? "Student details updated." : "Student created successfully."
      );
      await loadStudents();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to save student.");
    } finally {
      setSaving(false);
    }
  }

  async function toggleStatus(student: Student) {
    const token = sessionStorage.getItem("admin_token");

    if (!token) {
      window.location.href = "/login?next=/students";
      return;
    }

    setBusyId(student.id);
    setError("");
    setSuccess("");

    try {
      const response = await fetch(`${API_URL}/students/${student.id}/`, {
        method: "PATCH",
        headers: {
          Authorization: `Token ${token}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({ is_active: !student.is_active }),
      });

      const data = await response.json().catch(() => ({}));

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login?next=/students";
        return;
      }

      if (!response.ok) throw new Error(getErrorMessage(data));

      setSuccess(data.message ?? "Student account updated.");
      await loadStudents();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to update student.");
    } finally {
      setBusyId(null);
    }
  }

  const query = search.trim().toLowerCase();
  const filteredStudents = students.filter(
    (student) =>
      student.username.toLowerCase().includes(query) ||
      (student.email ?? "").toLowerCase().includes(query)
  );

  const activeCount = students.filter((student) => student.is_active).length;
  const inactiveCount = students.length - activeCount;

  const inputClass =
    "mt-1 w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100";

  return (
    <main className="min-h-screen bg-slate-100 p-6 text-slate-900 md:p-10">
      <div className="mx-auto max-w-7xl space-y-8">
        <Link href="/" className="text-sm text-blue-600 hover:underline">
          &larr; Back to Dashboard
        </Link>

        <header className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="text-sm text-slate-500">Administration</p>
            <h1 className="mt-1 text-3xl font-bold">Student Management</h1>
            <p className="mt-2 text-slate-600">
              Create student accounts and manage their details and access.
            </p>
          </div>

          <div className="flex flex-wrap gap-3">
            <button
              type="button"
              onClick={() => void loadStudents()}
              className="rounded-lg border border-slate-300 bg-white px-4 py-2 hover:bg-slate-50"
            >
              Refresh
            </button>
            <button
              type="button"
              onClick={openCreateForm}
              className="rounded-lg bg-blue-700 px-4 py-2 font-medium text-white hover:bg-blue-800"
            >
              + Add Student
            </button>
          </div>
        </header>

        <section className="grid gap-5 sm:grid-cols-3">
          <article className="rounded-xl bg-white p-6 shadow-sm">
            <p className="text-sm text-slate-500">Total Students</p>
            <p className="mt-2 text-3xl font-bold">{students.length}</p>
          </article>
          <article className="rounded-xl bg-white p-6 shadow-sm">
            <p className="text-sm text-slate-500">Active Accounts</p>
            <p className="mt-2 text-3xl font-bold text-green-700">{activeCount}</p>
          </article>
          <article className="rounded-xl bg-white p-6 shadow-sm">
            <p className="text-sm text-slate-500">Inactive Accounts</p>
            <p className="mt-2 text-3xl font-bold text-slate-600">{inactiveCount}</p>
          </article>
        </section>

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

        {formOpen && (
          <section className="rounded-xl bg-white p-6 shadow-sm">
            <h2 className="mb-5 text-xl font-semibold">
              {editingStudent ? `Edit ${editingStudent.username}` : "Add Student"}
            </h2>

            <form onSubmit={saveStudent} className="grid gap-5 sm:grid-cols-2">
              {!editingStudent && (
                <label className="text-sm font-medium">
                  Username *
                  <input
                    required
                    minLength={1}
                    maxLength={150}
                    autoComplete="username"
                    className={inputClass}
                    value={draft.username}
                    onChange={(e) => setDraft({ ...draft, username: e.target.value })}
                  />
                </label>
              )}

              <label className="text-sm font-medium">
                Email *
                <input
                  required
                  type="email"
                  autoComplete="email"
                  className={inputClass}
                  value={draft.email}
                  onChange={(e) => setDraft({ ...draft, email: e.target.value })}
                />
              </label>

              {!editingStudent && (
                <label className="text-sm font-medium">
                  Temporary password *
                  <input
                    required
                    type="password"
                    minLength={8}
                    autoComplete="new-password"
                    className={inputClass}
                    value={draft.password}
                    onChange={(e) => setDraft({ ...draft, password: e.target.value })}
                  />
                  <span className="mt-1 block text-xs text-slate-500">
                    At least 8 characters. Share credentials securely.
                  </span>
                </label>
              )}

              <label className="text-sm font-medium">
                Phone
                <input
                  type="tel"
                  maxLength={20}
                  className={inputClass}
                  value={draft.phone}
                  onChange={(e) => setDraft({ ...draft, phone: e.target.value })}
                />
              </label>

              <label className="text-sm font-medium">
                Preferred language
                <select
                  className={inputClass}
                  value={draft.preferred_language}
                  onChange={(e) =>
                    setDraft({ ...draft, preferred_language: e.target.value })
                  }
                >
                  <option value="en">English</option>
                  <option value="hi">Hindi</option>
                  <option value="mr">Marathi</option>
                </select>
              </label>

              <div className="flex flex-wrap items-center gap-3 sm:col-span-2">
                <button
                  type="submit"
                  disabled={saving}
                  className="rounded-lg bg-blue-700 px-5 py-2.5 font-medium text-white hover:bg-blue-800 disabled:opacity-50"
                >
                  {saving ? "Saving..." : editingStudent ? "Save Changes" : "Create Student"}
                </button>
                <button
                  type="button"
                  disabled={saving}
                  onClick={() => {
                    setFormOpen(false);
                    setEditingStudent(null);
                    setDraft(emptyDraft);
                    setError("");
                  }}
                  className="rounded-lg border border-slate-300 px-5 py-2.5 hover:bg-slate-50"
                >
                  Cancel
                </button>
              </div>
            </form>
          </section>
        )}

        <section className="rounded-xl bg-white p-6 shadow-sm">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-4">
            <h2 className="text-xl font-semibold">Registered Students</h2>
            <span className="rounded-full bg-blue-50 px-3 py-1 text-sm text-blue-700">
              Showing {filteredStudents.length}
            </span>
          </div>

          <label htmlFor="student-search" className="mb-2 block text-sm font-medium">
            Search by username or email
          </label>
          <input
            id="student-search"
            type="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search students..."
            className="mb-5 w-full rounded-lg border border-slate-300 px-4 py-3 outline-none focus:border-blue-500"
          />

          {loading ? (
            <p className="py-8 text-center text-slate-500">Loading students...</p>
          ) : filteredStudents.length === 0 ? (
            <p className="py-8 text-center text-slate-500">
              {students.length === 0
                ? "No student accounts found."
                : "No students match your search."}
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b bg-slate-50 text-slate-600">
                  <tr>
                    <th className="p-3">ID</th>
                    <th className="p-3">Username</th>
                    <th className="p-3">Email</th>
                    <th className="p-3">Phone</th>
                    <th className="p-3">Language</th>
                    <th className="p-3">Status</th>
                    <th className="p-3">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredStudents.map((student) => (
                    <tr key={student.id} className="border-b last:border-0">
                      <td className="p-3">{student.id}</td>
                      <td className="p-3 font-medium">{student.username}</td>
                      <td className="p-3">{student.email || "—"}</td>
                      <td className="p-3">{student.phone || "—"}</td>
                      <td className="p-3">
                        {languageNames[student.preferred_language] ?? student.preferred_language ?? "—"}
                      </td>
                      <td className="p-3">
                        <span
                          className={
                            student.is_active
                              ? "rounded-full bg-green-50 px-3 py-1 text-green-700"
                              : "rounded-full bg-slate-100 px-3 py-1 text-slate-600"
                          }
                        >
                          {student.is_active ? "Active" : "Inactive"}
                        </span>
                      </td>
                      <td className="p-3">
                        <div className="flex flex-wrap gap-2">
                          <button
                            type="button"
                            onClick={() => openEditForm(student)}
                            className="rounded-lg border border-blue-300 px-3 py-2 text-blue-700 hover:bg-blue-50"
                          >
                            Edit
                          </button>
                          <button
                            type="button"
                            disabled={busyId === student.id}
                            onClick={() => void toggleStatus(student)}
                            className="whitespace-nowrap rounded-lg border border-slate-300 px-3 py-2 hover:bg-slate-50 disabled:opacity-50"
                          >
                            {busyId === student.id
                              ? "Updating..."
                              : student.is_active
                                ? "Deactivate"
                                : "Activate"}
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
