
"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";

type Trainer = {
  id: number;
  username: string;
  email: string;
  role: string;
};

const API_URL = "http://127.0.0.1:8000/api/auth";

export default function TrainersPage() {
  const [trainers, setTrainers] = useState<Trainer[]>([]);
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);

  const loadTrainers = useCallback(async () => {
    const token = sessionStorage.getItem("admin_token");

    if (!token) {
      window.location.href = "/login";
      return;
    }

    try {
      const response = await fetch(`${API_URL}/users/`, {
        headers: {
          Authorization: `Token ${token}`,
          Accept: "application/json",
        },
      });

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login";
        return;
      }

      if (!response.ok) {
        throw new Error(`Unable to load trainers (${response.status}).`);
      }

      const data = await response.json();
      const users = Array.isArray(data) ? data : data.results ?? [];

      setTrainers(
        users.filter((user: Trainer) => user.role === "TRAINER")
      );
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Unable to load trainers."
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadTrainers();
  }, [loadTrainers]);

  async function handleCreateTrainer(
    event: React.FormEvent<HTMLFormElement>
  ) {
    event.preventDefault();
    setError("");
    setSuccess("");
    setCreating(true);

    const token = sessionStorage.getItem("admin_token");

    if (!token) {
      window.location.href = "/login";
      return;
    }

    try {
      const response = await fetch(`${API_URL}/trainers/create/`, {
        method: "POST",
        headers: {
          Authorization: `Token ${token}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({ username, email, password }),
      });

      const data = await response.json();

      if (response.status === 401 || response.status === 403) {
        sessionStorage.removeItem("admin_token");
        window.location.href = "/login";
        return;
      }

      if (!response.ok) {
        const details = data.email?.[0]
          ?? data.username?.[0]
          ?? data.password?.[0]
          ?? data.detail
          ?? data.message
          ?? "Could not create trainer. Check the entered details.";

        throw new Error(details);
      }

      setSuccess(data.message ?? "Trainer created successfully.");
      setUsername("");
      setEmail("");
      setPassword("");
      await loadTrainers();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Unable to create trainer."
      );
    } finally {
      setCreating(false);
    }
  }

  return (
    <main className="min-h-screen bg-slate-100 p-6 text-slate-900 md:p-10">
      <div className="mx-auto max-w-6xl space-y-8">
        <Link href="/" className="text-blue-600 hover:underline">
          &larr; Back to Dashboard
        </Link>

        <header>
          <h1 className="text-3xl font-bold">Trainers</h1>
          <p className="mt-2 text-slate-600">
            Create and manage trainer accounts.
          </p>
        </header>

        <section className="rounded-xl bg-white p-6 shadow-sm">
          <h2 className="mb-5 text-xl font-semibold">Add Trainer</h2>

          <form onSubmit={handleCreateTrainer} className="space-y-4">
            <div>
              <label htmlFor="username" className="mb-1 block text-sm font-medium">
                Username
              </label>
              <input
                id="username"
                value={username}
                onChange={(event) => setUsername(event.target.value)}
                required
                autoComplete="off"
                className="w-full rounded-lg border border-slate-300 px-3 py-2 outline-none focus:border-blue-500"
                placeholder="Enter username"
              />
            </div>

            <div>
              <label htmlFor="email" className="mb-1 block text-sm font-medium">
                Email
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                required
                className="w-full rounded-lg border border-slate-300 px-3 py-2 outline-none focus:border-blue-500"
                placeholder="trainer@example.com"
              />
            </div>

            <div>
              <label htmlFor="password" className="mb-1 block text-sm font-medium">
                Temporary password
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                required
                minLength={8}
                autoComplete="new-password"
                className="w-full rounded-lg border border-slate-300 px-3 py-2 outline-none focus:border-blue-500"
                placeholder="At least 8 characters"
              />
            </div>

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

            <button
              type="submit"
              disabled={creating}
              className="rounded-lg bg-blue-600 px-5 py-2.5 font-medium text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {creating ? "Creating..." : "Create Trainer"}
            </button>
          </form>
        </section>

        <section className="rounded-xl bg-white p-6 shadow-sm">
          <div className="mb-5 flex items-center justify-between">
            <h2 className="text-xl font-semibold">Trainer List</h2>
            <span className="rounded-full bg-blue-50 px-3 py-1 text-sm text-blue-700">
              Total: {trainers.length}
            </span>
          </div>

          {loading ? (
            <p className="text-slate-500">Loading trainers...</p>
          ) : trainers.length === 0 ? (
            <p className="text-slate-500">No trainers found.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b bg-slate-50 text-slate-600">
                  <tr>
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
                      <td className="p-3 font-medium">{trainer.username}</td>
                      <td className="p-3">{trainer.email || "—"}</td>
                      <td className="p-3">
                        <span className="rounded-full bg-green-50 px-2 py-1 text-green-700">
                          {trainer.role}
                        </span>
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
