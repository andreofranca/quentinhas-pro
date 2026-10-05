import '../utils/whatsapp_phone_normalizer.dart';
class AdicionalQuentinha {
  final String id;
  final String nome;
  final double preco;

  AdicionalQuentinha({required this.id, required this.nome, required this.preco});
}

class CatalogoCompleto {
  final List<OfertaQuentinha> ofertas;
  final List<AdicionalQuentinha> adicionais;
  
  CatalogoCompleto({required this.ofertas, required this.adicionais});
}
// Modelos focados no fluxo da Quentinha


enum TamanhoQuentinha { P, M, G, U }

extension TamanhoQuentinhaExtension on TamanhoQuentinha {
  String get nome {
    switch (this) {
      case TamanhoQuentinha.P:
        return 'Pequena';
      case TamanhoQuentinha.M:
        return 'Média';
      case TamanhoQuentinha.G:
        return 'Grande';
        case TamanhoQuentinha.U:
          return 'Única';
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
        case TamanhoQuentinha.U:
          return 'U';
      }
  }
}

class TamanhoOpcao {
  final TamanhoQuentinha tamanho;
  final double preco;
  int? quantidadeDisponivel;
  final String? ofertaId; // Adicionado para integração com backend

  TamanhoOpcao({
    required this.tamanho,
    required this.preco,
    this.quantidadeDisponivel,
    this.ofertaId,
  });

  bool get disponivel => quantidadeDisponivel == null || quantidadeDisponivel! > 0;

  void consumir(int quantidade) {
    if (quantidadeDisponivel == null) return;
    if (quantidade <= 0) throw Exception('Domínio: Quantidade deve ser positiva.');
    if (quantidadeDisponivel! < quantidade) {
      throw Exception('Domínio: Estoque insuficiente para o tamanho ${tamanho.sigla}.');
    }
    quantidadeDisponivel = quantidadeDisponivel! - quantidade;
  }
}

class OfertaQuentinha {
  final String id;
  final String nome;
  final String descricao;
  final String categoria;
  final int estoqueAtual;
  final List<TamanhoOpcao> tamanhos;
  final String? imagemUrl;

  OfertaQuentinha({
    required this.id,
    required this.nome,
    required this.descricao,
    this.categoria = 'MARMITA',
    this.estoqueAtual = 0,
    required this.tamanhos,
    this.imagemUrl,
  });
}

class ItemCarrinhoQuentinha {
  final String idItem;
  final OfertaQuentinha oferta;
  final TamanhoOpcao tamanhoEscolhido;
  int quantidade;
  final List<AdicionalQuentinha> adicionais;

  ItemCarrinhoQuentinha({
    required this.idItem,
    required this.oferta,
    required this.tamanhoEscolhido,
    this.quantidade = 1,
    this.adicionais = const [],
  });

  double get subtotal => (tamanhoEscolhido.preco + adicionais.fold(0.0, (sum, a) => sum + a.preco)) * quantidade;
}

// ---------------------------------------------------------------------------
// NOVOS MODELOS: DOMÍNIO DE CHECKOUT E DRAFT (EOS-004.2.2)
// ---------------------------------------------------------------------------

class ClienteContato {
  final String nome;
  final String telefoneWhatsApp;

  ClienteContato({required this.nome, required String telefoneWhatsApp})
      : telefoneWhatsApp = WhatsAppPhoneNormalizer.normalizar(telefoneWhatsApp);
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
  final double? valorRecebido;
  final String observacoes;

  PedidoDraft({
    required this.itens,
    required this.subtotalItens,
    this.cliente,
    this.tipoEntrega = TipoEntrega.retirada,
    this.endereco,
    this.taxaEntrega = 0.0,
    this.formaPagamento = FormaPagamentoDraft.pendente,
    this.valorRecebido,
    this.observacoes = '',
  }) {
    validar();
  }

