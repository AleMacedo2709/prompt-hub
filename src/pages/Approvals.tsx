
import { useState } from "react";
import MainLayout from "@/components/layout/MainLayout";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Search, CheckCircle, XCircle, AlertCircle, RotateCcw } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import {
  Pagination,
  PaginationContent,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from "@/components/ui/pagination";

// Mock data for pending approvals
const pendingPrompts = [
  {
    id: "pend-001",
    title: "Manifestação de Arquivamento de Inquérito Civil",
    category: "criminal",
    createdBy: {
      name: "Ana Silva",
      role: "Promotora de Justiça"
    },
    submittedAt: "2023-10-15T14:30:00Z",
    excerpt: "Considerando que as diligências realizadas não encontraram elementos suficientes para...",
    keywords: ["inquérito civil", "arquivamento", "diligências"]
  },
  {
    id: "pend-002",
    title: "Petição Inicial - Improbidade Administrativa",
    category: "administrative",
    createdBy: {
      name: "Carlos Oliveira",
      role: "Promotor de Justiça"
    },
    submittedAt: "2023-10-17T09:45:00Z",
    excerpt: "O Ministério Público Estadual, por seu órgão de execução, vem à presença de Vossa Excelência...",
    keywords: ["improbidade", "administrativa", "petição inicial"]
  },
  {
    id: "pend-003",
    title: "Recurso Especial - Crimes Ambientais",
    category: "environmental",
    createdBy: {
      name: "Juliana Martins",
      role: "Promotora de Justiça"
    },
    submittedAt: "2023-10-18T16:20:00Z",
    excerpt: "O Ministério Público do Estado, não se conformando com o v. acórdão proferido pela...",
    keywords: ["recurso especial", "ambiental", "crime"]
  }
];

// Mock data for approved prompts
const approvedPromptsMock = [
  {
    id: "app-001",
    title: "Modelo de Parecer em Habeas Corpus",
    category: "criminal",
    createdBy: {
      name: "Roberto Fernandes",
      role: "Promotor de Justiça"
    },
    submittedAt: "2023-10-10T11:20:00Z",
    approvedAt: "2023-10-12T14:30:00Z",
    excerpt: "Trata-se de Habeas Corpus impetrado em favor de [nome], alegando constrangimento ilegal...",
    keywords: ["habeas corpus", "constrangimento ilegal", "criminal"]
  },
  {
    id: "app-002",
    title: "Alegações Finais - Tráfico de Drogas",
    category: "criminal",
    createdBy: {
      name: "Mariana Costa",
      role: "Promotora de Justiça"
    },
    submittedAt: "2023-10-08T09:15:00Z",
    approvedAt: "2023-10-09T16:45:00Z",
    excerpt: "MM. Juiz, Trata-se de ação penal pública incondicionada promovida pelo Ministério Público...",
    keywords: ["alegações finais", "tráfico", "drogas"]
  },
  {
    id: "app-003",
    title: "Recomendação - Regularização Ambiental",
    category: "environmental",
    createdBy: {
      name: "Paulo Mendes",
      role: "Promotor de Justiça"
    },
    submittedAt: "2023-10-05T13:40:00Z", 
    approvedAt: "2023-10-07T10:20:00Z",
    excerpt: "O MINISTÉRIO PÚBLICO DO ESTADO, por meio da Promotoria de Justiça do Meio Ambiente...",
    keywords: ["recomendação", "ambiental", "regularização"]
  }
];

// Mock data for rejected prompts
const rejectedPromptsMock = [
  {
    id: "rej-001",
    title: "Acordo de Não Persecução Penal - Versão Inicial",
    category: "criminal",
    createdBy: {
      name: "Luiz Henrique",
      role: "Assistente Jurídico"
    },
    submittedAt: "2023-10-11T15:30:00Z",
    rejectedAt: "2023-10-13T09:15:00Z",
    rejectionReason: "Necessita revisão quanto aos requisitos legais",
    excerpt: "Pelo presente instrumento, o MINISTÉRIO PÚBLICO DO ESTADO, por seu órgão de execução...",
    keywords: ["ANPP", "acordo", "não persecução"]
  },
  {
    id: "rej-002",
    title: "Ação Civil Pública - Dano Ambiental",
    category: "environmental",
    createdBy: {
      name: "Teresa Alves",
      role: "Analista Jurídica"
    },
    submittedAt: "2023-10-09T14:20:00Z",
    rejectedAt: "2023-10-10T11:30:00Z",
    rejectionReason: "Inconsistências na fundamentação jurídica",
    excerpt: "O MINISTÉRIO PÚBLICO DO ESTADO, no uso de suas atribuições constitucionais e legais...",
    keywords: ["ação civil pública", "dano ambiental", "reparação"]
  }
];

const Approvals = () => {
  const { toast } = useToast();
  const [searchTerm, setSearchTerm] = useState("");
  const [activeTab, setActiveTab] = useState("pending");
  const [pendingItems, setPendingItems] = useState(pendingPrompts);
  const [approvedItems, setApprovedItems] = useState(approvedPromptsMock);
  const [rejectedItems, setRejectedItems] = useState(rejectedPromptsMock);
  
  // Filter prompts based on search term and active tab
  const getFilteredPrompts = () => {
    let items = [];
    
    switch(activeTab) {
      case "pending":
        items = pendingItems;
        break;
      case "approved":
        items = approvedItems;
        break;
      case "rejected":
        items = rejectedItems;
        break;
      default:
        items = pendingItems;
    }
    
    return items.filter(prompt => 
      prompt.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      prompt.createdBy.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      prompt.keywords.some(keyword => keyword.toLowerCase().includes(searchTerm.toLowerCase()))
    );
  };
  
  const filteredPrompts = getFilteredPrompts();
  
  const handleApprove = (id: string) => {
    // Find the prompt to approve
    const promptToApprove = pendingItems.find(p => p.id === id);
    if (!promptToApprove) return;
    
    // Add to approved list with approval timestamp
    const approvedPrompt = {
      ...promptToApprove,
      approvedAt: new Date().toISOString()
    };
    
    setApprovedItems([approvedPrompt, ...approvedItems]);
    
    // Remove from pending list
    setPendingItems(pendingItems.filter(p => p.id !== id));
    
    toast({
      title: "Prompt aprovado",
      description: "O prompt foi aprovado e agora está disponível publicamente.",
    });
  };
  
  const handleReject = (id: string) => {
    // Find the prompt to reject
    const promptToReject = pendingItems.find(p => p.id === id);
    if (!promptToReject) return;
    
    // Add to rejected list with rejection timestamp and default reason
    const rejectedPrompt = {
      ...promptToReject,
      rejectedAt: new Date().toISOString(),
      rejectionReason: "Não atende aos padrões de qualidade"
    };
    
    setRejectedItems([rejectedPrompt, ...rejectedItems]);
    
    // Remove from pending list
    setPendingItems(pendingItems.filter(p => p.id !== id));
    
    toast({
      title: "Prompt rejeitado",
      description: "O prompt foi rejeitado e o autor foi notificado.",
    });
  };
  
  const handleReconsider = (id: string) => {
    // Find the prompt to reconsider
    let promptToReconsider;
    let sourceList;
    
    if (activeTab === "approved") {
      promptToReconsider = approvedItems.find(p => p.id === id);
      sourceList = "approved";
    } else if (activeTab === "rejected") {
      promptToReconsider = rejectedItems.find(p => p.id === id);
      sourceList = "rejected";
    }
    
    if (!promptToReconsider) return;
    
    // Add back to pending list
    setPendingItems([promptToReconsider, ...pendingItems]);
    
    // Remove from source list
    if (sourceList === "approved") {
      setApprovedItems(approvedItems.filter(p => p.id !== id));
    } else if (sourceList === "rejected") {
      setRejectedItems(rejectedItems.filter(p => p.id !== id));
    }
    
    toast({
      title: "Prompt movido para revisão",
      description: "O prompt foi movido de volta para a lista de pendentes para reconsideração.",
    });
  };

  return (
    <MainLayout>
      <div className="space-y-8">
        <div>
          <h1 className="text-3xl font-bold text-mp-primary mb-2">
            Aprovação de Prompts
          </h1>
          <p className="text-gray-600">
            Avalie e aprove prompts submetidos pela comunidade antes da publicação.
          </p>
        </div>
        
        {/* Search field */}
        <div className="relative">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Buscar prompts por título, autor ou palavras-chave..."
            className="w-full pl-8"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        
        {/* Tabbed interface */}
        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="w-full max-w-md mb-6">
            <TabsTrigger value="pending" className="flex-1">
              Pendentes
              <Badge variant="secondary" className="ml-2 bg-amber-100 text-amber-800">
                {pendingItems.length}
              </Badge>
            </TabsTrigger>
            <TabsTrigger value="approved" className="flex-1">
              Aprovados
              <Badge variant="secondary" className="ml-2 bg-green-100 text-green-800">
                {approvedItems.length}
              </Badge>
            </TabsTrigger>
            <TabsTrigger value="rejected" className="flex-1">
              Rejeitados
              <Badge variant="secondary" className="ml-2 bg-red-100 text-red-800">
                {rejectedItems.length}
              </Badge>
            </TabsTrigger>
          </TabsList>
          
          {/* Pending Tab Content */}
          <TabsContent value="pending">
            {filteredPrompts.length === 0 ? (
              <div className="text-center py-12">
                <AlertCircle className="mx-auto h-12 w-12 text-gray-400" />
                <h3 className="mt-4 text-lg font-medium">Nenhum prompt pendente</h3>
                <p className="mt-2 text-gray-500">
                  Não há prompts aguardando aprovação no momento.
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                {filteredPrompts.map((prompt) => (
                  <Card key={prompt.id}>
                    <CardHeader className="pb-2">
                      <div className="flex justify-between">
                        <CardTitle className="text-lg">{prompt.title}</CardTitle>
                        <Badge className="bg-mp-light text-mp-primary">
                          {prompt.category}
                        </Badge>
                      </div>
                    </CardHeader>
                    <CardContent className="pb-2">
                      <div className="flex justify-between text-sm text-gray-500 mb-2">
                        <span>Por: {prompt.createdBy.name} ({prompt.createdBy.role})</span>
                        <span>
                          Submetido em: {new Date(prompt.submittedAt).toLocaleDateString('pt-BR')}
                        </span>
                      </div>
                      
                      <p className="text-gray-700 mb-2">{prompt.excerpt}...</p>
                      
                      <div className="flex flex-wrap gap-1 mt-2">
                        {prompt.keywords.map((keyword) => (
                          <Badge key={keyword} variant="outline" className="bg-gray-100">
                            {keyword}
                          </Badge>
                        ))}
                      </div>
                    </CardContent>
                    <CardFooter className="flex justify-between border-t pt-4">
                      <Button 
                        variant="outline" 
                        className="text-red-500 hover:text-red-700"
                        onClick={() => handleReject(prompt.id)}
                      >
                        <XCircle className="mr-2 h-4 w-4" />
                        Rejeitar
                      </Button>
                      <Button 
                        variant="default" 
                        className="bg-mp-primary hover:bg-mp-primary/90"
                        onClick={() => handleApprove(prompt.id)}
                      >
                        <CheckCircle className="mr-2 h-4 w-4" />
                        Aprovar
                      </Button>
                    </CardFooter>
                  </Card>
                ))}
              </div>
            )}
          </TabsContent>
          
          {/* Approved Tab Content */}
          <TabsContent value="approved">
            {filteredPrompts.length === 0 ? (
              <div className="text-center py-12">
                <CheckCircle className="mx-auto h-12 w-12 text-green-500" />
                <h3 className="mt-4 text-lg font-medium">Nenhum prompt aprovado</h3>
                <p className="mt-2 text-gray-500">
                  Não há prompts aprovados com os filtros atuais.
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                {filteredPrompts.map((prompt) => (
                  <Card key={prompt.id}>
                    <CardHeader className="pb-2">
                      <div className="flex justify-between">
                        <CardTitle className="text-lg">{prompt.title}</CardTitle>
                        <Badge className="bg-green-100 text-green-800">
                          Aprovado
                        </Badge>
                      </div>
                    </CardHeader>
                    <CardContent className="pb-2">
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-gray-500 mb-2">
                        <span>Por: {prompt.createdBy.name}</span>
                        <span>Categoria: {prompt.category}</span>
                        <span>Submetido: {new Date(prompt.submittedAt).toLocaleDateString('pt-BR')}</span>
                        <span>Aprovado: {new Date(prompt.approvedAt).toLocaleDateString('pt-BR')}</span>
                      </div>
                      
                      <p className="text-gray-700 mb-2">{prompt.excerpt}...</p>
                      
                      <div className="flex flex-wrap gap-1 mt-2">
                        {prompt.keywords.map((keyword) => (
                          <Badge key={keyword} variant="outline" className="bg-gray-100">
                            {keyword}
                          </Badge>
                        ))}
                      </div>
                    </CardContent>
                    <CardFooter className="flex justify-end border-t pt-4">
                      <Button 
                        variant="outline"
                        onClick={() => handleReconsider(prompt.id)}
                      >
                        <RotateCcw className="mr-2 h-4 w-4" />
                        Reconsiderar
                      </Button>
                    </CardFooter>
                  </Card>
                ))}
                
                {/* Pagination for approved items */}
                <Pagination>
                  <PaginationContent>
                    <PaginationItem>
                      <PaginationPrevious href="#" />
                    </PaginationItem>
                    <PaginationItem>
                      <PaginationLink href="#" isActive>1</PaginationLink>
                    </PaginationItem>
                    <PaginationItem>
                      <PaginationLink href="#">2</PaginationLink>
                    </PaginationItem>
                    <PaginationItem>
                      <PaginationLink href="#">3</PaginationLink>
                    </PaginationItem>
                    <PaginationItem>
                      <PaginationNext href="#" />
                    </PaginationItem>
                  </PaginationContent>
                </Pagination>
              </div>
            )}
          </TabsContent>
          
          {/* Rejected Tab Content */}
          <TabsContent value="rejected">
            {filteredPrompts.length === 0 ? (
              <div className="text-center py-12">
                <XCircle className="mx-auto h-12 w-12 text-red-500" />
                <h3 className="mt-4 text-lg font-medium">Nenhum prompt rejeitado</h3>
                <p className="mt-2 text-gray-500">
                  Não há prompts rejeitados com os filtros atuais.
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                {filteredPrompts.map((prompt) => (
                  <Card key={prompt.id}>
                    <CardHeader className="pb-2">
                      <div className="flex justify-between">
                        <CardTitle className="text-lg">{prompt.title}</CardTitle>
                        <Badge className="bg-red-100 text-red-800">
                          Rejeitado
                        </Badge>
                      </div>
                    </CardHeader>
                    <CardContent className="pb-2">
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-gray-500 mb-2">
                        <span>Por: {prompt.createdBy.name}</span>
                        <span>Categoria: {prompt.category}</span>
                        <span>Submetido: {new Date(prompt.submittedAt).toLocaleDateString('pt-BR')}</span>
                        <span>Rejeitado: {new Date(prompt.rejectedAt).toLocaleDateString('pt-BR')}</span>
                      </div>
                      
                      <div className="bg-red-50 p-3 rounded-md mb-3 text-sm">
                        <strong>Motivo da rejeição:</strong> {prompt.rejectionReason}
                      </div>
                      
                      <p className="text-gray-700 mb-2">{prompt.excerpt}...</p>
                      
                      <div className="flex flex-wrap gap-1 mt-2">
                        {prompt.keywords.map((keyword) => (
                          <Badge key={keyword} variant="outline" className="bg-gray-100">
                            {keyword}
                          </Badge>
                        ))}
                      </div>
                    </CardContent>
                    <CardFooter className="flex justify-end border-t pt-4">
                      <Button 
                        variant="outline"
                        onClick={() => handleReconsider(prompt.id)}
                      >
                        <RotateCcw className="mr-2 h-4 w-4" />
                        Reconsiderar
                      </Button>
                    </CardFooter>
                  </Card>
                ))}
                
                {/* Pagination for rejected items */}
                <Pagination>
                  <PaginationContent>
                    <PaginationItem>
                      <PaginationPrevious href="#" />
                    </PaginationItem>
                    <PaginationItem>
                      <PaginationLink href="#" isActive>1</PaginationLink>
                    </PaginationItem>
                    <PaginationItem>
                      <PaginationLink href="#">2</PaginationLink>
                    </PaginationItem>
                    <PaginationItem>
                      <PaginationNext href="#" />
                    </PaginationItem>
                  </PaginationContent>
                </Pagination>
              </div>
            )}
          </TabsContent>
        </Tabs>
      </div>
    </MainLayout>
  );
};

export default Approvals;
