"use client";

import { useEffect, useState } from "react";

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

export default function ClassroomsPage() {
  const [classrooms, setClassrooms] = useState<Classroom[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    fetch("http://127.0.0.1:8000/api/classrooms/")
      .then((response) => {
        if (!response.ok) throw new Error("Unable to load classrooms.");
        return response.json();
      })
      .then((data) => {
        setClassrooms(Array.isArray(data) ? data : data.results ?? []);
      })
      .catch(() => setError("Cannot connect to Django. Check that the backend is running."))
      .finally(() => setLoading(false));
  }, []);

  return (
    <main className="min-h-screen bg-slate-100 p-6 text-slate-900 md:p-10">
      <a href="/" className="text-blue-600 hover:underline">
        ← Back to Dashboard
      </a>

      <header className="mt-6 flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-sm text-slate-500">Administration</p>
          <h1 className="mt-1 text-3xl font-bold">Classrooms</h1>
          <p className="mt-2 text-slate-600">
            View scheduled classes and live classroom details.
          </p>
        </div>
        <span className="rounded-full bg-white px-4 py-3 shadow-sm">
          Total classrooms: {classrooms.length}
        </span>
      </header>

      {error && (
        <p className="mt-6 rounded-lg bg-red-50 p-4 text-red-700">{error}</p>
      )}

      {loading ? (
        <p className="mt-8">Loading classrooms...</p>
      ) : (
        <section className="mt-8 overflow-x-auto rounded-2xl bg-white p-6 shadow-sm">
          <table className="w-full min-w-[850px] text-left text-sm">
            <thead className="border-b bg-slate-50 text-slate-600">
              <tr>
                <th className="p-3">Class</th>
                <th className="p-3">Course ID</th>
                <th className="p-3">Trainer ID</th>
                <th className="p-3">Scheduled At</th>
                <th className="p-3">Duration</th>
                <th className="p-3">Meeting</th>
                <th className="p-3">Status</th>
              </tr>
            </thead>
            <tbody>
              {classrooms.map((item) => (
                <tr key={item.id} className="border-b last:border-0">
                  <td className="p-3 font-medium">{item.title}</td>
                  <td className="p-3">{item.course}</td>
                  <td className="p-3">{item.trainer}</td>
                  <td className="p-3">
                    {new Date(item.scheduled_at).toLocaleString()}
                  </td>
                  <td className="p-3">{item.duration_minutes} min</td>
                  <td className="p-3">
                    {item.meeting_url ? (
                      <a
                        href={item.meeting_url}
                        target="_blank"
                        rel="noreferrer"
                        className="text-blue-600 hover:underline"
                      >
                        Join link
                      </a>
                    ) : (
                      <span className="text-slate-400">Not set</span>
                    )}
                  </td>
                  <td className="p-3">
                    <span
                      className={`rounded-full px-3 py-1 ${
                        item.is_active
                          ? "bg-green-100 text-green-700"
                          : "bg-slate-100 text-slate-600"
                      }`}
                    >
                      {item.is_active ? "Active" : "Inactive"}
                    </span>
                  </td>
                </tr>
              ))}
              {!error && classrooms.length === 0 && (
                <tr>
                  <td colSpan={7} className="p-6 text-center text-slate-500">
                    No classrooms found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </section>
      )}
    </main>
  );
}