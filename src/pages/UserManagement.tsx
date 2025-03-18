
import { useState } from "react";
import MainLayout from "@/components/layout/MainLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Edit, Trash2, Plus, Search } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { useToast } from "@/hooks/use-toast";

// Mock users
const mockUsers = [
  {
    id: "user1",
    name: "Ana Silva",
    email: "ana.silva@mp.gov.br",
    role: "admin",
    department: "Criminal",
    active: true,
    avatar: "",
  },
  {
    id: "user2",
    name: "Carlos Oliveira",
    email: "carlos.oliveira@mp.gov.br",
    role: "approver",
    department: "Civil",
    active: true,
    avatar: "",
  },
  {
    id: "user3",
    name: "Juliana Martins",
    email: "juliana.martins@mp.gov.br",
    role: "user",
    department: "Ambiental",
    active: true,
    avatar: "",
  },
  {
    id: "user4",
    name: "Ricardo Santos",
    email: "ricardo.santos@mp.gov.br",
    role: "user",
    department: "Consumidor",
    active: false,
    avatar: "",
  },
];

const roleLabels = {
  admin: { label: "Administrador", color: "bg-purple-100 text-purple-800" },
  approver: { label: "Aprovador", color: "bg-blue-100 text-blue-800" },
  user: { label: "Usuário", color: "bg-gray-100 text-gray-800" },
};

const UserManagement = () => {
  const { toast } = useToast();
  const [users, setUsers] = useState(mockUsers);
  const [searchTerm, setSearchTerm] = useState("");
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [newUser, setNewUser] = useState({
    name: "",
    email: "",
    role: "user",
    department: "",
    active: true,
  });
  
  const filteredUsers = users.filter(user => 
    user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.department.toLowerCase().includes(searchTerm.toLowerCase())
  );
  
  const handleCreateUser = () => {
    if (!newUser.name.trim() || !newUser.email.trim() || !newUser.department.trim()) {
      toast({
        title: "Erro",
        description: "Todos os campos são obrigatórios.",
        variant: "destructive"
      });
      return;
    }
    
    const id = `user${users.length + 1}`;
    setUsers([...users, { ...newUser, id, avatar: "" }]);
    setIsDialogOpen(false);
    
    // Reset form
    setNewUser({
      name: "",
      email: "",
      role: "user",
      department: "",
      active: true,
    });
    
    toast({
      title: "Usuário criado",
      description: `O usuário "${newUser.name}" foi criado com sucesso.`
    });
  };
  
  const toggleUserStatus = (id: string) => {
    setUsers(users.map(user => 
      user.id === id ? { ...user, active: !user.active } : user
    ));
    
    const user = users.find(u => u.id === id);
    toast({
      title: user?.active ? "Usuário desativado" : "Usuário ativado",
      description: `O usuário "${user?.name}" foi ${user?.active ? "desativado" : "ativado"} com sucesso.`
    });
  };
  
  const deleteUser = (id: string) => {
    const userToDelete = users.find(u => u.id === id);
    setUsers(users.filter(user => user.id !== id));
    
    toast({
      title: "Usuário excluído",
      description: `O usuário "${userToDelete?.name}" foi excluído com sucesso.`
    });
  };

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-mp-primary">Gerenciar Usuários</h1>
            <p className="text-gray-600 mt-1">
              Adicione, edite ou remova usuários e defina suas permissões
            </p>
          </div>
          
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button className="bg-mp-primary hover:bg-mp-primary/90">
                <Plus className="mr-2 h-4 w-4" />
                Novo Usuário
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Novo Usuário</DialogTitle>
                <DialogDescription>
                  Adicione um novo usuário ao sistema.
                </DialogDescription>
              </DialogHeader>
              
              <div className="space-y-4 py-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="user-name">Nome</Label>
                    <Input 
                      id="user-name" 
                      placeholder="Nome completo"
                      value={newUser.name}
                      onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="user-email">E-mail</Label>
                    <Input 
                      id="user-email" 
                      type="email"
                      placeholder="email@mp.gov.br"
                      value={newUser.email}
                      onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                    />
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="user-role">Função</Label>
                    <Select 
                      value={newUser.role} 
                      onValueChange={(value) => setNewUser({ ...newUser, role: value })}
                    >
                      <SelectTrigger id="user-role">
                        <SelectValue placeholder="Selecione uma função" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="admin">Administrador</SelectItem>
                        <SelectItem value="approver">Aprovador</SelectItem>
                        <SelectItem value="user">Usuário</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="user-department">Departamento</Label>
                    <Input 
                      id="user-department" 
                      placeholder="Ex: Departamento Criminal"
                      value={newUser.department}
                      onChange={(e) => setNewUser({ ...newUser, department: e.target.value })}
                    />
                  </div>
                </div>
                
                <div className="flex items-center space-x-2">
                  <Switch 
                    id="user-active" 
                    checked={newUser.active}
                    onCheckedChange={(checked) => setNewUser({ ...newUser, active: checked })}
                  />
                  <Label htmlFor="user-active">Usuário ativo</Label>
                </div>
              </div>
              
              <DialogFooter>
                <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                  Cancelar
                </Button>
                <Button onClick={handleCreateUser} className="bg-mp-primary hover:bg-mp-primary/90">
                  Criar Usuário
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
        
        {/* Search field */}
        <div className="relative">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Buscar usuários por nome, e-mail ou departamento..."
            className="w-full pl-8"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        
        <Card>
          <CardContent className="p-6">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Usuário</TableHead>
                  <TableHead>Função</TableHead>
                  <TableHead>Departamento</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredUsers.map((user) => (
                  <TableRow key={user.id}>
                    <TableCell>
                      <div className="flex items-center space-x-3">
                        <Avatar>
                          <AvatarImage src={user.avatar} />
                          <AvatarFallback className="bg-mp-primary text-white">
                            {user.name.split(' ').map(n => n[0]).join('').toUpperCase()}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <div className="font-medium">{user.name}</div>
                          <div className="text-sm text-gray-500">{user.email}</div>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge className={roleLabels[user.role as keyof typeof roleLabels].color}>
                        {roleLabels[user.role as keyof typeof roleLabels].label}
                      </Badge>
                    </TableCell>
                    <TableCell>{user.department}</TableCell>
                    <TableCell>
                      <div className="flex items-center space-x-2">
                        <Switch 
                          checked={user.active} 
                          onCheckedChange={() => toggleUserStatus(user.id)} 
                        />
                        <span className={user.active ? "text-green-600" : "text-gray-500"}>
                          {user.active ? "Ativo" : "Inativo"}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end space-x-2">
                        <Button variant="ghost" size="sm">
                          <Edit className="h-4 w-4" />
                        </Button>
                        
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button variant="ghost" size="sm">
                              <Trash2 className="h-4 w-4 text-red-500" />
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
                              <AlertDialogDescription>
                                Tem certeza que deseja excluir o usuário "{user.name}"? Esta ação não poderá ser desfeita.
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Cancelar</AlertDialogCancel>
                              <AlertDialogAction 
                                onClick={() => deleteUser(user.id)}
                                className="bg-red-500 text-white hover:bg-red-600"
                              >
                                Excluir
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
                
                {filteredUsers.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center py-10 text-gray-500">
                      Nenhum usuário encontrado. Ajuste o termo de busca ou adicione novos usuários.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  );
};

export default UserManagement;
