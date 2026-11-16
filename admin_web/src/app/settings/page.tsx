import Link from "next/link";

export default function SettingsPage() {
  return (
    <main className="min-h-screen p-6 text-slate-900 md:p-10">
      <Link href="/" className="text-sm text-blue-600 hover:underline">
        &larr; Back to Dashboard
      </Link>

      <header className="mt-6">
        <p className="text-sm text-slate-500">Administration</p>
        <h1 className="mt-1 text-3xl font-bold">Settings</h1>
        <p className="mt-2 text-slate-600">
          Platform configuration.
        </p>
      </header>

      <section className="mt-8 rounded-xl bg-white p-6 shadow-sm">
        <h2 className="text-xl font-semibold">Settings</h2>
        <p className="mt-2 text-slate-600">
          This page is ready for settings features. Configuration controls
          have not been added yet.
        </p>
      </section>
    </main>
  );
}
