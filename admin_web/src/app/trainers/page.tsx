"use client";

import { useEffect, useState } from "react";

type Trainer = {
  id: number;
  username: string;
  email: string;
};

export default function TrainersPage() {
  const [trainers, setTrainers] = useState<Trainer[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("http://127.0.0.1:8000/api/auth/users/")
      .then((response) => {
        if (!response.ok) throw new Error("Unable to load trainers");
        return response.json();
      })
      .then((data) => {
        const users = Array.isArray(data) ? data : data.results ?? [];
        setTrainers(users.filter((user: Trainer & { role?: string }) =>
          user.role === "TRAINER"
        ));
      })
      .catch(() => setError("Unable to load trainers. The API endpoint may not exist yet."))
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
          <h1 className="mt-1 text-3xl font-bold">Trainers</h1>
          <p className="mt-2 text-slate-600">Manage your platform trainers.</p>
        </div>
        <span className="rounded-full bg-white px-4 py-3 shadow-sm">
          Total trainers: {trainers.length}
        </span>
      </header>

      <section className="mt-8 overflow-x-auto rounded-2xl bg-white p-6 shadow-sm">
        {loading && <p>Loading trainers...</p>}
        {error && <p className="rounded-lg bg-red-50 p-4 text-red-700">{error}</p>}

        {!loading && !error && (
          <table className="w-full text-left text-sm">
            <thead className="border-b bg-slate-50">
              <tr>
                <th className="p-3">ID</th>
                <th className="p-3">Username</th>
                <th className="p-3">Email</th>
                <th className="p-3">Role</th>
              </tr>
            </thead>
            <tbody>
              {trainers.map((trainer) => (
                <tr key={trainer.id} className="border-b">
                  <td className="p-3">{trainer.id}</td>
                  <td className="p-3">{trainer.username}</td>
                  <td className="p-3">{trainer.email || "—"}</td>
                  <td className="p-3">TRAINER</td>
                </tr>
              ))}
              {trainers.length === 0 && (
                <tr>
                  <td colSpan={4} className="p-6 text-center text-slate-500">
                    No trainers found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </section>
    </main>
  );
}