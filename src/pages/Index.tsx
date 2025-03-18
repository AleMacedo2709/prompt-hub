import { useState } from "react";
import { Link } from "react-router-dom";
import { DateRange } from 'react-day-picker'
import { addDays, format } from 'date-fns'
import { ptBR } from 'date-fns/locale'
import {
  BarChart as BarChartIcon,
  Activity,
  Users,
  FileText,
} from "lucide-react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts'
import MainLayout from "@/components/layout/MainLayout";
import PromptGrid from "@/components/prompts/PromptGrid";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useDashboard } from '@/hooks/useDashboard'
import { cn } from '@/utils/cn'

// Cores para os gráficos
const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8']

const Index = () => {
  const [activeTab, setActiveTab] = useState("overview");
  
  // Estado para o filtro de data
  const [dateRange, setDateRange] = useState<DateRange | undefined>({
    from: addDays(new Date(), -30),
    to: new Date(),
  })

  // Buscar dados do dashboard
  const { data: dashboardData, isLoading, error } = useDashboard({
    dataInicio: dateRange?.from,
    dataFim: dateRange?.to,
  })

  if (isLoading) {
    return (
      <MainLayout>
        <div className="flex items-center justify-center min-h-screen">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-mp-primary" />
        </div>
      </MainLayout>
    )
  }

  if (error) {
    return (
      <MainLayout>
        <div className="flex items-center justify-center min-h-screen">
          <div className="text-red-500">Erro ao carregar dados do dashboard</div>
        </div>
      </MainLayout>
    )
  }

  if (!dashboardData) {
    return null
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-start">
          <div>
            <h1 className="text-3xl font-bold text-mp-primary">Dashboard</h1>
            <p className="text-gray-600 mt-1">
              Bem-vindo ao Jurist Prompts Hub do Ministério Público
            </p>
          </div>
          <Button asChild className="bg-mp-primary hover:bg-mp-primary/90">
            <Link to="/create-prompt">Criar Novo Prompt</Link>
          </Button>
        </div>
        
        {/* Dashboard Tabs */}
        <Tabs defaultValue="overview" value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="w-full max-w-md mb-6">
            <TabsTrigger value="overview" className="flex-1">Visão Geral</TabsTrigger>
            <TabsTrigger value="analytics" className="flex-1">Análises</TabsTrigger>
            <TabsTrigger value="activity" className="flex-1">Atividade</TabsTrigger>
          </TabsList>
          
          {/* Overview Tab */}
          <TabsContent value="overview">
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium">Total de Prompts</CardTitle>
                  <FileText className="h-4 w-4 text-gray-500" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.stats.totalPrompts}</div>
                  <p className="text-xs text-gray-500">
                    {dashboardData.stats.promptsAprovados} aprovados
                  </p>
                </CardContent>
              </Card>
              
              <Card>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium">Usuários Ativos</CardTitle>
                  <Users className="h-4 w-4 text-gray-500" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.stats.usuariosAtivos}</div>
                  <p className="text-xs text-gray-500">de {dashboardData.stats.totalUsuarios} total</p>
                </CardContent>
              </Card>
              
              <Card>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium">Curtidas</CardTitle>
                  <Activity className="h-4 w-4 text-gray-500" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.stats.totalCurtidas}</div>
                  <p className="text-xs text-gray-500">{dashboardData.stats.totalFavoritos} favoritos</p>
                </CardContent>
              </Card>
              
              <Card>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium">Pendentes Aprovação</CardTitle>
                  <BarChartIcon className="h-4 w-4 text-gray-500" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.stats.promptsPendentes}</div>
                  <p className="text-xs text-gray-500">
                    <Link to="/approvals" className="text-mp-primary hover:underline">
                      Ver todos
                    </Link>
                  </p>
                </CardContent>
              </Card>
            </div>
            
            <div className="mt-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-semibold text-mp-primary">Top Prompts</h2>
                <Button variant="link" asChild className="text-mp-primary">
                  <Link to="/explore">Ver todos</Link>
                </Button>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {dashboardData.topPrompts.map((prompt) => (
                  <Card key={prompt.PromptId}>
                    <CardHeader className="flex flex-row items-start justify-between pb-2">
                      <div>
                        <CardTitle className="text-sm font-medium">
                          <Link to={`/prompt/${prompt.PromptId}`} className="hover:text-mp-primary">
                            {prompt.Titulo}
                          </Link>
                        </CardTitle>
                        <p className="text-xs text-gray-500">por {prompt.autor.Nome}</p>
                      </div>
                      <img
                        src={prompt.autor.Avatar}
                        alt={prompt.autor.Nome}
                        className="w-8 h-8 rounded-full"
                      />
                    </CardHeader>
                    <CardContent>
                      <div className="flex items-center justify-between text-sm text-gray-500">
                        <span>{prompt.curtidas} curtidas</span>
                        <span>{prompt.favoritos} favoritos</span>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </div>
          </TabsContent>
          
          {/* Analytics Tab */}
          <TabsContent value="analytics">
            <div className="space-y-6">
              {/* Gráfico de Tendências */}
              <Card>
                <CardHeader>
                  <CardTitle>Tendências de Prompts</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="h-[300px]">
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={dashboardData.promptsPorDia}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis
                          dataKey="data"
                          tickFormatter={(value) => format(new Date(value), 'dd/MM', { locale: ptBR })}
                        />
                        <YAxis />
                        <Tooltip
                          labelFormatter={(value) => format(new Date(value), 'dd/MM/yyyy', { locale: ptBR })}
                        />
                        <Legend />
                        <Bar dataKey="valor" name="Prompts" fill="#0088FE" />
                      </BarChart>
                    </ResponsiveContainer>
                  </div>
                </CardContent>
              </Card>

              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Distribuição por Categoria */}
                <Card>
                  <CardHeader>
                    <CardTitle>Distribuição por Categoria</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="h-[300px]">
                      <ResponsiveContainer width="100%" height="100%">
                        <PieChart>
                          <Pie
                            data={dashboardData.distribuicaoCategorias}
                            dataKey="quantidade"
                            nameKey="Nome"
                            cx="50%"
                            cy="50%"
                            outerRadius={80}
                            label={(entry) => `${entry.Nome} (${entry.percentual}%)`}
                          >
                            {dashboardData.distribuicaoCategorias.map((_, index) => (
                              <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                            ))}
                          </Pie>
                          <Tooltip />
                          <Legend />
                        </PieChart>
                      </ResponsiveContainer>
                    </div>
                  </CardContent>
                </Card>

                {/* Top Usuários */}
                <Card>
                  <CardHeader>
                    <CardTitle>Top Usuários</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      {dashboardData.topUsuarios.map((usuario) => (
                        <div
                          key={usuario.UsuarioId}
                          className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                        >
                          <div className="flex items-center space-x-4">
                            <img
                              src={usuario.Avatar}
                              alt={usuario.Nome}
                              className="w-10 h-10 rounded-full"
                            />
                            <div>
                              <p className="font-medium">{usuario.Nome}</p>
                              <p className="text-sm text-gray-500">
                                {usuario.totalPrompts} prompts • {usuario.totalCurtidas} curtidas
                              </p>
                            </div>
                          </div>
                          <div className="text-sm font-medium text-gray-900">
                            {usuario.totalFavoritos} favoritos
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </div>
            </div>
          </TabsContent>
          
          {/* Activity Tab */}
          <TabsContent value="activity">
            <Card>
              <CardHeader>
                <CardTitle>Atividade Recente</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {dashboardData.topUsuarios.slice(0, 5).map((usuario) => (
                    <div key={usuario.UsuarioId} className="flex items-start space-x-4 border-b pb-4">
                      <img
                        src={usuario.Avatar}
                        alt={usuario.Nome}
                        className="w-10 h-10 rounded-full"
                      />
                      <div>
                        <p className="font-medium">{usuario.Nome} criou um novo prompt</p>
                        <p className="text-sm text-gray-500">Há {Math.floor(Math.random() * 24)} horas</p>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </MainLayout>
  );
};

export default Index;
