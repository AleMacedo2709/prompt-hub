
import { useState } from "react";
import MainLayout from "@/components/layout/MainLayout";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import PromptGrid from "@/components/prompts/PromptGrid";

// Importar dados mockados
import { mockPrompts } from "@/utils/mock-data";

// Lista completa de categorias jurídicas
const categories = [
  { id: "criminal", name: "Direito Criminal", icon: "⚖️", color: "bg-red-100 text-red-800", count: 0 },
  { id: "civil", name: "Direito Civil", icon: "📝", color: "bg-blue-100 text-blue-800", count: 0 },
  { id: "family", name: "Direito de Família", icon: "👪", color: "bg-green-100 text-green-800", count: 0 },
  { id: "consumer", name: "Direito do Consumidor", icon: "🛒", color: "bg-yellow-100 text-yellow-800", count: 0 },
  { id: "administrative", name: "Direito Administrativo", icon: "🏛️", color: "bg-purple-100 text-purple-800", count: 0 },
  { id: "constitutional", name: "Direito Constitucional", icon: "📜", color: "bg-indigo-100 text-indigo-800", count: 0 },
  { id: "environmental", name: "Direito Ambiental", icon: "🌿", color: "bg-emerald-100 text-emerald-800", count: 0 },
  { id: "labor", name: "Direito do Trabalho", icon: "👷", color: "bg-orange-100 text-orange-800", count: 0 },
  { id: "election", name: "Direito Eleitoral", icon: "🗳️", color: "bg-pink-100 text-pink-800", count: 0 },
  { id: "tax", name: "Direito Tributário", icon: "💰", color: "bg-gray-100 text-gray-800", count: 0 },
];

// Contar o número de prompts por categoria
categories.forEach(category => {
  category.count = mockPrompts.filter(prompt => prompt.category === category.id).length;
});

const Categories = () => {
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  
  // Filtrar prompts pela categoria selecionada
  const categoryPrompts = selectedCategory 
    ? mockPrompts.filter(prompt => prompt.category === selectedCategory)
    : [];

  return (
    <MainLayout>
      <div className="space-y-8">
        <div>
          <h1 className="text-3xl font-bold text-mp-primary mb-2">
            Categorias
          </h1>
          <p className="text-gray-600">
            Explore prompts jurídicos organizados por área do direito.
          </p>
        </div>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
          {categories.map((category) => (
            <Card 
              key={category.id} 
              className={`cursor-pointer transition-all hover:shadow-md ${
                selectedCategory === category.id ? "ring-2 ring-mp-primary" : ""
              }`}
              onClick={() => setSelectedCategory(
                selectedCategory === category.id ? null : category.id
              )}
            >
              <CardHeader className="p-4 pb-2">
                <CardTitle className="flex items-center text-lg">
                  <span className="mr-2 text-2xl">{category.icon}</span>
                  {category.name}
                </CardTitle>
              </CardHeader>
              <CardContent className="p-4 pt-2">
                <CardDescription>
                  {category.count} {category.count === 1 ? "prompt" : "prompts"}
                </CardDescription>
              </CardContent>
            </Card>
          ))}
        </div>
        
        {selectedCategory && (
          <div className="mt-8">
            <Tabs defaultValue="all" className="w-full">
              <TabsList className="w-full max-w-md mb-6">
                <TabsTrigger value="all" className="flex-1">Todos</TabsTrigger>
                <TabsTrigger value="recent" className="flex-1">Mais Recentes</TabsTrigger>
                <TabsTrigger value="popular" className="flex-1">Mais Populares</TabsTrigger>
              </TabsList>
              
              <TabsContent value="all">
                <PromptGrid 
                  prompts={categoryPrompts}
                  title={`Prompts de ${categories.find(c => c.id === selectedCategory)?.name}`}
                  emptyMessage={`Nenhum prompt encontrado na categoria ${
                    categories.find(c => c.id === selectedCategory)?.name
                  }`}
                />
              </TabsContent>
              
              <TabsContent value="recent">
                <PromptGrid 
                  prompts={[...categoryPrompts].sort(
                    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
                  )}
                  title={`Prompts Recentes de ${
                    categories.find(c => c.id === selectedCategory)?.name
                  }`}
                  emptyMessage={`Nenhum prompt encontrado na categoria ${
                    categories.find(c => c.id === selectedCategory)?.name
                  }`}
                  allowSorting={false}
                />
              </TabsContent>
              
              <TabsContent value="popular">
                <PromptGrid 
                  prompts={[...categoryPrompts].sort(
                    (a, b) => b.likesCount - a.likesCount
                  )}
                  title={`Prompts Populares de ${
                    categories.find(c => c.id === selectedCategory)?.name
                  }`}
                  emptyMessage={`Nenhum prompt encontrado na categoria ${
                    categories.find(c => c.id === selectedCategory)?.name
                  }`}
                  allowSorting={false}
                />
              </TabsContent>
            </Tabs>
          </div>
        )}
      </div>
    </MainLayout>
  );
};

export default Categories;
