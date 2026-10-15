
import Shell from '@/components/Shell';
import Link from 'next/link';
import { workspace, statusLabel } from '@/lib/workspace';

type Video = {
  id: string;
  title: string;
  status: string;
  due_date: string | null;
  clients: {
    name: string;
  } | null;
};

export default async function Dashboard() {
  const { supabase, role, name } = await workspace();

  const { data: videos, error } = await supabase
    .from('videos')
    .select('id,title,status,due_date,clients(name)')
    .order('created_at', { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  const rows: Video[] = (videos ?? []) as Video[];

  const stats = [
    {
      label: 'Total Videos',
      count: rows.length,
    },
    {
      label: 'In Editing',
      count: rows.filter(
        (v: Video) => v.status === 'editing'
      ).length,
    },
    {
      label: 'In Review',
      count: rows.filter(
        (v: Video) => v.status === 'review'
      ).length,
    },
    {
      label: 'Completed',
      count: rows.filter(
        (v: Video) =>
          ['approved', 'delivered'].includes(v.status)
      ).length,
    },
  ];

  return (
    <Shell role={role}>
      <h1 className="text-3xl font-bold mb-2">
        Welcome back, {name}
      </h1>

      <p className="muted text-sm">
        Your production overview
      </p>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 my-8">
        {stats.map(({ label, count }) => (
          <div className="panel" key={label}>
            <div className="text-3xl font-bold text-purple-300 mb-3">
              {count}
            </div>

            <div className="muted text-sm">
              {label}
            </div>
          </div>
        ))}
      </div>

      <div className="flex justify-between mb-4">
        <h2 className="font-bold">
          Recent Videos
        </h2>

        <Link
          href="/videos"
          className="text-purple-300 text-sm"
        >
          View all →
        </Link>
      </div>

      <div className="panel space-y-3">
        {rows.length ? (
          rows.slice(0, 8).map((v: Video) => (
            <Link
              href={`/videos/${v.id}`}
              key={v.id}
              className="flex gap-4 justify-between border-b border-[#292a3b] pb-3 text-sm"
            >
              <span>{v.title}</span>

              <span className="pill">
                {statusLabel[v.status as keyof typeof statusLabel] ??
                  v.status}
              </span>
            </Link>
          ))
        ) : (
          <p className="muted text-sm">
            No videos yet. Add your first project
            to get started.
          </p>
        )}
      </div>
    </Shell>
  );
}
