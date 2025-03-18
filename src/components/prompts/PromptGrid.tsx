
import { useState } from "react";
import { ViewIcon, Rows3Icon, Globe, Lock, Trash2, Edit, ExternalLink } from "lucide-react";
import PromptCard, { PromptType } from "./PromptCard";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { 
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Link } from "react-router-dom";
import { useToast } from "@/hooks/use-toast";

interface PromptGridProps {
  prompts: PromptType[];
  title: string;
  emptyMessage?: string;
  allowSorting?: boolean;
  allowViewToggle?: boolean;
  isOwner?: boolean;
  onDelete?: (id: string) => void;
  onLike?: (id: string) => void;
  onFavorite?: (id: string) => void;
}

const PromptGrid = ({ 
  prompts, 
  title, 
  emptyMessage = "Nenhum prompt encontrado", 
  allowSorting = true,
  allowViewToggle = true,
  isOwner = false,
  onDelete,
  onLike,
  onFavorite
}: PromptGridProps) => {
  const [sortOption, setSortOption] = useState("recent");
  const [viewMode, setViewMode] = useState<"card" | "table">("card");
  const { toast } = useToast();
  
  const sortedPrompts = [...prompts].sort((a, b) => {
    if (sortOption === "recent") {
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    } else if (sortOption === "popular") {
      return b.likesCount - a.likesCount;
    } else if (sortOption === "alphabetical") {
      return a.title.localeCompare(b.title);
    }
    return 0;
  });

  const handleViewToggle = (mode: "card" | "table") => {
    setViewMode(mode);
  };

  const handleDelete = (id: string) => {
    if (onDelete) {
      onDelete(id);
      toast({
        title: "Prompt excluído",
        description: "O prompt foi excluído com sucesso.",
      });
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-mp-primary">{title}</h2>
        
        <div className="flex items-center gap-4">
          {allowViewToggle && prompts.length > 0 && (
            <div className="flex items-center border rounded-md">
              <Button
                variant="ghost"
                size="sm"
                className={`${viewMode === 'card' ? 'bg-mp-light text-mp-primary' : ''}`}
                onClick={() => handleViewToggle("card")}
              >
                <ViewIcon className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="sm"
                className={`${viewMode === 'table' ? 'bg-mp-light text-mp-primary' : ''}`}
                onClick={() => handleViewToggle("table")}
              >
                <Rows3Icon className="h-4 w-4" />
              </Button>
            </div>
          )}
          
          {allowSorting && prompts.length > 0 && (
            <div className="flex items-center space-x-2">
              <span className="text-sm text-gray-500">Ordenar por:</span>
              <Select value={sortOption} onValueChange={setSortOption}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Ordenar por" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="recent">Mais recentes</SelectItem>
                  <SelectItem value="popular">Mais populares</SelectItem>
                  <SelectItem value="alphabetical">Ordem alfabética</SelectItem>
                </SelectContent>
              </Select>
            </div>
          )}
        </div>
      </div>
      
      {sortedPrompts.length > 0 ? (
        <>
          {viewMode === "card" ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {sortedPrompts.map((prompt) => (
                <PromptCard 
                  key={prompt.id} 
                  prompt={prompt} 
                  onLike={onLike}
                  onFavorite={onFavorite}
                  onDelete={isOwner ? handleDelete : undefined}
                />
              ))}
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Título</TableHead>
                  <TableHead>Categoria</TableHead>
                  <TableHead>Visibilidade</TableHead>
                  <TableHead>Likes</TableHead>
                  <TableHead>Data</TableHead>
                  <TableHead className="text-right">Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {sortedPrompts.map((prompt) => (
                  <TableRow key={prompt.id}>
                    <TableCell className="font-medium">
                      <div className="flex flex-col">
                        <span>{prompt.title}</span>
                        <span className="text-xs text-gray-500 line-clamp-1">{prompt.description}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline" className="bg-mp-light text-mp-primary">
                        {prompt.category}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      {prompt.isPublic ? (
                        <div className="flex items-center text-green-600">
                          <Globe className="h-4 w-4 mr-1" />
                          <span>Público</span>
                        </div>
                      ) : (
                        <div className="flex items-center text-gray-600">
                          <Lock className="h-4 w-4 mr-1" />
                          <span>Privado</span>
                        </div>
                      )}
                    </TableCell>
                    <TableCell>{prompt.likesCount}</TableCell>
                    <TableCell>{new Date(prompt.createdAt).toLocaleDateString('pt-BR')}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button asChild variant="ghost" size="sm">
                          <Link to={`/prompt/${prompt.id}`}>
                            <ExternalLink className="h-4 w-4" />
                          </Link>
                        </Button>
                        
                        {isOwner && (
                          <>
                            <Button asChild variant="ghost" size="sm">
                              <Link to={`/edit-prompt/${prompt.id}`}>
                                <Edit className="h-4 w-4" />
                              </Link>
                            </Button>
                            <Button 
                              variant="ghost" 
                              size="sm"
                              className="text-destructive hover:text-destructive hover:bg-destructive/10"
                              onClick={() => handleDelete(prompt.id)}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </>
      ) : (
        <div className="text-center py-12">
          <p className="text-gray-500">{emptyMessage}</p>
        </div>
      )}
    </div>
  );
};

export default PromptGrid;
