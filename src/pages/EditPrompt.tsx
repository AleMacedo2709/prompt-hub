
import { useParams } from "react-router-dom";
import MainLayout from "@/components/layout/MainLayout";
import PromptForm from "@/components/forms/PromptForm";

// Importar dados mockados
import { mockPrompts } from "@/utils/mock-data";

const EditPrompt = () => {
  const { promptId } = useParams();
  const prompt = mockPrompts.find(p => p.id === promptId);

  if (!prompt) {
    return (
      <MainLayout>
        <div className="text-center py-12">
          <h2 className="text-2xl font-bold text-gray-700">Prompt não encontrado</h2>
          <p className="text-gray-500 mt-2">O prompt que você está tentando editar não existe ou foi removido.</p>
        </div>
      </MainLayout>
    );
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <h1 className="text-3xl font-bold text-mp-primary">Editar Prompt</h1>
        <p className="text-gray-600">
          Atualize as informações do seu prompt jurídico.
        </p>
        
        <PromptForm prompt={prompt} isEditing={true} />
      </div>
    </MainLayout>
  );
};

export default EditPrompt;
