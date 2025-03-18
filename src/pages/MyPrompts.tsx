
import { useState } from "react";
import { Link } from "react-router-dom";
import { Plus } from "lucide-react";
import MainLayout from "@/components/layout/MainLayout";
import PromptGrid from "@/components/prompts/PromptGrid";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

// Importar dados mockados
import { mockPrompts } from "@/utils/mock-data";

const MyPrompts = () => {
  // Mock para simular dados do usuário atual
  const currentUserId = "user1";
  
  // Filtrar prompts do usuário atual
  const userPrompts = mockPrompts.filter(prompt => prompt.createdBy.id === currentUserId);
  
  // Filtrar prompts públicos e privados
  const publicPrompts = userPrompts.filter(prompt => prompt.isPublic);
  const privatePrompts = userPrompts.filter(prompt => !prompt.isPublic);
  
  // Mock para favoritos e curtidos
  const favoritedPrompts = mockPrompts.filter(prompt => prompt.isFavorited);
  const likedPrompts = mockPrompts.filter(prompt => prompt.isLiked);

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold text-mp-primary">Meus Prompts</h1>
          <Button className="bg-mp-accent hover:bg-mp-accent/90" asChild>
            <Link to="/create-prompt" className="flex items-center">
              <Plus className="mr-2 h-4 w-4" />
              Novo Prompt
            </Link>
          </Button>
        </div>
        
        <Tabs defaultValue="all" className="w-full">
          <TabsList className="w-full max-w-md mb-6">
            <TabsTrigger value="all" className="flex-1">Todos</TabsTrigger>
            <TabsTrigger value="public" className="flex-1">Públicos</TabsTrigger>
            <TabsTrigger value="private" className="flex-1">Privados</TabsTrigger>
            <TabsTrigger value="favorites" className="flex-1">Favoritos</TabsTrigger>
            <TabsTrigger value="liked" className="flex-1">Curtidos</TabsTrigger>
          </TabsList>
          
          <TabsContent value="all">
            <PromptGrid 
              prompts={userPrompts.map(p => ({ ...p, isOwner: true }))}
              title="Todos os Meus Prompts"
              emptyMessage="Você ainda não criou nenhum prompt."
            />
          </TabsContent>
          
          <TabsContent value="public">
            <PromptGrid 
              prompts={publicPrompts.map(p => ({ ...p, isOwner: true }))}
              title="Meus Prompts Públicos"
              emptyMessage="Você não tem prompts públicos."
            />
          </TabsContent>
          
          <TabsContent value="private">
            <PromptGrid 
              prompts={privatePrompts.map(p => ({ ...p, isOwner: true }))}
              title="Meus Prompts Privados"
              emptyMessage="Você não tem prompts privados."
            />
          </TabsContent>
          
          <TabsContent value="favorites">
            <PromptGrid 
              prompts={favoritedPrompts}
              title="Prompts Favoritos"
              emptyMessage="Você não favoritou nenhum prompt ainda."
            />
          </TabsContent>
          
          <TabsContent value="liked">
            <PromptGrid 
              prompts={likedPrompts}
              title="Prompts Curtidos"
              emptyMessage="Você não curtiu nenhum prompt ainda."
            />
          </TabsContent>
        </Tabs>
      </div>
    </MainLayout>
  );
};

export default MyPrompts;
