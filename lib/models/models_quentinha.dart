// Modelos focados no fluxo da Quentinha

enum TamanhoQuentinha { P, M, G }

extension TamanhoQuentinhaExtension on TamanhoQuentinha {
  String get nome {
    switch (this) {
      case TamanhoQuentinha.P:
        return 'Pequena';
      case TamanhoQuentinha.M:
        return 'Média';
      case TamanhoQuentinha.G:
        return 'Grande';
    }
  }

  String get sigla {
    switch (this) {
      case TamanhoQuentinha.P:
        return 'P';
      case TamanhoQuentinha.M:
        return 'M';
      case TamanhoQuentinha.G:
        return 'G';
    }
  }
}

class TamanhoOpcao {
  final TamanhoQuentinha tamanho;
  final double preco;
  final bool disponivel;

  TamanhoOpcao({
    required this.tamanho,
    required this.preco,
    this.disponivel = true,
  });
}

class OfertaQuentinha {
  final String id;
  final String nome;
  final String descricao;
  final List<TamanhoOpcao> tamanhos;
  final String? imagemUrl;

  OfertaQuentinha({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.tamanhos,
    this.imagemUrl,
  });
}

class ItemCarrinhoQuentinha {
  final String idItem; // Pode ser gerado com DateTime.now() para mock
  final OfertaQuentinha oferta;
  final TamanhoOpcao tamanhoEscolhido;
  int quantidade;

  ItemCarrinhoQuentinha({
    required this.idItem,
    required this.oferta,
    required this.tamanhoEscolhido,
    this.quantidade = 1,
  });

  double get subtotal => tamanhoEscolhido.preco * quantidade;
}

// ---------------------------------------------------------------------------
// NOVOS MODELOS: DOMÍNIO DE CHECKOUT E DRAFT (EOS-004.2.2)
// ---------------------------------------------------------------------------

class ClienteContato {
  final String nome;
  final String telefoneWhatsApp;

  ClienteContato({required this.nome, required this.telefoneWhatsApp});
}

class EnderecoEntrega {
  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String referencia;
  
  // Preparação futura para geolocalização e mapas (não implementado nesta fase)
  final double? latitudeFutura;
  final double? longitudeFutura;
  final double? precisaoGpsFutura;
  final String? provedorMapaFuturo;

  EnderecoEntrega({
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.complemento = '',
    required this.bairro,
    required this.cidade,
    required this.uf,
    this.referencia = '',
    this.latitudeFutura,
    this.longitudeFutura,
    this.precisaoGpsFutura,
    this.provedorMapaFuturo,
  });
}

enum TipoEntrega { retirada, entrega }
enum FormaPagamentoDraft { pix, dinheiro, cartao, pendente }

/// Representa a intenção do pedido.
/// Será enviado à Transition Engine para virar um "Pedido" definitivo.
class PedidoDraft {
  final List<ItemCarrinhoQuentinha> itens;
  final double subtotalItens;
  
  final ClienteContato? cliente;
  final TipoEntrega tipoEntrega;
  final EnderecoEntrega? endereco; // Obrigatório apenas se tipoEntrega == entrega
  final double taxaEntrega;
  
  final FormaPagamentoDraft formaPagamento;
  final String observacoes;

  PedidoDraft({
    required this.itens,
    required this.subtotalItens,
    this.cliente,
    this.tipoEntrega = TipoEntrega.retirada,
    this.endereco,
    this.taxaEntrega = 0.0,
    this.formaPagamento = FormaPagamentoDraft.pendente,
    this.observacoes = '',
  });

  double get total => subtotalItens + taxaEntrega;
}

// ============================================================================
// MOCK DATA PARA O DASHBOARD (VÁLIDO PARA A MISSÃO EOS-004.1)
// ============================================================================

final List<OfertaQuentinha> mockCardapioHoje = [
  OfertaQuentinha(
    id: 'Q01',
    nome: 'Frango Assado com Batatas',
    descricao: 'Acompanha arroz, feijão, farofa e salada mista.',
    tamanhos: [
      TamanhoOpcao(tamanho: TamanhoQuentinha.P, preco: 15.00),
      TamanhoOpcao(tamanho: TamanhoQuentinha.M, preco: 18.00),
      TamanhoOpcao(tamanho: TamanhoQuentinha.G, preco: 22.00),
    ],
  ),
  OfertaQuentinha(
    id: 'Q02',
    nome: 'Bife Acebolado',
    descricao: 'Acompanha arroz, feijão tropeiro e fritas.',
    tamanhos: [
      TamanhoOpcao(tamanho: TamanhoQuentinha.P, preco: 17.00),
      TamanhoOpcao(tamanho: TamanhoQuentinha.M, preco: 20.00),
      TamanhoOpcao(tamanho: TamanhoQuentinha.G, preco: 25.00),
    ],
  ),
  OfertaQuentinha(
    id: 'Q03',
    nome: 'Feijoada Completa',
    descricao: 'Acompanha arroz, couve refogada, farofa e torresmo.',
    tamanhos: [
      TamanhoOpcao(tamanho: TamanhoQuentinha.P, preco: 20.00, disponivel: false), // P esgotado
      TamanhoOpcao(tamanho: TamanhoQuentinha.M, preco: 25.00),
      TamanhoOpcao(tamanho: TamanhoQuentinha.G, preco: 30.00),
    ],
  ),
  OfertaQuentinha(
    id: 'Q04',
    nome: 'Frango à Parmegiana',
    descricao: 'Acompanha arroz e purê de batata.',
    tamanhos: [
      TamanhoOpcao(tamanho: TamanhoQuentinha.P, preco: 18.00, disponivel: false), // Esgotado
      TamanhoOpcao(tamanho: TamanhoQuentinha.M, preco: 22.00, disponivel: false), // Esgotado
      TamanhoOpcao(tamanho: TamanhoQuentinha.G, preco: 28.00, disponivel: false), // Esgotado
    ],
  ),
];