  void validar() {
    if (cliente == null || cliente!.nome.trim().isEmpty || cliente!.telefoneWhatsApp.trim().isEmpty) {
      throw Exception('Domínio: Cliente e telefone são obrigatórios.');
    }
    if (itens.isEmpty) {
      throw Exception('Domínio: O pedido deve conter pelo menos um item.');
    }
    if (subtotalItens < 0) {
      throw Exception('Domínio: Subtotal não pode ser negativo.');
    }

    double calculoSubtotal = 0.0;
    for (var item in itens) {
      if (item.quantidade <= 0) throw Exception('Domínio: Quantidade do item deve ser maior que zero.');
      if (item.tamanhoEscolhido.preco < 0) throw Exception('Domínio: Preço do tamanho deve ser positivo.');
      if (!item.tamanhoEscolhido.disponivel) throw Exception('Domínio: O tamanho ${item.tamanhoEscolhido.tamanho.sigla} da oferta ${item.oferta.nome} está esgotado.');
      if (item.tamanhoEscolhido.quantidadeDisponivel != null && item.tamanhoEscolhido.quantidadeDisponivel! < item.quantidade) {
        throw Exception('Domínio: Estoque insuficiente para o tamanho ${item.tamanhoEscolhido.tamanho.sigla} da oferta ${item.oferta.nome}.');
      }
      calculoSubtotal += item.subtotal;
    }

    if ((calculoSubtotal - subtotalItens).abs() > 0.01) {
      throw Exception('Domínio: O subtotal informado não confere com a soma dos itens.');
    }

    if (tipoEntrega == TipoEntrega.entrega) {
      if (endereco == null) {
        throw Exception('Domínio: Endereço é obrigatório para pedidos de entrega.');
      }
    } else {
      if (taxaEntrega > 0) {
        throw Exception('Domínio: Pedidos de retirada não podem ter taxa de entrega.');
      }
    }
    
    if (formaPagamento == FormaPagamentoDraft.dinheiro) {
      if (valorRecebido != null && valorRecebido! < total) {
        throw Exception('Domínio: O valor recebido para pagamento em dinheiro deve ser maior ou igual ao total.');
      }
    }
  }

  double get total => subtotalItens + taxaEntrega;
  
  double get valorTroco {
    if (formaPagamento != FormaPagamentoDraft.dinheiro || valorRecebido == null) return 0.0;
    final troco = valorRecebido! - total;
    return troco > 0 ? troco : 0.0;
  }

  Map<String, dynamic> toRpcPayload({
    required String caixaId,
    required String provedorEvento,
    String? externalEventId,
  }) {
    String enderecoString = '';
    if (endereco != null) {
      enderecoString = '${endereco!.logradouro}, ${endereco!.numero}';
      if (endereco!.complemento.isNotEmpty) enderecoString += ' - ${endereco!.complemento}';
      enderecoString += ', ${endereco!.bairro}, ${endereco!.cidade}/${endereco!.uf} - CEP: ${endereco!.cep}';
    }

    return {
      'caixaId': caixaId,
      'cliente': cliente != null ? {
        'nome': cliente!.nome,
        'telefone': cliente!.telefoneWhatsApp,
      } : null,
      'modalidade': tipoEntrega == TipoEntrega.entrega ? 'ENTREGA' : 'RETIRADA',
      'taxaEntrega': taxaEntrega,
      'enderecoEntrega': enderecoString.isNotEmpty ? enderecoString : null,
      'observacoes': observacoes,
      'total': total,
      'itens': itens.map((item) => {
        'variacaoId': item.tamanhoEscolhido.ofertaId,
          'adicionaisIds': item.adicionais.map((a) => a.id).toList(), 
        'quantidade': item.quantidade,
        'precoUnitario': item.tamanhoEscolhido.preco,
        'subtotal': item.subtotal,
      }).toList(),
      'pagamento': formaPagamento != FormaPagamentoDraft.pendente ? {
        'formaPagamento': formaPagamento.name.toUpperCase(),
        'valor': total,
        'valorRecebido': valorRecebido ?? total,
        'troco': valorTroco,
      } : null,
      'provedorEvento': provedorEvento,
      'externalEventId': externalEventId,
    };
  }
}










