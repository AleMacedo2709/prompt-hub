
import MainLayout from "@/components/layout/MainLayout";
import PromptGrid from "@/components/prompts/PromptGrid";

// Importar dados mockados
import { mockPrompts } from "@/utils/mock-data";

const Favorites = () => {
  // Filtrar prompts favoritados
  const favoritePrompts = mockPrompts.filter(prompt => prompt.isFavorited);

  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-mp-primary mb-2">
            Prompts Favoritos
          </h1>
          <p className="text-gray-600">
            Acesse rapidamente os prompts que você favoritou.
          </p>
        </div>
        
        <PromptGrid 
          prompts={favoritePrompts}
          title=""
          emptyMessage="Você ainda não favoritou nenhum prompt."
        />
      </div>
    </MainLayout>
  );
};

export default Favorites;
