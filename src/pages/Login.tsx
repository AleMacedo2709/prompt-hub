
import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { Separator } from "@/components/ui/separator";
import { Mail } from "lucide-react";

const Login = () => {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  // Check if already authenticated
  useEffect(() => {
    const auth = localStorage.getItem("isAuthenticated");
    if (auth === "true") {
      navigate("/");
    }
  }, [navigate]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    // Simulate login process
    setTimeout(() => {
      // Set authentication in localStorage
      localStorage.setItem("isAuthenticated", "true");
      
      setLoading(false);
      toast({
        title: "Login realizado com sucesso",
        description: "Bem-vindo ao Jurist Prompts Hub."
      });
      navigate("/");
    }, 1500);
  };

  const handleMicrosoftLogin = () => {
    setLoading(true);
    
    // Simulate Office 365 login
    setTimeout(() => {
      // Set authentication in localStorage
      localStorage.setItem("isAuthenticated", "true");
      
      setLoading(false);
      toast({
        title: "Login com Microsoft realizado",
        description: "Bem-vindo ao Jurist Prompts Hub."
      });
      
      // Force navigation after Microsoft login
      setTimeout(() => {
        navigate("/");
      }, 100);
    }, 1500);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="w-full max-w-md px-4">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-mp-primary">Jurist Prompts Hub</h1>
          <p className="text-gray-600 mt-2">Plataforma de prompts jurídicos para o Ministério Público</p>
        </div>
        
        <Card>
          <CardHeader>
            <CardTitle>Entrar</CardTitle>
            <CardDescription>
              Acesse com sua conta institucional
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button 
              variant="outline" 
              className="w-full flex items-center justify-center gap-2"
              onClick={handleMicrosoftLogin}
              disabled={loading}
            >
              <Mail className="h-5 w-5" />
              Entrar com Office 365
            </Button>
            
            <div className="relative my-6">
              <Separator />
              <span className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 bg-card px-2 text-xs text-muted-foreground">
                OU
              </span>
            </div>
            
            <form onSubmit={handleLogin} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="email">E-mail</Label>
                <Input 
                  id="email" 
                  type="email" 
                  placeholder="seu.email@mp.gov.br" 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                />
              </div>
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label htmlFor="password">Senha</Label>
                  <Button type="button" variant="link" className="text-xs p-0 h-auto">
                    Esqueceu a senha?
                  </Button>
                </div>
                <Input 
                  id="password" 
                  type="password" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
              </div>
              <Button 
                type="submit" 
                className="w-full bg-mp-primary hover:bg-mp-primary/90"
                disabled={loading}
              >
                {loading ? "Entrando..." : "Entrar"}
              </Button>
            </form>
          </CardContent>
          <CardFooter className="flex justify-center">
            <p className="text-sm text-gray-600">
              Acesso exclusivo para membros do Ministério Público
            </p>
          </CardFooter>
        </Card>
      </div>
    </div>
  );
};

export default Login;
