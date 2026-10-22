
"use client";

import { useEffect, useState } from "react";

type Course = {
  id: number;
  title: string;
  description: string;
  language: string;
  is_active: boolean;
};

export default function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    fetch("http://127.0.0.1:8000/api/courses/")
      .then((response) => {
        if (!response.ok) throw new Error(`API error: ${response.status}`);
        return response.json();
      })
      .then((data) =>
        setCourses(Array.isArray(data) ? data : data.results ?? [])
      )
      .catch((err) =>
        setError(err instanceof Error ? err.message : "Failed to load courses")
      )
      .finally(() => setLoading(false));
  }, []);

  return (
    <main className="min-h-screen bg-slate-100 p-6 text-slate-900 md:p-10">
      <a href="/" className="text-sm text-blue-600 hover:underline">
        ← Back to Dashboard
      </a>

      <header className="mb-8 mt-4 flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-sm text-slate-500">Administration</p>
          <h1 className="mt-1 text-3xl font-bold">Courses</h1>
          <p className="mt-2 text-slate-600">
            Manage courses offered on your learning platform.
          </p>
        </div>

        <span className="rounded-full bg-white px-4 py-2 shadow-sm">
          Total courses: {courses.length}
        </span>
      </header>

      {error && (
        <p className="mb-5 rounded-lg bg-red-50 p-4 text-red-700">{error}</p>
      )}

      <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
        {courses.map((course) => (
          <article
            key={course.id}
            className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
          >
            <div className="flex items-start justify-between gap-3">
              <h2 className="text-xl font-bold">{course.title}</h2>
              <span
                className={`shrink-0 rounded-full px-3 py-1 text-xs ${
                  course.is_active
                    ? "bg-green-100 text-green-700"
                    : "bg-slate-100 text-slate-600"
                }`}
              >
                {course.is_active ? "Active" : "Inactive"}
              </span>
            </div>

            <p className="mt-3 min-h-12 text-sm text-slate-600">
              {course.description || "No description available."}
            </p>

            <div className="mt-5 flex justify-between border-t pt-4 text-sm text-slate-500">
              <span>Course ID: {course.id}</span>
              <span>Language: {course.language}</span>
            </div>
          </article>
        ))}
      </section>

      {loading && <p className="mt-6 text-slate-500">Loading courses...</p>}

      {!loading && !error && courses.length === 0 && (
        <div className="rounded-xl bg-white p-8 text-center text-slate-500">
          No courses found. Add a course through Django Admin.
        </div>
      )}
    </main>
  );
}
