
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleLogin(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const response = await fetch(
        "http://127.0.0.1:8000/api/auth/login/",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ username, password }),
        }
      );

      const data = await response.json();

      if (!response.ok || !data.token) {
        throw new Error(data.message || "Login failed. Check your credentials.");
      }

      sessionStorage.setItem("admin_token", data.token);
      router.push("/trainers");
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Unable to connect to the server."
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-100 p-6">
      <form
        onSubmit={handleLogin}
        className="w-full max-w-md space-y-5 rounded-2xl bg-white p-8 shadow"
      >
        <h1 className="text-2xl font-bold text-slate-900">Admin Login</h1>
        <p className="text-sm text-slate-600">
          Sign in to manage platform trainers.
        </p>

        <label className="block text-sm font-medium">
          Username
          <input
            className="mt-1 w-full rounded-lg border p-3"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            autoComplete="username"
            required
          />
        </label>

        <label className="block text-sm font-medium">
          Password
          <input
            className="mt-1 w-full rounded-lg border p-3"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
            required
          />
        </label>

        {error && (
          <p role="alert" className="text-sm text-red-600">
            {error}
          </p>
        )}

        <button
          className="w-full rounded-lg bg-blue-600 p-3 font-semibold text-white disabled:opacity-50"
          type="submit"
          disabled={loading}
        >
          {loading ? "Signing in..." : "Sign in"}
        </button>
      </form>
    </main>
  );
}
