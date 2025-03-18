
import { useState } from "react";
import { Link } from "react-router-dom";
import { Heart, Copy, Bookmark, Share, MoreHorizontal, Globe, Lock, Trash2, Edit } from "lucide-react";
import { Card, CardHeader, CardContent, CardFooter } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator
} from "@/components/ui/dropdown-menu";
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

export interface PromptType {
  id: string;
  title: string;
  description: string;
  content: string;
  category: string;
  keywords: string[];
  isPublic: boolean;
  createdBy: {
    id: string;
    name: string;
    role: string;
    avatar: string;
  };
  createdAt: string;
  updatedAt: string;
  likesCount: number;
  isLiked?: boolean;
  isFavorited?: boolean;
  isOwner?: boolean;
}

interface PromptCardProps {
  prompt: PromptType;
  onLike?: (id: string) => void;
  onFavorite?: (id: string) => void;
  onDelete?: (id: string) => void;
}

const PromptCard = ({ prompt, onLike, onFavorite, onDelete }: PromptCardProps) => {
  const { toast } = useToast();
  const [liked, setLiked] = useState(prompt.isLiked || false);
  const [likesCount, setLikesCount] = useState(prompt.likesCount);
  const [favorited, setFavorited] = useState(prompt.isFavorited || false);

  const handleLike = () => {
    setLiked(!liked);
    setLikesCount(liked ? likesCount - 1 : likesCount + 1);
    if (onLike) onLike(prompt.id);
  };

  const handleFavorite = () => {
    setFavorited(!favorited);
    if (onFavorite) onFavorite(prompt.id);
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(prompt.content);
    toast({
      title: "Conteúdo copiado!",
      description: "O prompt foi copiado para a área de transferência.",
    });
  };

  const handleShare = () => {
    navigator.clipboard.writeText(window.location.origin + `/prompt/${prompt.id}`);
    toast({
      title: "Link copiado!",
      description: "O link para este prompt foi copiado para a área de transferência.",
    });
  };

  const handleDeletePrompt = () => {
    if (onDelete) {
      onDelete(prompt.id);
    }
  };

  return (
    <Card className="prompt-card">
      <CardHeader className="p-4 pb-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Avatar className="h-8 w-8">
              <AvatarImage src={prompt.createdBy.avatar} />
              <AvatarFallback className="bg-mp-primary text-white">
                {prompt.createdBy.name.slice(0, 2).toUpperCase()}
              </AvatarFallback>
            </Avatar>
            <div>
              <Link to={`/profile/${prompt.createdBy.id}`} className="text-sm font-medium hover:underline">
                {prompt.createdBy.name}
              </Link>
              <p className="text-xs text-gray-500">{prompt.createdBy.role}</p>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            {prompt.isPublic ? (
              <Badge variant="outline" className="flex gap-1 text-green-600 border-green-200 bg-green-50">
                <Globe className="h-3 w-3" />
                <span className="text-xs">Público</span>
              </Badge>
            ) : (
              <Badge variant="outline" className="flex gap-1 text-gray-600 border-gray-200 bg-gray-50">
                <Lock className="h-3 w-3" />
                <span className="text-xs">Privado</span>
              </Badge>
            )}
            
            {prompt.isOwner && (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="icon" className="h-8 w-8">
                    <MoreHorizontal className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem asChild>
                    <Link to={`/edit-prompt/${prompt.id}`} className="flex items-center gap-2">
                      <Edit className="h-4 w-4" />
                      <span>Editar</span>
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <DropdownMenuItem onSelect={(e) => e.preventDefault()} className="text-destructive flex items-center gap-2">
                        <Trash2 className="h-4 w-4" />
                        <span>Excluir</span>
                      </DropdownMenuItem>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>Excluir prompt</AlertDialogTitle>
                        <AlertDialogDescription>
                          Tem certeza que deseja excluir este prompt? Esta ação não poderá ser desfeita.
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                        <AlertDialogAction 
                          onClick={handleDeletePrompt}
                          className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                        >
                          Excluir
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
                </DropdownMenuContent>
              </DropdownMenu>
            )}
          </div>
        </div>
      </CardHeader>
      
      <CardContent className="p-4 pt-2">
        <Link to={`/prompt/${prompt.id}`} className="block">
          <h3 className="text-lg font-semibold text-gray-900 hover:text-mp-primary transition-colors">
            {prompt.title}
          </h3>
          <p className="text-gray-600 line-clamp-3 mt-1">
            {prompt.description}
          </p>
        </Link>
        
        <div className="flex flex-wrap gap-1 mt-2">
          <Badge variant="outline" className="bg-mp-light text-mp-primary">
            {prompt.category}
          </Badge>
          {prompt.keywords.slice(0, 2).map((keyword) => (
            <Badge key={keyword} variant="outline" className="bg-gray-100">
              {keyword}
            </Badge>
          ))}
          {prompt.keywords.length > 2 && (
            <Badge variant="outline" className="bg-gray-100">
              +{prompt.keywords.length - 2}
            </Badge>
          )}
        </div>
      </CardContent>
      
      <CardFooter className="p-4 pt-2 flex justify-between items-center">
        <div className="flex items-center space-x-4 text-sm text-gray-500">
          <Button 
            variant="ghost" 
            size="sm" 
            className={`flex items-center space-x-1 ${liked ? 'text-red-500' : ''}`}
            onClick={handleLike}
          >
            <Heart className="h-4 w-4" fill={liked ? "currentColor" : "none"} />
            <span>{likesCount}</span>
          </Button>
          
          <Button 
            variant="ghost" 
            size="sm" 
            className={`flex items-center space-x-1 ${favorited ? 'text-yellow-500' : ''}`}
            onClick={handleFavorite}
          >
            <Bookmark className="h-4 w-4" fill={favorited ? "currentColor" : "none"} />
          </Button>
          
          <Button 
            variant="ghost" 
            size="sm" 
            className="flex items-center space-x-1"
            onClick={handleCopy}
          >
            <Copy className="h-4 w-4" />
          </Button>
          
          <Button 
            variant="ghost" 
            size="sm" 
            className="flex items-center space-x-1"
            onClick={handleShare}
          >
            <Share className="h-4 w-4" />
          </Button>
        </div>
        
        <div className="text-xs text-gray-500">
          {new Date(prompt.createdAt).toLocaleDateString('pt-BR')}
        </div>
      </CardFooter>
    </Card>
  );
};

export default PromptCard;
