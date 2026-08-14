// Modelos focados no fluxo da Quentinha
import '../utils/whatsapp_phone_normalizer.dart';

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
  int? quantidadeDisponivel; // null indica infinito no mock

  TamanhoOpcao({
    required this.tamanho,
    required this.preco,
    this.quantidadeDisponivel,
  });

  bool get disponivel => quantidadeDisponivel == null || quantidadeDisponivel! > 0;

  void consumir(int quantidade) {
    if (quantidadeDisponivel == null) return; // Estoque infinito mockado
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
      'caixa_id': caixaId,
      'cliente': cliente != null ? {
        'nome': cliente!.nome,
        'telefone': cliente!.telefoneWhatsApp,
      } : null,
      'modalidade': tipoEntrega == TipoEntrega.entrega ? 'ENTREGA' : 'RETIRADA',
      'taxa_entrega': taxaEntrega,
      'endereco_entrega': enderecoString.isNotEmpty ? enderecoString : null,
      'observacoes': observacoes,
      'total': total,
      'itens': itens.map((item) => {
        'oferta_id': item.oferta.id, 
        'quantidade': item.quantidade,
        'preco_unitario': item.tamanhoEscolhido.preco,
        'subtotal': item.subtotal,
      }).toList(),
      'pagamento': formaPagamento != FormaPagamentoDraft.pendente ? {
        'forma_pagamento': formaPagamento.name.toUpperCase(),
        'valor': total,
        'valor_recebido': valorRecebido ?? total,
        'troco': valorTroco,
      } : null,
      'provedor_evento': provedorEvento,
      'external_event_id': externalEventId,
    };
  }
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
      TamanhoOpcao(tamanho: TamanhoQuentinha.P, preco: 20.00, quantidadeDisponivel: 0), // P esgotado
      TamanhoOpcao(tamanho: TamanhoQuentinha.M, preco: 25.00),
      TamanhoOpcao(tamanho: TamanhoQuentinha.G, preco: 30.00, quantidadeDisponivel: 1), // Apenas 1 G restante!
    ],
  ),
  OfertaQuentinha(
    id: '4',
    nome: 'Salada Fit Completa',
    descricao: 'Mix de folhas, frango desfiado, batata doce, tomate e molho de iogurte.',
    tamanhos: [
      TamanhoOpcao(tamanho: TamanhoQuentinha.P, preco: 18.00, quantidadeDisponivel: 0), // Esgotado
      TamanhoOpcao(tamanho: TamanhoQuentinha.M, preco: 22.00, quantidadeDisponivel: 0), // Esgotado
      TamanhoOpcao(tamanho: TamanhoQuentinha.G, preco: 28.00, quantidadeDisponivel: 0), // Esgotado
    ],
  ),
];
