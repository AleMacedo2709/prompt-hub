import { useState } from "react";
import { useParams, Link } from "react-router-dom";
import { 
  Heart, 
  Copy, 
  Bookmark, 
  Share, 
  Edit, 
  Trash, 
  Lock, 
  Unlock, 
  ChevronLeft 
} from "lucide-react";
import MainLayout from "@/components/layout/MainLayout";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardFooter } from "@/components/ui/card";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
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

// Importar dados mockados
import { mockPrompts, categories } from "@/utils/mock-data";

const PromptDetail = () => {
  const { promptId } = useParams();
  const { toast } = useToast();
  
  // Encontrar o prompt pelo ID nos dados mockados
  const prompt = mockPrompts.find(p => p.id === promptId);
  
  // Estados para interações do usuário
  const [isLiked, setIsLiked] = useState(prompt?.isLiked || false);
  const [likesCount, setLikesCount] = useState(prompt?.likesCount || 0);
  const [isFavorited, setIsFavorited] = useState(prompt?.isFavorited || false);
  const [isPublic, setIsPublic] = useState<boolean>(prompt?.isPublic || true);
  
  // Verificação se o usuário é o dono do prompt (mock)
  const isOwner = true; // Mock - Em produção, verificar se o usuário atual é o dono
  
  if (!prompt) {
    return (
      <MainLayout>
        <div className="text-center py-12">
          <h2 className="text-2xl font-bold text-gray-700">Prompt não encontrado</h2>
          <p className="text-gray-500 mt-2">O prompt que você está procurando não existe ou foi removido.</p>
          <Button className="mt-4" asChild>
            <Link to="/">Voltar para o início</Link>
          </Button>
        </div>
      </MainLayout>
    );
  }
  
  const handleLike = () => {
    setIsLiked(!isLiked);
    setLikesCount(isLiked ? likesCount - 1 : likesCount + 1);
    // Em produção, enviar requisição para o backend
  };
  
  const handleFavorite = () => {
    setIsFavorited(!isFavorited);
    toast({
      title: isFavorited ? "Removido dos favoritos" : "Adicionado aos favoritos",
      description: isFavorited 
        ? "O prompt foi removido da sua lista de favoritos."
        : "O prompt foi adicionado à sua lista de favoritos.",
    });
    // Em produção, enviar requisição para o backend
  };
  
  const handleCopy = () => {
    navigator.clipboard.writeText(prompt.content);
    toast({
      title: "Conteúdo copiado!",
      description: "O prompt foi copiado para a área de transferência.",
    });
  };
  
  const handleShare = () => {
    // Em produção, implementar funcionalidade de compartilhamento
    toast({
      title: "Link copiado!",
      description: "O link do prompt foi copiado para a área de transferência.",
    });
  };
  
  const handleVisibilityToggle = () => {
    setIsPublic((prevState: boolean) => !prevState);
    toast({
      title: isPublic ? "Prompt privado" : "Prompt público",
      description: isPublic 
        ? "O prompt agora é visível apenas para você."
        : "O prompt agora é visível para todos.",
    });
    // Em produção, enviar requisição para o backend
  };
  
  const handleDelete = () => {
    // Em produção, enviar requisição para o backend
    toast({
      title: "Prompt excluído",
      description: "O prompt foi excluído permanentemente.",
    });
  };

  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <Button 
            variant="ghost" 
            className="flex items-center text-gray-500 mb-4"
            asChild
          >
            <Link to="/">
              <ChevronLeft className="h-4 w-4 mr-1" />
              Voltar
            </Link>
          </Button>
          
          <div className="flex items-center justify-between">
            <h1 className="text-3xl font-bold text-mp-primary">{prompt.title}</h1>
            
            {isOwner && (
              <div className="flex items-center space-x-2">
                <TooltipProvider>
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button 
                        variant="outline" 
                        size="icon"
                        onClick={handleVisibilityToggle}
                      >
                        {isPublic ? <Unlock className="h-4 w-4" /> : <Lock className="h-4 w-4" />}
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent>
                      {isPublic ? "Tornar privado" : "Tornar público"}
                    </TooltipContent>
                  </Tooltip>
                </TooltipProvider>
                
                <TooltipProvider>
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button 
                        variant="outline" 
                        size="icon"
                        asChild
                      >
                        <Link to={`/edit-prompt/${prompt.id}`}>
                          <Edit className="h-4 w-4" />
                        </Link>
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent>Editar prompt</TooltipContent>
                  </Tooltip>
                </TooltipProvider>
                
                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <Button variant="outline" size="icon" className="text-red-500">
                      <Trash className="h-4 w-4" />
                    </Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Excluir prompt?</AlertDialogTitle>
                      <AlertDialogDescription>
                        Esta ação não pode ser desfeita. O prompt será excluído permanentemente.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Cancelar</AlertDialogCancel>
                      <AlertDialogAction
                        className="bg-red-500 hover:bg-red-600 text-white"
                        onClick={handleDelete}
                      >
                        Excluir
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              </div>
            )}
          </div>
        </div>
        
        <div className="flex items-center">
          <Avatar className="h-10 w-10 mr-3">
            <AvatarImage src={prompt.createdBy.avatar} />
            <AvatarFallback className="bg-mp-primary text-white">
              {prompt.createdBy.name.slice(0, 2).toUpperCase()}
            </AvatarFallback>
          </Avatar>
          
          <div>
            <Link 
              to={`/profile/${prompt.createdBy.id}`} 
              className="font-medium hover:underline"
            >
              {prompt.createdBy.name}
            </Link>
            <p className="text-sm text-gray-500">{prompt.createdBy.role}</p>
          </div>
          
          <div className="ml-auto text-sm text-gray-500 flex items-center">
            <span className="mr-2">
              Criado em {new Date(prompt.createdAt).toLocaleDateString('pt-BR')}
            </span>
            {prompt.updatedAt !== prompt.createdAt && (
              <span>
                (Atualizado em {new Date(prompt.updatedAt).toLocaleDateString('pt-BR')})
              </span>
            )}
          </div>
        </div>
        
        <div className="flex flex-wrap gap-2">
          <Badge variant="outline" className="bg-mp-light text-mp-primary">
            {categories.find(c => c.id === prompt.category)?.name || prompt.category}
          </Badge>
          
          {prompt.keywords.map((keyword) => (
            <Badge key={keyword} variant="outline" className="bg-gray-100">
              {keyword}
            </Badge>
          ))}
        </div>
        
        <Card>
          <CardContent className="p-6">
            <div className="mb-4">
              <h3 className="text-lg font-medium mb-2 text-mp-primary">Descrição</h3>
              <p className="text-gray-700">{prompt.description}</p>
            </div>
            
            <div>
              <h3 className="text-lg font-medium mb-2 text-mp-primary">Conteúdo</h3>
              <div className="bg-gray-50 p-4 rounded-md border font-mono text-sm whitespace-pre-wrap">
                {prompt.content}
              </div>
            </div>
          </CardContent>
          
          <CardFooter className="flex justify-between items-center p-6 pt-0 border-t">
            <div className="flex items-center space-x-4">
              <Button 
                variant="ghost" 
                size="sm" 
                className={`flex items-center space-x-1 ${isLiked ? 'text-red-500' : ''}`}
                onClick={handleLike}
              >
                <Heart className="h-4 w-4" fill={isLiked ? "currentColor" : "none"} />
                <span>{likesCount}</span>
              </Button>
              
              <Button 
                variant="ghost" 
                size="sm" 
                className={`flex items-center space-x-1 ${isFavorited ? 'text-yellow-500' : ''}`}
                onClick={handleFavorite}
              >
                <Bookmark className="h-4 w-4" fill={isFavorited ? "currentColor" : "none"} />
                <span>Favoritar</span>
              </Button>
              
              <Button 
                variant="ghost" 
                size="sm" 
                className="flex items-center space-x-1"
                onClick={handleCopy}
              >
                <Copy className="h-4 w-4" />
                <span>Copiar</span>
              </Button>
              
              <Button 
                variant="ghost" 
                size="sm" 
                className="flex items-center space-x-1"
                onClick={handleShare}
              >
                <Share className="h-4 w-4" />
                <span>Compartilhar</span>
              </Button>
            </div>
          </CardFooter>
        </Card>
      </div>
    </MainLayout>
  );
};

export default PromptDetail;
