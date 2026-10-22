
"use client";

import { useCallback, useEffect, useState } from "react";
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

const API_URL = "http://127.0.0.1:8000/api/auth";

const languageNames: Record<string, string> = {
  en: "English",
  hi: "Hindi",
  mr: "Marathi",
};

export default function StudentsPage() {
  const [students, setStudents] = useState<Student[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<number | null>(null);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

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
      setError(
        err instanceof Error ? err.message : "Unable to load students."
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadStudents();
  }, [loadStudents]);

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
      const response = await fetch(
        `${API_URL}/students/${student.id}/`,
        {
          method: "PATCH",
          headers: {
            Authorization: `Token ${token}`,
            "Content-Type": "application/json",
            Accept: "application/json",
          },
          body: JSON.stringify({ is_active: !student.is_active }),
        }
      );

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login?next=/students";
        return;
      }

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data.detail ??
            data.is_active ??
            "Unable to update student account."
        );
      }

      setSuccess(data.message ?? "Student account updated.");
      await loadStudents();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Unable to update student."
      );
    } finally {
      setBusyId(null);
    }
  }

  const filteredStudents = students.filter((student) => {
    const query = search.trim().toLowerCase();
    return (
      student.username.toLowerCase().includes(query) ||
      student.email.toLowerCase().includes(query)
    );
  });

  const activeCount = students.filter((student) => student.is_active).length;
  const inactiveCount = students.length - activeCount;

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
              View student accounts and manage their access.
            </p>
          </div>
          <button
            type="button"
            onClick={() => void loadStudents()}
            className="rounded-lg border border-slate-300 bg-white px-4 py-2 hover:bg-slate-50"
          >
            Refresh
          </button>
        </header>

        <section className="grid gap-5 sm:grid-cols-3">
          <article className="rounded-xl bg-white p-6 shadow-sm">
            <p className="text-sm text-slate-500">Total Students</p>
            <p className="mt-2 text-3xl font-bold">{students.length}</p>
          </article>
          <article className="rounded-xl bg-white p-6 shadow-sm">
            <p className="text-sm text-slate-500">Active Accounts</p>
            <p className="mt-2 text-3xl font-bold text-green-700">
              {activeCount}
            </p>
          </article>
          <article className="rounded-xl bg-white p-6 shadow-sm">
            <p className="text-sm text-slate-500">Inactive Accounts</p>
            <p className="mt-2 text-3xl font-bold text-slate-600">
              {inactiveCount}
            </p>
          </article>
        </section>

        <section className="rounded-xl bg-white p-6 shadow-sm">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-4">
            <h2 className="text-xl font-semibold">Registered Students</h2>
            <span className="rounded-full bg-blue-50 px-3 py-1 text-sm text-blue-700">
              Showing {filteredStudents.length}
            </span>
          </div>

          <label
            htmlFor="student-search"
            className="mb-2 block text-sm font-medium"
          >
            Search by username or email
          </label>
          <input
            id="student-search"
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search students..."
            className="mb-5 w-full rounded-lg border border-slate-300 px-4 py-3 outline-none focus:border-blue-500"
          />

          {error && (
            <p role="alert" className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
              {error}
            </p>
          )}

          {success && (
            <p role="status" className="mb-4 rounded-lg bg-green-50 p-3 text-sm text-green-700">
              {success}
            </p>
          )}

          {loading ? (
            <p className="py-8 text-center text-slate-500">
              Loading students...
            </p>
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
                    <th className="p-3">Action</th>
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
                        {languageNames[student.preferred_language] ??
                          student.preferred_language ??
                          "—"}
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
