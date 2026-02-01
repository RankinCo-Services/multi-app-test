import { useEffect, useState } from 'react';

const APP_API_URL = import.meta.env.VITE_API_URL || '';

interface HealthResponse {
  status: string;
  timestamp: string;
  database: 'connected' | 'not connected';
}

export default function DashboardPage() {
  const [dbStatus, setDbStatus] = useState<'connected' | 'not connected' | 'loading'>('loading');

  useEffect(() => {
    const url = APP_API_URL ? `${String(APP_API_URL).replace(/\/$/, '')}/api/health` : '/api/health';
    fetch(url)
      .then((res) => res.json())
      .then((data: HealthResponse) => {
        setDbStatus(data.database === 'connected' ? 'connected' : 'not connected');
      })
      .catch(() => setDbStatus('not connected'));
  }, []);

  return (
    <div className="p-6 max-w-2xl">
      <h1 className="text-2xl font-bold text-gray-900 mb-2">Dashboard</h1>
      <p className="text-gray-600 mb-4">
        <strong>Database:</strong>{' '}
        {dbStatus === 'loading' ? '…' : dbStatus === 'connected' ? 'connected' : 'not connected'}
      </p>
    </div>
  );
}
