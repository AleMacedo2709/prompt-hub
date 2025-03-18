
import { ReactNode } from "react";
import Sidebar from "./Sidebar";
import Header from "./Header";
import { SidebarProvider } from "@/components/ui/sidebar";

interface MainLayoutProps {
  children: ReactNode;
}

const MainLayout = ({ children }: MainLayoutProps) => {
  return (
    <SidebarProvider>
      <div className="min-h-screen flex w-full">
        <Sidebar />
        <div className="flex-1 flex flex-col">
          <Header />
          <main className="flex-1 p-6">{children}</main>
          <footer className="py-4 px-6 text-center text-sm text-gray-500 border-t">
            © {new Date().getFullYear()} Ministério Público Estadual - Jurist Prompts Hub
          </footer>
        </div>
      </div>
    </SidebarProvider>
  );
};

export default MainLayout;
