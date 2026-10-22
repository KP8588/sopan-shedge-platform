
"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

type Trainer = {
  id: number;
  username: string;
  email: string;
  role: string;
};

export default function TrainersPage() {
  const [trainers, setTrainers] = useState<Trainer[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadTrainers() {
      const token = sessionStorage.getItem("admin_token");

      if (!token) {
        window.location.href = "/login";
        return;
      }

      try {
        const response = await fetch(
          "http://127.0.0.1:8000/api/auth/users/",
          {
            headers: {
              Authorization: `Token ${token}`,
              Accept: "application/json",
            },
          }
        );

        if (response.status === 401 || response.status === 403) {
          sessionStorage.removeItem("admin_token");
          window.location.href = "/login";
          return;
        }

        if (!response.ok) {
          throw new Error(`API request failed (${response.status})`);
        }

        const data = await response.json();
        const users = Array.isArray(data) ? data : data.results ?? [];
        setTrainers(
          users.filter((user: Trainer) => user.role === "TRAINER")
        );
      } catch (err) {
        setError(
          err instanceof Error
            ? err.message
            : "Unable to connect to the Django API."
        );
      } finally {
        setLoading(false);
      }
    }

    loadTrainers();
  }, []);

  return (
    <main className="min-h-screen bg-slate-100 p-6 text-slate-900 md:p-10">
      <Link href="/" className="text-blue-600 hover:underline">
        ← Back to Dashboard
      </Link>

      <div className="mt-8 flex items-center justify-between gap-4">
        <div>
          <p className="text-sm text-slate-500">Administration</p>
          <h1 className="mt-1 text-3xl font-bold">Trainers</h1>
          <p className="mt-2">Manage your platform trainers.</p>
        </div>

        <div className="rounded-full bg-white px-5 py-3 shadow">
          Total trainers: {trainers.length}
        </div>
      </div>

      <section className="mt-8 rounded-2xl bg-white p-6 shadow-sm">
        {loading ? (
          <p>Loading trainers...</p>
        ) : error ? (
          <p role="alert" className="rounded-lg bg-red-50 p-4 text-red-700">
            {error}
          </p>
        ) : trainers.length === 0 ? (
          <p className="text-slate-600">
            No trainers found. Create or assign a user with the TRAINER role.
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="border-b text-sm text-slate-500">
                  <th className="p-3">ID</th>
                  <th className="p-3">Username</th>
                  <th className="p-3">Email</th>
                  <th className="p-3">Role</th>
                </tr>
              </thead>
              <tbody>
                {trainers.map((trainer) => (
                  <tr key={trainer.id} className="border-b last:border-0">
                    <td className="p-3">{trainer.id}</td>
                    <td className="p-3">{trainer.username}</td>
                    <td className="p-3">{trainer.email || "—"}</td>
                    <td className="p-3">{trainer.role}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </main>
  );
}
