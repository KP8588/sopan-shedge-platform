"use client";

import { useEffect, useState } from "react";

type Classroom = {
  id: number;
  title: string;
  course: number;
  trainer: number;
  scheduled_at: string;
  duration_minutes?: number;
  is_active: boolean;
};

export default function Home() {
  const [classrooms, setClassrooms] = useState<Classroom[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadClassrooms() {
      try {
        setError("");

        const response = await fetch("http://127.0.0.1:8000/api/classrooms/");

        if (!response.ok) {
          throw new Error(`Django returned HTTP ${response.status}`);
        }

        const data = await response.json();

        if (!cancelled) {
          setClassrooms(Array.isArray(data) ? data : data.results ?? []);
        }
      } catch (err) {
        if (!cancelled) {
          setError(
            err instanceof Error ? err.message : "Unable to load classrooms.",
          );
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    void loadClassrooms();

    return () => {
      cancelled = true;
    };
  }, []);

  const cards = [
    { label: "Total Classrooms", value: classrooms.length },
    {
      label: "Active Classrooms",
      value: classrooms.filter((item) => item.is_active).length,
    },
    {
      label: "Courses in Scheduled Classes",
      value: new Set(classrooms.map((item) => item.course)).size,
    },
    { label: "Scheduled Classes", value: classrooms.length },
  ];

  return (
    <main className="min-h-screen p-6 text-slate-900 md:p-10">
      <header className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-sm text-slate-500">Administration</p>
          <h1 className="mt-1 text-3xl font-bold">Dashboard</h1>
          <p className="mt-2 text-slate-600">
            Manage your learning platform.
          </p>
        </div>

        <span className="rounded-full bg-white px-4 py-2 text-sm shadow-sm">
          Admin Panel
        </span>
      </header>

      <section
        aria-label="Platform statistics"
        className="mt-8 grid gap-5 sm:grid-cols-2 xl:grid-cols-4"
      >
        {cards.map((card) => (
          <article key={card.label} className="rounded-2xl bg-white p-6 shadow-sm">
            <p className="text-sm text-slate-500">{card.label}</p>
            <p className="mt-3 text-3xl font-bold">{card.value}</p>
          </article>
        ))}
      </section>

      <section className="mt-8 rounded-2xl bg-white p-6 shadow-sm">
        <h2 className="text-xl font-bold">Classroom Schedule</h2>
        <p className="mt-1 text-sm text-slate-500">
          Live data from your Django backend
        </p>

        {error && (
          <p role="alert" className="mt-5 rounded-lg bg-red-50 p-4 text-red-700">
            {error}
          </p>
        )}

        {loading ? (
          <p className="mt-5 text-slate-500">Loading classrooms...</p>
        ) : (
          <div className="mt-5 overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-slate-50 text-slate-600">
                <tr>
                  <th className="p-3">Class</th>
                  <th className="p-3">Course ID</th>
                  <th className="p-3">Trainer ID</th>
                  <th className="p-3">Scheduled At</th>
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
                    <td className="p-3">
                      <span
                        className={
                          item.is_active
                            ? "rounded-full bg-green-100 px-3 py-1 text-green-700"
                            : "rounded-full bg-slate-100 px-3 py-1 text-slate-600"
                        }
                      >
                        {item.is_active ? "Active" : "Inactive"}
                      </span>
                    </td>
                  </tr>
                ))}

                {classrooms.length === 0 && (
                  <tr>
                    <td colSpan={5} className="p-6 text-center text-slate-500">
                      No classrooms found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </main>
  );
}
