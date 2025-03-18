using System;
using System.Collections.Generic;

namespace NovoSistema.Domain.Models
{
    public class Prompt
    {
        public string PromptId { get; set; }
        public string Titulo { get; set; }
        public string Descricao { get; set; }
        public string Conteudo { get; set; }
        public string CategoriaId { get; set; }
        public bool Publico { get; set; }
        public string Status { get; set; }
        public int UsuarioCriadorId { get; set; }
        public DateTime DataCriacao { get; set; }
        public DateTime? DataAtualizacao { get; set; }
        public DateTime? DataAprovacao { get; set; }
        public int? UsuarioAprovadorId { get; set; }

        // Propriedades de navegação
        public virtual Categoria Categoria { get; set; }
        public virtual Usuario UsuarioCriador { get; set; }
        public virtual Usuario UsuarioAprovador { get; set; }
        public virtual ICollection<string> PalavrasChave { get; set; }
        public virtual int CurtidasCount { get; set; }
        public virtual bool CurtidoPeloUsuarioAtual { get; set; }
        public virtual bool FavoritadoPeloUsuarioAtual { get; set; }

        public Prompt()
        {
            PalavrasChave = new List<string>();
            DataCriacao = DateTime.Now;
            Status = "pending";
        }
    }
} 