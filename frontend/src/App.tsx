import { useEffect, useState } from 'react';

const API_URL = import.meta.env.VITE_API_URL || '';

interface HealthResponse {
  status: string;
  timestamp: string;
  database: 'connected' | 'not connected';
}

export default function App() {
  const [dbStatus, setDbStatus] = useState<'connected' | 'not connected' | 'loading'>('loading');

  useEffect(() => {
    const url = API_URL ? `${API_URL.replace(/\/$/, '')}/api/health` : '/api/health';
    fetch(url)
      .then((res) => res.json())
      .then((data: HealthResponse) => {
        setDbStatus(data.database === 'connected' ? 'connected' : 'not connected');
      })
      .catch(() => setDbStatus('not connected'));
  }, []);

  return (
    <div style={{ padding: '2rem', maxWidth: 600 }}>
      <h1>Beacon App (Min)</h1>
      <p>
        <strong>Database:</strong>{' '}
        {dbStatus === 'loading' ? '…' : dbStatus === 'connected' ? 'connected' : 'not connected'}
      </p>
    </div>
  );
}
