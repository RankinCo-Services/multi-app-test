import ReactDOM from 'react-dom/client';
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

ReactDOM.createRoot(document.getElementById('root')!).render(
  <TenantAuthProvider
    publishableKey={PUBLISHABLE_KEY}
    api={api}
    setAuthToken={setAuthToken}
    afterSignInUrl="/tenants"
    afterSignUpUrl="/tenants"
  >
    <App />
  </TenantAuthProvider>
);
