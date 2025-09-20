import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "@/hooks/useAuth";
import Home from "./pages/Home";
import StreakDetails from "./pages/StreakDetails";
import SelectHabits from "./pages/SelectHabits";
import Auth from "./pages/Auth";
import CreateStreak from "./pages/CreateStreak";
import Profile from "./pages/Profile";
import NotFound from "./pages/NotFound";
import TemplateManager from "./pages/TemplateManager";
import { PublicStreakView } from "./pages/PublicStreakView";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/auth" element={<Auth />} />
            <Route path="/create" element={<CreateStreak />} />
            <Route path="/streak/:id" element={<StreakDetails />} />
            <Route path="/streak/:id/habits" element={<SelectHabits />} />
            <Route path="/streak/:id/select-habits" element={<SelectHabits />} />
            <Route path="/public/streak/:streakId" element={<PublicStreakView />} />
            <Route path="/profile" element={<Profile />} />
            <Route path="/templates" element={<TemplateManager />} />
            {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
