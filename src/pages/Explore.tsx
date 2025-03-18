
import { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import MainLayout from "@/components/layout/MainLayout";
import PromptGrid from "@/components/prompts/PromptGrid";
import CategoryFilter from "@/components/prompts/CategoryFilter";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Search } from "lucide-react";

// Importar os prompts mockados e categorias
import { mockPrompts, categories } from "@/utils/mock-data";

const Explore = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const defaultTab = searchParams.get('tab') || "todos";
  
  const [activeTab, setActiveTab] = useState(defaultTab);
  const [selectedCategories, setSelectedCategories] = useState<string[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  
  // Update URL when tab changes
  useEffect(() => {
    if (activeTab !== "todos") {
      searchParams.set('tab', activeTab);
      setSearchParams(searchParams);
    } else {
      if (searchParams.has('tab')) {
        searchParams.delete('tab');
        setSearchParams(searchParams);
      }
    }
  }, [activeTab, searchParams, setSearchParams]);
  
  // Filter prompts based on categories and search term
  const filterPrompts = (prompts) => {
    let filtered = [...prompts];
    
    // Filter by categories if any are selected
    if (selectedCategories.length > 0) {
      filtered = filtered.filter(prompt => 
        selectedCategories.includes(prompt.category)
      );
    }
    
    // Filter by search term if any
    if (searchTerm.trim() !== "") {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(prompt => 
        prompt.title.toLowerCase().includes(term) || 
        prompt.description.toLowerCase().includes(term) ||
        prompt.keywords.some(keyword => keyword.toLowerCase().includes(term))
      );
    }
    
    return filtered;
  };
  
  // Prepare different prompt lists
  const allPrompts = filterPrompts(mockPrompts);
  
  const recentPrompts = filterPrompts([...mockPrompts].sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  ));
  
  const popularPrompts = filterPrompts([...mockPrompts].sort(
    (a, b) => b.likesCount - a.likesCount
  ));

  return (
    <MainLayout>
      <div className="space-y-8">
        <div>
          <h1 className="text-3xl font-bold text-mp-primary mb-2">
            Explorar Prompts
          </h1>
          <p className="text-gray-600">
            Descubra prompts jurídicos compartilhados pela comunidade do Ministério Público.
          </p>
        </div>

        {/* Search field */}
        <div className="relative">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Buscar prompts por título, descrição ou palavras-chave..."
            className="w-full pl-8"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        {/* Category filter */}
        <CategoryFilter 
          categories={categories}
          selectedCategories={selectedCategories}
          onCategoryChange={setSelectedCategories}
        />
        
        {/* Tabbed interface */}
        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="w-full max-w-md mb-6">
            <TabsTrigger value="todos" className="flex-1">Todos</TabsTrigger>
            <TabsTrigger value="recentes" className="flex-1">Mais Recentes</TabsTrigger>
            <TabsTrigger value="populares" className="flex-1">Mais Populares</TabsTrigger>
          </TabsList>
          
          <TabsContent value="todos">
            <PromptGrid 
              prompts={allPrompts}
              title="Todos os Prompts"
              emptyMessage={
                allPrompts.length === 0 && searchTerm
                  ? "Nenhum prompt encontrado para os termos de busca"
                  : selectedCategories.length > 0
                    ? "Nenhum prompt encontrado nas categorias selecionadas"
                    : "Nenhum prompt disponível"
              }
              allowViewToggle={true}
            />
          </TabsContent>
          
          <TabsContent value="recentes">
            <PromptGrid 
              prompts={recentPrompts}
              title="Prompts Mais Recentes"
              emptyMessage={
                recentPrompts.length === 0 && searchTerm
                  ? "Nenhum prompt recente encontrado para os termos de busca"
                  : selectedCategories.length > 0
                    ? "Nenhum prompt recente encontrado nas categorias selecionadas"
                    : "Nenhum prompt recente disponível"
              }
              allowSorting={false}
              allowViewToggle={true}
            />
          </TabsContent>
          
          <TabsContent value="populares">
            <PromptGrid 
              prompts={popularPrompts}
              title="Prompts Mais Populares"
              emptyMessage={
                popularPrompts.length === 0 && searchTerm
                  ? "Nenhum prompt popular encontrado para os termos de busca"
                  : selectedCategories.length > 0
                    ? "Nenhum prompt popular encontrado nas categorias selecionadas"
                    : "Nenhum prompt popular disponível"
              }
              allowSorting={false}
              allowViewToggle={true}
            />
          </TabsContent>
        </Tabs>
      </div>
    </MainLayout>
  );
};

export default Explore;
