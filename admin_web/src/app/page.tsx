
"use client";

import { useEffect, useState } from "react";

type Classroom = {
  id: number;
  title: string;
  course: number;
  trainer: number;
  scheduled_at: string;
  duration_minutes: number;
  is_active: boolean;
};

export default function Home() {
  const [classrooms, setClassrooms] = useState<Classroom[]>([]);
  const [error, setError] = useState("");


  useEffect(() => {
    async function loadClassrooms() {
      try {
        setError("");

        const response = await fetch(
          "http://127.0.0.1:8000/api/classrooms/",
        );

        if (!response.ok) {
          throw new Error(`Django returned HTTP ${response.status}`);
        }

        const data = await response.json();

        setClassrooms(
          Array.isArray(data) ? data : data.results ?? [],
        );
      } catch (err) {
        setError(
          err instanceof Error
            ? err.message
            : "Unable to load classrooms",
        );
      }
    }

    loadClassrooms();
  }, []);


  const cards = [
    { label: "Total Classrooms", value: classrooms.length },
    {
      label: "Active Classrooms",
      value: classrooms.filter((item) => item.is_active).length,
    },
    { label: "Courses", value: new Set(classrooms.map((item) => item.course)).size },
    { label: "Scheduled Classes", value: classrooms.length },
  ];

  return (
    <main className="min-h-screen bg-slate-100 text-slate-900">
      <aside className="fixed inset-y-0 left-0 hidden w-64 bg-slate-950 p-6 text-white md:block">
        <h1 className="text-xl font-bold">SOPAN SHEDGE</h1>
        <p className="mt-1 text-sm text-slate-400">Learning Platform</p>
        <nav className="mt-10 space-y-3">
          <p className="rounded-lg bg-blue-600 px-4 py-3">Dashboard</p>
          <p className="px-4 py-3 text-slate-300">Courses</p>
          <p className="px-4 py-3 text-slate-300">Classrooms</p>
          <p className="px-4 py-3 text-slate-300">Trainers</p>
          <p className="px-4 py-3 text-slate-300">Students</p>
          <p className="px-4 py-3 text-slate-300">Settings</p>
        </nav>
      </aside>

      <section className="p-6 md:ml-64 md:p-10">
        <header className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="text-sm text-slate-500">Administration</p>
            <h2 className="mt-1 text-3xl font-bold">Dashboard</h2>
            <p className="mt-2 text-slate-500">
              Manage your learning platform.
            </p>
          </div>
          <span className="rounded-full bg-white px-4 py-2 text-sm shadow-sm">
            Admin Panel
          </span>
        </header>

        <div className="mt-8 grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
          {cards.map((card) => (
            <article key={card.label} className="rounded-2xl bg-white p-6 shadow-sm">
              <p className="text-sm text-slate-500">{card.label}</p>
              <p className="mt-3 text-3xl font-bold">{card.value}</p>
            </article>
          ))}
        </div>

        <section className="mt-8 rounded-2xl bg-white p-6 shadow-sm">
          <h3 className="text-xl font-bold">Classroom Schedule</h3>
          <p className="mt-1 text-sm text-slate-500">
            Live data from your Django backend
          </p>

          {error && (
            <p className="mt-5 rounded-lg bg-red-50 p-4 text-red-700">{error}</p>
          )}

          <div className="mt-5 overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-slate-50 text-slate-500">
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
                      <span className="rounded-full bg-green-100 px-3 py-1 text-green-700">
                        {item.is_active ? "Active" : "Inactive"}
                      </span>
                    </td>
                  </tr>
                ))}
                {!error && classrooms.length === 0 && (
                  <tr>
                    <td colSpan={5} className="p-6 text-center text-slate-500">
                      No classrooms found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      </section>
    </main>
  );
}
