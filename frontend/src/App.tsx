import { Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { TenantAuthGuard } from '@beacon/tenant-ui';
import { NavigationProvider, AppLayout } from '@beacon/app-layout';
import { Toaster } from 'sonner';
import ProtectedRoute from './components/auth/ProtectedRoute';
import { navigation, level2Navigation, level3Navigation } from './config/navigation';
import DashboardPage from './pages/DashboardPage';
import { TenantSelectionPage } from '@beacon/tenant-ui';
import { SignInPage, SignUpPage } from '@beacon/tenant-ui';

function App() {
  return (
    <>
      <Toaster position="bottom-right" richColors />
      <Routes>
        <Route path="/sign-in/*" element={<SignInPage />} />
        <Route path="/sign-up/*" element={<SignUpPage />} />
        <Route
          path="/tenants"
          element={
            <ProtectedRoute>
              <TenantSelectionPage />
            </ProtectedRoute>
          }
        />
        <Route
          element={
            <ProtectedRoute>
              <TenantAuthGuard>
                <Outlet />
              </TenantAuthGuard>
            </ProtectedRoute>
          }
        >
          <Route
            element={
              <NavigationProvider
                navigation={navigation}
                level2Navigation={level2Navigation}
                level3Navigation={level3Navigation}
              >
                <AppLayout />
              </NavigationProvider>
            }
          >
            <Route index element={<DashboardPage />} />
          </Route>
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </>
  );
}

export default App;
