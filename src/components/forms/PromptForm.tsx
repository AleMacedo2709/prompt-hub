import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import { PromptType } from "../prompts/PromptCard";

const promptFormSchema = z.object({
  title: z.string().min(5, "O título deve ter pelo menos 5 caracteres").max(100, "O título não pode ter mais de 100 caracteres"),
  description: z.string().min(10, "A descrição deve ter pelo menos 10 caracteres").max(500, "A descrição não pode ter mais de 500 caracteres"),
  content: z.string().min(10, "O conteúdo deve ter pelo menos 10 caracteres"),
  category: z.string({ required_error: "Por favor, selecione uma categoria" }),
  isPublic: z.boolean().default(true),
  isAnonymous: z.boolean().default(false),
});

type PromptFormValues = z.infer<typeof promptFormSchema>;

const categories = [
  { id: "criminal", name: "Direito Criminal" },
  { id: "civil", name: "Direito Civil" },
  { id: "family", name: "Direito de Família" },
  { id: "consumer", name: "Direito do Consumidor" },
  { id: "administrative", name: "Direito Administrativo" },
  { id: "constitutional", name: "Direito Constitucional" },
  { id: "environmental", name: "Direito Ambiental" },
  { id: "labor", name: "Direito do Trabalho" },
  { id: "election", name: "Direito Eleitoral" },
  { id: "tax", name: "Direito Tributário" },
];

interface PromptFormProps {
  prompt?: PromptType;
  isEditing?: boolean;
}

const PromptForm = ({ prompt, isEditing = false }: PromptFormProps) => {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [keywords, setKeywords] = useState<string[]>(prompt?.keywords || []);
  const [keywordInput, setKeywordInput] = useState("");

  const form = useForm<PromptFormValues>({
    resolver: zodResolver(promptFormSchema),
    defaultValues: {
      title: prompt?.title || "",
      description: prompt?.description || "",
      content: prompt?.content || "",
      category: prompt?.category || "",
      isPublic: prompt?.isPublic || true,
      isAnonymous: false,
    },
  });

  const addKeyword = () => {
    const trimmedKeyword = keywordInput.trim();
    if (trimmedKeyword && !keywords.includes(trimmedKeyword)) {
      setKeywords([...keywords, trimmedKeyword]);
      setKeywordInput("");
    }
  };

  const removeKeyword = (keyword: string) => {
    setKeywords(keywords.filter((k) => k !== keyword));
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      addKeyword();
    }
  };

  const onSubmit = (data: PromptFormValues) => {
    console.log({ ...data, keywords });
    
    toast({
      title: isEditing ? "Prompt atualizado" : "Prompt criado",
      description: isEditing 
        ? "Seu prompt foi atualizado com sucesso." 
        : "Seu prompt foi criado com sucesso.",
    });
    
    navigate(isEditing ? `/prompt/${prompt?.id}` : "/my-prompts");
  };

  const isPublicField = form.watch("isPublic");
  const isAnonymousField = form.watch("isAnonymous");
  
  const handleAnonymousChange = (checked: boolean) => {
    form.setValue("isAnonymous", checked);
  };

  return (
    <Card>
      <CardContent className="p-6">
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <FormField
              control={form.control}
              name="title"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Título</FormLabel>
                  <FormControl>
                    <Input placeholder="Ex: Manifestação de Arquivamento de IP" {...field} />
                  </FormControl>
                  <FormDescription>
                    Um título claro e descritivo para o prompt.
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <FormField
              control={form.control}
              name="description"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Descrição</FormLabel>
                  <FormControl>
                    <Textarea 
                      placeholder="Descreva sucintamente o propósito e uso deste prompt..." 
                      {...field} 
                      rows={3}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <FormField
              control={form.control}
              name="category"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Categoria</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder="Selecione uma categoria" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {categories.map(category => (
                        <SelectItem key={category.id} value={category.id}>
                          {category.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <div className="space-y-2">
              <FormLabel>Palavras-chave</FormLabel>
              <div className="flex items-center space-x-2">
                <Input
                  value={keywordInput}
                  onChange={(e) => setKeywordInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Digite e pressione Enter para adicionar..."
                  className="flex-1"
                />
                <Button 
                  type="button" 
                  onClick={addKeyword}
                  variant="outline"
                >
                  Adicionar
                </Button>
              </div>
              <FormDescription>
                Adicione até 5 palavras-chave relevantes.
              </FormDescription>
              
              {keywords.length > 0 && (
                <div className="flex flex-wrap gap-1 mt-2">
                  {keywords.map((keyword) => (
                    <Badge 
                      key={keyword} 
                      variant="secondary"
                      className="flex items-center gap-1 bg-mp-light text-mp-primary"
                    >
                      {keyword}
                      <button
                        type="button"
                        onClick={() => removeKeyword(keyword)}
                        className="ml-1 rounded-full hover:bg-red-100 p-0.5"
                      >
                        <X className="h-3 w-3 text-red-500" />
                      </button>
                    </Badge>
                  ))}
                </div>
              )}
            </div>
            
            <FormField
              control={form.control}
              name="content"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Conteúdo do Prompt</FormLabel>
                  <FormControl>
                    <Textarea 
                      placeholder="Digite o conteúdo do prompt aqui..." 
                      {...field} 
                      rows={10}
                      className="font-mono"
                    />
                  </FormControl>
                  <FormDescription>
                    O texto completo do prompt que será utilizado.
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <div className="flex flex-col gap-4">
              <FormField
                control={form.control}
                name="isAnonymous"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-center justify-between rounded-lg border p-4">
                    <div className="space-y-0.5">
                      <FormLabel className="text-base">Submissão anônima</FormLabel>
                      <FormDescription>
                        {field.value 
                          ? "Seu nome não será exibido como autor do prompt" 
                          : "Seu nome será exibido como autor do prompt"}
                      </FormDescription>
                    </div>
                    <FormControl>
                      <Switch
                        checked={field.value}
                        onCheckedChange={handleAnonymousChange}
                      />
                    </FormControl>
                  </FormItem>
                )}
              />
              
              <FormField
                control={form.control}
                name="isPublic"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-center justify-between rounded-lg border p-4">
                    <div className="space-y-0.5">
                      <FormLabel className="text-base">Visibilidade</FormLabel>
                      <FormDescription>
                        {`Torne este prompt ${field.value ? "público" : "privado"}`}
                      </FormDescription>
                    </div>
                    <FormControl>
                      <Switch
                        checked={field.value}
                        onCheckedChange={field.onChange}
                      />
                    </FormControl>
                  </FormItem>
                )}
              />
            </div>
            
            <div className="flex justify-end space-x-2">
              <Button 
                type="button" 
                variant="outline"
                onClick={() => navigate(-1)}
              >
                Cancelar
              </Button>
              <Button type="submit" className="bg-mp-primary hover:bg-mp-primary/90">
                {isEditing ? "Atualizar Prompt" : "Criar Prompt"}
              </Button>
            </div>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
};

export default PromptForm;
