import 'package:flutter/material.dart';

import '../constants.dart';

class Produto {
  final String idProduto;
  String nome, descricao, categoria, imagemUrl;
  double preco;
  int estoqueAtual;
  int estoqueMinimo; // Nível mínimo de alerta: abaixo disso = Crítico
  bool ativo;

  Produto({
    required this.idProduto,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.categoria,
    required this.imagemUrl,
    this.estoqueAtual = estoqueDefault,
    this.estoqueMinimo = 8,
    this.ativo = true,
  });

  factory Produto.fromJsonFull(Map<String, dynamic> json) {
    return Produto(
      idProduto: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      categoria: json['categoria'] ?? '',
      imagemUrl: '',
      preco: (json['precoBase'] ?? 0).toDouble(),
      estoqueAtual: json['estoqueAtual'] ?? estoqueDefault,
      estoqueMinimo: json['estoqueMinimo'] ?? 8,
      ativo: json['ativo'] ?? true,
    );
  }
}

class ItemCarrinho {
  final Produto produto;
  int quantidade;
  ItemCarrinho({required this.produto, this.quantidade = 1});
}

class ResultadoNotificacaoWhatsApp {
  final bool enviadoFabrica;
  final bool enviadoCliente;

  const ResultadoNotificacaoWhatsApp({
    required this.enviadoFabrica,
    required this.enviadoCliente,
  });

  bool get ambosEnviados => enviadoFabrica && enviadoCliente;
  bool get algumEnviado => enviadoFabrica || enviadoCliente;
}

class Pedido {
  final String numeroPedido, nomeCliente, telefoneCliente;
  String statusLogistico;
  String statusPagamento;
  final String tipoEntrega;
  final String? enderecoCompleto;
  final String? observacao;
  final double taxaEntrega;
  final String formaPagamento;
  final double? trocoPara;
  final List<ItemCarrinho> itens;
  final double total;
  final DateTime dataHora;
  bool notificacaoNovoPedidoFabrica;
  bool notificacaoNovoPedidoCliente;
  bool notificacaoDespachoFabrica;
  bool notificacaoDespachoCliente;

  Pedido({
    required this.numeroPedido,
    required this.nomeCliente,
    required this.telefoneCliente,
    required this.tipoEntrega,
    this.enderecoCompleto,
    this.observacao,
    required this.taxaEntrega,
    required this.formaPagamento,
    this.trocoPara,
    required this.itens,
    required this.total,
    required this.dataHora,
    this.statusLogistico = 'NOVO',
    this.statusPagamento = 'AGUARDANDO',
    this.notificacaoNovoPedidoFabrica = false,
    this.notificacaoNovoPedidoCliente = false,
    this.notificacaoDespachoFabrica = false,
    this.notificacaoDespachoCliente = false,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    var itensJson = json['itens'] as List? ?? [];
    List<ItemCarrinho> mappedItens = itensJson.map((i) => ItemCarrinho(
      produto: Produto(
        idProduto: i['oferta_id'] ?? '',
        nome: "${i['nome_produto'] ?? ''} (${i['sigla_tamanho'] ?? ''})",
        descricao: '',
        categoria: 'API',
        imagemUrl: '',
        preco: (i['preco_unitario'] ?? 0).toDouble(),
      ),
      quantidade: i['quantidade'] ?? 1,
    )).toList();

    return Pedido(
      numeroPedido: json['id'] ?? '',
      nomeCliente: json['cliente_nome'] ?? 'Cliente não informado',
      telefoneCliente: json['cliente_telefone'] ?? '',
      tipoEntrega: json['modalidade'] ?? '',
      taxaEntrega: (json['taxa_entrega'] ?? 0).toDouble(),
      formaPagamento: json['forma_pagamento'] ?? '',
      itens: mappedItens,
      total: (json['total'] ?? 0).toDouble(),
      enderecoCompleto: json['endereco_entrega'],
      observacao: json['observacoes'],
      trocoPara: json['troco'] != null ? (json['troco'] as num).toDouble() + (json['total'] ?? 0).toDouble() : null,
      dataHora: json['registrado_em'] != null ? DateTime.parse(json['registrado_em']) : DateTime.now(),
      statusLogistico: json['status_operacional'] ?? 'NOVO',
      statusPagamento: json['status_financeiro'] ?? 'AGUARDANDO',
    );
  }
}

class Usuario {
  final String idUsuario;
  String senha, nomeCompleto, cargo, cpf, telefone, email;
  String cep, logradouro, numero, complemento, bairro, cidade, uf;
  bool situacaoConta;

  Usuario({
    required this.idUsuario,
    required this.senha,
    required this.nomeCompleto,
    required this.cargo,
    this.cpf = "",
    this.telefone = "",
    this.email = "",
    this.cep = "",
    this.logradouro = "",
    this.numero = "",
    this.complemento = "",
    this.bairro = "",
    this.cidade = "",
    this.uf = "",
    this.situacaoConta = true
  });
}
