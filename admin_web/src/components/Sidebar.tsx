"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const links = [
  { label: "Dashboard", href: "/", icon: "▦" },
  { label: "Courses", href: "/courses", icon: "▤" },
  { label: "Classrooms", href: "/classrooms", icon: "▣" },
  { label: "Trainers", href: "/trainers", icon: "♙" },
  { label: "Students", href: "/students", icon: "♧" },
  { label: "Settings", href: "/settings", icon: "⚙" },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <>
      <aside className="fixed inset-y-0 left-0 z-40 hidden w-64 overflow-y-auto bg-slate-950 p-6 text-white md:block">
        <Link href="/" className="block">
          <span className="text-xl font-bold">SOPAN SHEDGE</span>
          <span className="mt-1 block text-sm text-slate-400">
            Learning Platform
          </span>
        </Link>

        <nav aria-label="Main navigation" className="mt-10 space-y-3">
          {links.map((item) => {
            const active = pathname === item.href;

            return (
              <Link
                key={item.href}
                href={item.href}
                aria-current={active ? "page" : undefined}
                className={`flex items-center gap-3 rounded-lg px-4 py-3 transition-colors ${
                  active
                    ? "bg-blue-600 text-white"
                    : "text-slate-300 hover:bg-slate-800 hover:text-white"
                }`}
              >
                <span aria-hidden="true">{item.icon}</span>
                {item.label}
              </Link>
            );
          })}
        </nav>
      </aside>

      <nav
        aria-label="Mobile navigation"
        className="sticky top-0 z-40 flex gap-2 overflow-x-auto bg-slate-950 p-3 text-white md:hidden"
      >
        {links.map((item) => {
          const active = pathname === item.href;

          return (
            <Link
              key={item.href}
              href={item.href}
              aria-current={active ? "page" : undefined}
              className={`shrink-0 rounded-lg px-3 py-2 text-sm ${
                active
                  ? "bg-blue-600"
                  : "text-slate-300 hover:bg-slate-800"
              }`}
            >
              {item.label}
            </Link>
          );
        })}
      </nav>
    </>
  );
}
