
import { useState } from "react";
import { useParams } from "react-router-dom";
import { Mail, MapPin, Briefcase, Edit, Trash2, AlertTriangle } from "lucide-react";
import MainLayout from "@/components/layout/MainLayout";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
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
} from "@/components/ui/alert-dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import PromptGrid from "@/components/prompts/PromptGrid";
import { useToast } from "@/hooks/use-toast";

// Importar dados mockados
import { mockPrompts } from "@/utils/mock-data";
import { PromptType } from "@/components/prompts/PromptCard";

// Mock do usuário
const userProfiles = [
  {
    id: "user1",
    name: "João Silva",
    email: "joao.silva@mp.gov.br",
    role: "Promotor de Justiça",
    unit: "Central de Inquéritos",
    location: "São Paulo, SP",
    bio: "Promotor de Justiça com atuação em casos criminais. Especialista em crimes contra o patrimônio e organizações criminosas.",
    interests: ["Direito Penal", "Processo Penal", "Tribunal do Júri"],
    avatar: "",
  },
  {
    id: "user2",
    name: "Maria Oliveira",
    email: "maria.oliveira@mp.gov.br",
    role: "Promotora de Justiça",
    unit: "Promotoria de Justiça Criminal",
    location: "Rio de Janeiro, RJ",
    bio: "Promotora com experiência em casos complexos de corrupção e lavagem de dinheiro.",
    interests: ["Crimes contra Administração Pública", "Direito Anticorrupção"],
    avatar: "",
  },
];

