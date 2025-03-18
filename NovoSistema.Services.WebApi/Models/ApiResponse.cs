namespace NovoSistema.Services.WebApi.Models
{
    public class ApiResponse<T>
    {
        public bool Sucesso { get; set; }
        public string Mensagem { get; set; }
        public T Dados { get; set; }
        public Paginacao Paginacao { get; set; }
    }

    public class Paginacao
    {
        public int PaginaAtual { get; set; }
        public int TotalPaginas { get; set; }
        public int TamanhoPagina { get; set; }
        public int TotalRegistros { get; set; }
    }
} 