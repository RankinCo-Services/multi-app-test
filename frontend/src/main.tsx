import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { TenantAuthProvider, configureBeacon } from '@beacon/tenant-ui';
import api, { setAuthToken } from './services/api';
import App from './App';
import './index.css';

const PUBLISHABLE_KEY = import.meta.env.VITE_CLERK_PUBLISHABLE_KEY;
const PLATFORM_API_URL = import.meta.env.VITE_PLATFORM_API_URL || import.meta.env.VITE_API_URL || '';

if (!PUBLISHABLE_KEY) {
  throw new Error('Missing Clerk Publishable Key. Add VITE_CLERK_PUBLISHABLE_KEY to your .env');
}

configureBeacon({
  api,
  setAuthToken,
  apiBaseUrl: PLATFORM_API_URL,
  app: { name: 'Beacon App' },
  afterCreateTenantPath: '/',
});

// Router must wrap TenantAuthProvider so Clerk/AuthSync useNavigate() works (e.g. when embedded in iframe).
ReactDOM.createRoot(document.getElementById('root')!).render(
  <BrowserRouter>
    <TenantAuthProvider
      publishableKey={PUBLISHABLE_KEY}
      api={api}
      setAuthToken={setAuthToken}
      afterSignInUrl="/tenants"
      afterSignUpUrl="/tenants"
    >
      <App />
    </TenantAuthProvider>
  </BrowserRouter>
);
