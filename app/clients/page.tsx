
import Shell from '@/components/Shell';
import { workspace } from '@/lib/workspace';
import { redirect } from 'next/navigation';

type Client = {
  id: string;
  name: string;
  created_at: string;
};

export default async function Clients() {
  const { supabase, role } = await workspace();

  if (role !== 'admin') {
    redirect('/dashboard');
  }

  const { data: clients, error } = await supabase
    .from('clients')
    .select('id, name, created_at')
    .order('name');

  if (error) {
    console.error('Error fetching clients:', error.message);
  }

  return (
    <Shell role={role}>
      <h1 className="text-3xl font-bold mb-2">
        Clients
      </h1>

      <p className="muted text-sm mb-7">
        Client records and workspaces
      </p>

      <div className="grid md:grid-cols-3 gap-4">
        {(clients as Client[] | null)?.map(
          (c: Client) => (
            <div className="panel" key={c.id}>
              <div className="text-purple-300 text-2xl mb-3">
                ◈
              </div>

              <h2 className="font-bold">
                {c.name}
              </h2>

              <p className="muted text-xs mt-2">
                Client workspace
              </p>
            </div>
          )
        )}
      </div>
    </Shell>
  );
}
