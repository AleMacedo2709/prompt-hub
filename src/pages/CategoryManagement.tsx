
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import MainLayout from "@/components/layout/MainLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Edit, Trash2, Plus, Save, X } from "lucide-react";
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

// Iniciar com as categorias existentes no mock-data
import { categories } from "@/utils/mock-data";

const CategoryManagement = () => {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [allCategories, setAllCategories] = useState(categories);
  const [newCategory, setNewCategory] = useState({ id: "", name: "" });
  const [editingCategory, setEditingCategory] = useState<{ index: number; id: string; name: string } | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  
  const handleCreateCategory = () => {
    if (!newCategory.name.trim()) {
      toast({
        title: "Erro",
        description: "O nome da categoria não pode estar vazio.",
        variant: "destructive"
      });
      return;
    }
    
    // Generate a simple ID based on the name
    const id = newCategory.name.toLowerCase().replace(/\s+/g, "-");
    
    setAllCategories([...allCategories, { id, name: newCategory.name }]);
    setNewCategory({ id: "", name: "" });
    setIsDialogOpen(false);
    
    toast({
      title: "Categoria criada",
      description: `A categoria "${newCategory.name}" foi criada com sucesso.`
    });
  };
  
  const startEditingCategory = (index: number) => {
    setEditingCategory({
      index,
      id: allCategories[index].id,
      name: allCategories[index].name
    });
  };
  
  const cancelEditingCategory = () => {
    setEditingCategory(null);
  };
  
  const saveEditingCategory = () => {
    if (!editingCategory) return;
    
    const updatedCategories = [...allCategories];
    updatedCategories[editingCategory.index] = {
      id: editingCategory.id,
      name: editingCategory.name
    };
    
    setAllCategories(updatedCategories);
    setEditingCategory(null);
    
    toast({
      title: "Categoria atualizada",
      description: `A categoria foi atualizada com sucesso.`
    });
  };
  
  const deleteCategory = (index: number) => {
    const categoryToDelete = allCategories[index];
    const updatedCategories = allCategories.filter((_, i) => i !== index);
    setAllCategories(updatedCategories);
    
    toast({
      title: "Categoria excluída",
      description: `A categoria "${categoryToDelete.name}" foi excluída com sucesso.`
    });
  };

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-mp-primary">Gerenciar Categorias</h1>
            <p className="text-gray-600 mt-1">
              Adicione, edite ou remova categorias para organizar os prompts
            </p>
          </div>
          
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button className="bg-mp-primary hover:bg-mp-primary/90">
                <Plus className="mr-2 h-4 w-4" />
                Nova Categoria
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Nova Categoria</DialogTitle>
                <DialogDescription>
                  Adicione uma nova categoria para classificar os prompts.
                </DialogDescription>
              </DialogHeader>
              
              <div className="space-y-4 py-4">
                <div className="space-y-2">
                  <Label htmlFor="category-name">Nome da Categoria</Label>
                  <Input 
                    id="category-name" 
                    placeholder="Ex: Direito Processual Civil"
                    value={newCategory.name}
                    onChange={(e) => setNewCategory({ ...newCategory, name: e.target.value })}
                  />
                </div>
              </div>
              
              <DialogFooter>
                <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                  Cancelar
                </Button>
                <Button onClick={handleCreateCategory} className="bg-mp-primary hover:bg-mp-primary/90">
                  Criar Categoria
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
        
        <Card>
          <CardContent className="p-6">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ID</TableHead>
                  <TableHead>Nome</TableHead>
                  <TableHead className="w-[100px] text-right">Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {allCategories.map((category, index) => (
                  <TableRow key={category.id}>
                    <TableCell className="font-medium">
                      {editingCategory?.index === index ? (
                        <Input 
                          value={editingCategory.id}
                          onChange={(e) => setEditingCategory({ ...editingCategory, id: e.target.value })}
                          className="w-full"
                        />
                      ) : (
                        category.id
                      )}
                    </TableCell>
                    <TableCell>
                      {editingCategory?.index === index ? (
                        <Input 
                          value={editingCategory.name}
                          onChange={(e) => setEditingCategory({ ...editingCategory, name: e.target.value })}
                          className="w-full"
                        />
                      ) : (
                        category.name
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      {editingCategory?.index === index ? (
                        <div className="flex justify-end space-x-2">
                          <Button variant="ghost" size="sm" onClick={cancelEditingCategory}>
                            <X className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm" onClick={saveEditingCategory}>
                            <Save className="h-4 w-4" />
                          </Button>
                        </div>
                      ) : (
                        <div className="flex justify-end space-x-2">
                          <Button variant="ghost" size="sm" onClick={() => startEditingCategory(index)}>
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
                                  Tem certeza que deseja excluir a categoria "{category.name}"? Esta ação não poderá ser desfeita.
                                </AlertDialogDescription>
                              </AlertDialogHeader>
                              <AlertDialogFooter>
                                <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                <AlertDialogAction 
                                  onClick={() => deleteCategory(index)}
                                  className="bg-red-500 text-white hover:bg-red-600"
                                >
                                  Excluir
                                </AlertDialogAction>
                              </AlertDialogFooter>
                            </AlertDialogContent>
                          </AlertDialog>
                        </div>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
                
                {allCategories.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={3} className="text-center py-10 text-gray-500">
                      Nenhuma categoria cadastrada. Clique em "Nova Categoria" para adicionar.
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

export default CategoryManagement;
