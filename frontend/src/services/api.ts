/**
 * Platform API client for tenant-ui (tenant list, tenant context, subscriptions).
 * Uses VITE_PLATFORM_API_URL. App-specific calls (e.g. /api/health) use VITE_API_URL elsewhere.
 */
import axios from 'axios';

const PLATFORM_API_URL = import.meta.env.VITE_PLATFORM_API_URL || import.meta.env.VITE_API_URL || '';

const api = axios.create({
  baseURL: PLATFORM_API_URL,
  headers: { 'Content-Type': 'application/json' },
});

export type SetAuthTokenOptions = { userDisplayName?: string | null; userEmail?: string | null };

export const setAuthToken = (
  token: string | null,
  userId?: string | null,
  options?: SetAuthTokenOptions
) => {
  if (token) {
    api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  } else {
    delete api.defaults.headers.common['Authorization'];
  }
  if (userId != null) {
    api.defaults.headers.common['x-user-id'] = String(userId);
  } else {
    delete api.defaults.headers.common['x-user-id'];
  }
  if (options?.userDisplayName != null) {
    api.defaults.headers.common['x-user-name'] = options.userDisplayName;
  } else {
    delete api.defaults.headers.common['x-user-name'];
  }
  if (options?.userEmail != null) {
    api.defaults.headers.common['x-user-email'] = options.userEmail;
  } else {
    delete api.defaults.headers.common['x-user-email'];
  }
};

export default api;