const Profile = () => {
  const { userId } = useParams();
  const { toast } = useToast();
  
  // Se userId for fornecido, buscar esse perfil. Caso contrário, mostrar o perfil do usuário atual (user1)
  const profileId = userId || "user1";
  const isCurrentUser = profileId === "user1"; // Mock - Em produção, verificar se é o usuário logado
  
  const userProfile = userProfiles.find(user => user.id === profileId);
  
  // Estado para edição do perfil
  const [editedProfile, setEditedProfile] = useState(userProfile);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  
  // Estado para armazenar os prompts
  const [prompts, setPrompts] = useState(mockPrompts);
  
  // Filtrar prompts do usuário (incluindo privados se for o usuário atual)
  const userPrompts = prompts.filter(prompt => {
    if (prompt.createdBy.id === profileId) {
      // Se for o usuário atual, mostrar todos os prompts (públicos e privados)
      // Se for outro usuário, mostrar apenas os prompts públicos
      return isCurrentUser || prompt.isPublic;
    }
    return false;
  }).map(prompt => ({
    ...prompt,
    isOwner: isCurrentUser
  }));
  
  // Filtrar prompts favoritados pelo usuário
  const favoritedPrompts = prompts.filter(prompt => 
    prompt.isFavorited && isCurrentUser
  );
  
  if (!userProfile) {
    return (
      <MainLayout>
        <div className="text-center py-12">
          <h2 className="text-2xl font-bold text-gray-700">Usuário não encontrado</h2>
          <p className="text-gray-500 mt-2">O perfil que você está procurando não existe.</p>
        </div>
      </MainLayout>
    );
  }
  
  const handleProfileUpdate = () => {
    // Em produção, enviar requisição para o backend
    setIsDialogOpen(false);
    toast({
      title: "Perfil atualizado",
      description: "Seu perfil foi atualizado com sucesso.",
    });
  };
  
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setEditedProfile({
      ...editedProfile!,
      [name]: value,
    });
  };

  // Função para lidar com curtidas em prompts
  const handleLikePrompt = (id: string) => {
    // Em produção, enviar requisição para o backend
    setPrompts(prevPrompts => 
      prevPrompts.map(prompt => 
        prompt.id === id 
          ? { 
              ...prompt, 
              isLiked: !prompt.isLiked,
              likesCount: prompt.isLiked ? prompt.likesCount - 1 : prompt.likesCount + 1
            } 
          : prompt
      )
    );
  };

  // Função para lidar com favoritar prompts
  const handleFavoritePrompt = (id: string) => {
    // Em produção, enviar requisição para o backend
    setPrompts(prevPrompts => 
      prevPrompts.map(prompt => 
        prompt.id === id 
          ? { ...prompt, isFavorited: !prompt.isFavorited } 
          : prompt
      )
    );
    
    toast({
      title: "Prompt favoritado",
      description: "O prompt foi adicionado aos seus favoritos.",
    });
  };

  // Função para lidar com exclusão de prompts
  const handleDeletePrompt = (id: string) => {
    // Em produção, enviar requisição para o backend
    setPrompts(prevPrompts => prevPrompts.filter(prompt => prompt.id !== id));
    
    toast({
      title: "Prompt excluído",
      description: "O prompt foi excluído com sucesso.",
    });
  };

  return (
    <MainLayout>
      <div className="space-y-8">
        <Card>
          <CardContent className="p-6">
            <div className="flex flex-col md:flex-row gap-6">
              <div className="flex-shrink-0 flex flex-col items-center">
                <Avatar className="h-32 w-32">
                  <AvatarImage src={userProfile.avatar} />
                  <AvatarFallback className="text-3xl bg-mp-primary text-white">
                    {userProfile.name.slice(0, 2).toUpperCase()}
                  </AvatarFallback>
                </Avatar>
                
                {isCurrentUser && (
                  <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                    <DialogTrigger asChild>
                      <Button 
                        variant="outline" 
                        size="sm" 
                        className="mt-4 flex items-center"
                      >
                        <Edit className="mr-2 h-4 w-4" />
                        Editar Perfil
                      </Button>
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Editar Perfil</DialogTitle>
                      </DialogHeader>
                      <div className="space-y-4 mt-4">
                        <div className="space-y-2">
                          <Label htmlFor="unit">Unidade/Comarca</Label>
                          <Input
                            id="unit"
                            name="unit"
                            value={editedProfile?.unit}
                            onChange={handleInputChange}
                          />
                        </div>
                        
                        <div className="space-y-2">
                          <Label htmlFor="location">Localização</Label>
                          <Input
                            id="location"
                            name="location"
                            value={editedProfile?.location}
                            onChange={handleInputChange}
                          />
                        </div>
                        
                        <div className="space-y-2">
                          <Label htmlFor="bio">Biografia</Label>
                          <Textarea
                            id="bio"
                            name="bio"
                            value={editedProfile?.bio}
                            onChange={handleInputChange}
                            rows={4}
                          />
                        </div>
                        
                        <div className="space-y-2">
                          <Label htmlFor="interests">Interesses (separados por vírgula)</Label>
                          <Input
                            id="interests"
                            name="interests"
                            value={editedProfile?.interests.join(", ")}
                            onChange={(e) => {
                              setEditedProfile({
                                ...editedProfile!,
                                interests: e.target.value.split(",").map(i => i.trim()).filter(Boolean),
                              });
                            }}
                          />
                        </div>
                        
                        <div className="flex justify-end mt-4">
                          <Button onClick={handleProfileUpdate}>
                            Salvar Alterações
                          </Button>
                        </div>
                      </div>
                    </DialogContent>
                  </Dialog>
                )}
              </div>
              
              <div className="flex-1">
                <h1 className="text-2xl font-bold text-mp-primary mb-2">
                  {userProfile.name}
                </h1>
                <p className="text-lg text-gray-600 mb-4">{userProfile.role}</p>
                
                <div className="space-y-2 text-gray-600">
                  <div className="flex items-center">
                    <Mail className="h-4 w-4 mr-2" />
                    {userProfile.email}
                  </div>
                  
                  {userProfile.unit && (
                    <div className="flex items-center">
                      <Briefcase className="h-4 w-4 mr-2" />
                      {userProfile.unit}
                    </div>
                  )}
                  
                  {userProfile.location && (
                    <div className="flex items-center">
                      <MapPin className="h-4 w-4 mr-2" />
                      {userProfile.location}
                    </div>
                  )}
                </div>
                
                {userProfile.bio && (
                  <div className="mt-4">
                    <h3 className="font-medium text-gray-700 mb-1">Sobre</h3>
                    <p className="text-gray-600">{userProfile.bio}</p>
                  </div>
                )}
                
                {userProfile.interests && userProfile.interests.length > 0 && (
                  <div className="mt-4">
                    <h3 className="font-medium text-gray-700 mb-1">Interesses</h3>
                    <div className="flex flex-wrap gap-1">
                      {userProfile.interests.map((interest) => (
                        <span 
                          key={interest}
                          className="inline-flex items-center rounded-full bg-mp-light px-2.5 py-0.5 text-xs font-medium text-mp-primary"
                        >
                          {interest}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Tabs defaultValue="prompts" className="w-full">
          <TabsList className="w-full max-w-md mb-6">
            <TabsTrigger value="prompts" className="flex-1">Prompts Compartilhados</TabsTrigger>
            {isCurrentUser && (
              <TabsTrigger value="favorites" className="flex-1">Prompts Favoritos</TabsTrigger>
            )}
            <TabsTrigger value="activity" className="flex-1">Atividade Recente</TabsTrigger>
          </TabsList>
          
          <TabsContent value="prompts">
            <PromptGrid 
              prompts={userPrompts}
              title={`Prompts de ${userProfile.name}`}
              emptyMessage={
                isCurrentUser 
                  ? "Você ainda não compartilhou nenhum prompt."
                  : "Este usuário ainda não compartilhou nenhum prompt público."
              }
              isOwner={isCurrentUser}
              allowViewToggle={true}
              onLike={handleLikePrompt}
              onFavorite={handleFavoritePrompt}
              onDelete={handleDeletePrompt}
            />
          </TabsContent>
          
          {isCurrentUser && (
            <TabsContent value="favorites">
              <PromptGrid 
                prompts={favoritedPrompts}
                title="Meus Prompts Favoritos"
                emptyMessage="Você ainda não favoritou nenhum prompt."
                onLike={handleLikePrompt}
                onFavorite={handleFavoritePrompt}
              />
            </TabsContent>
          )}
          
          <TabsContent value="activity">
            <Card>
              <CardHeader>
                <h3 className="text-lg font-medium">Atividade Recente</h3>
              </CardHeader>
              <CardContent>
                <p className="text-gray-500 text-center py-8">
                  Funcionalidade em desenvolvimento.
                </p>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </MainLayout>
  );
};

export default Profile;
