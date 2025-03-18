
import MainLayout from "@/components/layout/MainLayout";
import PromptForm from "@/components/forms/PromptForm";

const CreatePrompt = () => {
  return (
    <MainLayout>
      <div className="space-y-6">
        <h1 className="text-3xl font-bold text-mp-primary">Criar Novo Prompt</h1>
        <p className="text-gray-600">
          Compartilhe seu conhecimento jurídico com outros membros do Ministério Público.
          Preencha os campos abaixo para criar um novo prompt.
        </p>
        
        <PromptForm />
      </div>
    </MainLayout>
  );
};

export default CreatePrompt;
