
import { Home, FolderOpen, User, Heart, Search, FileText, Plus } from "lucide-react";
import { Link, useLocation } from "react-router-dom";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Sidebar as SidebarComponent,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarTrigger,
} from "@/components/ui/sidebar";
import { currentUser } from "@/utils/mock-data";

// Itens de navegação principal
const navItems = [
  {
    title: "Dashboard",
    icon: Home,
    path: "/",
  },
  {
    title: "Explorar Prompts",
    icon: Search,
    path: "/explore",
  },
  {
    title: "Meus Prompts",
    icon: FileText,
    path: "/my-prompts",
  },
  {
    title: "Categorias",
    icon: FolderOpen,
    path: "/categories",
  },
  {
    title: "Favoritos",
    icon: Heart,
    path: "/favorites",
  },
  {
    title: "Meu Perfil",
    icon: User,
    path: "/profile",
  },
];

const Sidebar = () => {
  const location = useLocation();
  
  return (
    <SidebarComponent>
      <SidebarHeader className="flex items-center gap-2 px-4 py-3">
        <div className="flex items-center">
          <FileText className="h-6 w-6 text-white" />
          <span className="ml-2 text-lg font-bold text-white">Jurist Prompts</span>
        </div>
        <SidebarTrigger className="ml-auto text-sidebar-foreground" />
      </SidebarHeader>
      
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Navegação</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {navItems.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton asChild isActive={location.pathname === item.path}>
                    <Link to={item.path} className="flex items-center">
                      <item.icon className="mr-2 h-5 w-5" />
                      <span>{item.title}</span>
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
        
        <SidebarGroup>
          <SidebarGroupLabel>Ações</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton asChild>
                  <Link to="/create-prompt" className="flex items-center text-white bg-mp-accent hover:bg-mp-accent/90 px-4 py-2 rounded-md">
                    <Plus className="mr-2 h-5 w-5" />
                    <span>Novo Prompt</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      
      <SidebarFooter>
        <div className="px-3 py-2">
          <div className="flex items-center gap-3 rounded-md border border-sidebar-border p-2">
            <Avatar>
              <AvatarImage src={currentUser.avatar} />
              <AvatarFallback className="bg-mp-accent text-white">
                {currentUser.name.slice(0, 2).toUpperCase()}
              </AvatarFallback>
            </Avatar>
            <div className="flex-1 overflow-hidden">
              <p className="truncate text-sm font-medium text-sidebar-foreground">
                {currentUser.name}
              </p>
              <p className="truncate text-xs text-sidebar-foreground/60">
                {currentUser.role}
              </p>
            </div>
          </div>
        </div>
      </SidebarFooter>
    </SidebarComponent>
  );
};

export default Sidebar;
