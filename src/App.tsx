import { Routes, Route, Navigate } from "react-router-dom";
import Index from "./pages/Index";
import Categories from "./pages/Categories";
import CreatePrompt from "./pages/CreatePrompt";
import EditPrompt from "./pages/EditPrompt";
import Explore from "./pages/Explore";
import Favorites from "./pages/Favorites";
import MyPrompts from "./pages/MyPrompts";
import NotFound from "./pages/NotFound";
import Profile from "./pages/Profile";
import PromptDetail from "./pages/PromptDetail";
import Login from "./pages/Login";
import Approvals from "./pages/Approvals";
import CategoryManagement from "./pages/CategoryManagement";
import UserManagement from "./pages/UserManagement";
import { useState, useEffect } from "react";
import { cn } from '@/utils/cn'

function App() {
  // Set up authentication state
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  
  // Check localStorage for authentication on load and on any changes
  useEffect(() => {
    const checkAuth = () => {
      const auth = localStorage.getItem("isAuthenticated");
      setIsAuthenticated(auth === "true");
    };
    
    // Check on mount
    checkAuth();
    
    // Listen for storage events (if localStorage changes in another tab)
    window.addEventListener('storage', checkAuth);
    
    return () => {
      window.removeEventListener('storage', checkAuth);
    };
  }, []);

  // Protected route component
  const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
    if (!isAuthenticated) {
      return <Navigate to="/login" replace />;
    }
    return children;
  };

  return (
    <div className={cn('min-h-screen bg-background')}>
      <h1>Jurist Prompts Hub</h1>
      <Routes>
        {/* Public routes */}
        <Route path="/login" element={
          isAuthenticated ? <Navigate to="/" replace /> : <Login />
        } />
        
        {/* Protected routes */}
        <Route path="/" element={
          <ProtectedRoute>
            <Index />
          </ProtectedRoute>
        } />
        <Route path="/explore" element={
          <ProtectedRoute>
            <Explore />
          </ProtectedRoute>
        } />
        <Route path="/my-prompts" element={
          <ProtectedRoute>
            <MyPrompts />
          </ProtectedRoute>
        } />
        <Route path="/categories" element={
          <ProtectedRoute>
            <Categories />
          </ProtectedRoute>
        } />
        <Route path="/favorites" element={
          <ProtectedRoute>
            <Favorites />
          </ProtectedRoute>
        } />
        <Route path="/profile" element={
          <ProtectedRoute>
            <Profile />
          </ProtectedRoute>
        } />
        <Route path="/profile/:userId" element={
          <ProtectedRoute>
            <Profile />
          </ProtectedRoute>
        } />
        <Route path="/create-prompt" element={
          <ProtectedRoute>
            <CreatePrompt />
          </ProtectedRoute>
        } />
        <Route path="/edit-prompt/:promptId" element={
          <ProtectedRoute>
            <EditPrompt />
          </ProtectedRoute>
        } />
        <Route path="/prompt/:promptId" element={
          <ProtectedRoute>
            <PromptDetail />
          </ProtectedRoute>
        } />
        
        {/* Admin routes */}
        <Route path="/approvals" element={
          <ProtectedRoute>
            <Approvals />
          </ProtectedRoute>
        } />
        <Route path="/manage/categories" element={
          <ProtectedRoute>
            <CategoryManagement />
          </ProtectedRoute>
        } />
        <Route path="/manage/users" element={
          <ProtectedRoute>
            <UserManagement />
          </ProtectedRoute>
        } />
        
        {/* Catch-all for 404 */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </div>
  );
}

export default App;
