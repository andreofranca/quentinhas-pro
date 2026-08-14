import '../models/models_quentinha.dart';

/// Construtor de mensagens de WhatsApp baseado no PedidoDraft.
/// Separa a lógica de formatação de texto do modelo de domínio e da interface gráfica.
class WhatsAppMessageBuilder {
  /// Retorna os itens resumidos (ex: "1x Frango Assado (M) - R$ 18,00")
  static String resumirItens(PedidoDraft pedido) {
    if (pedido.itens.isEmpty) return 'Nenhum item';
    return pedido.itens.map((item) {
      final sub = item.subtotal.toStringAsFixed(2).replaceAll('.', ',');
      return '${item.quantidade}x ${item.oferta.nome} (${item.tamanhoEscolhido.tamanho.sigla}) - R\$ $sub';
    }).join('\n');
  }

  /// Monta o endereço formatado a partir de um EnderecoEntrega.
  static String formatarEndereco(EnderecoEntrega endereco) {
    var linhas = [
      'Rua ${endereco.logradouro}, Nº ${endereco.numero}',
      if (endereco.complemento.isNotEmpty) 'Complemento: ${endereco.complemento}',
      'Bairro: ${endereco.bairro}',
      'CEP: ${endereco.cep}',
      if (endereco.referencia.isNotEmpty) 'Ref: ${endereco.referencia}'
    ];
    return linhas.join('\n');
  }

  /// Constrói o "Ticket Operacional" (para a Cozinha/Fábrica)
  static String buildOperacional(PedidoDraft pedido, {String numeroPedido = 'RASCUNHO'}) {
    final clienteNome = pedido.cliente?.nome ?? 'Cliente';
    final telefone = pedido.cliente?.telefoneWhatsApp ?? 'Não informado';
    
    var msg = '🍳 *NOVO PEDIDO: $numeroPedido*\n\n';
    msg += '*Cliente:* $clienteNome\n';
    msg += '*Contato:* $telefone\n\n';
    
    msg += '*ITENS:*\n';
    msg += '${resumirItens(pedido)}\n\n';
    
    if (pedido.tipoEntrega == TipoEntrega.entrega) {
      msg += '🛵 *ENTREGA*\n';
      if (pedido.endereco != null) {
        msg += '${formatarEndereco(pedido.endereco!)}\n\n';
      }
    } else {
      msg += '🏪 *RETIRADA NO BALCÃO*\n\n';
    }
    
    if (pedido.observacoes.isNotEmpty) {
      msg += '*OBSERVAÇÕES:*\n${pedido.observacoes}\n\n';
    }

    return msg.trim();
  }

  /// Constrói o "Recibo" (para o Cliente)
  static String buildCliente(PedidoDraft pedido, {String numeroPedido = 'RASCUNHO'}) {
    final clienteNome = pedido.cliente?.nome ?? 'Cliente';
    
    var msg = 'Olá, $clienteNome!\n\n';
    msg += 'Seu pedido *$numeroPedido* foi registrado com sucesso na Quentinhas Pro.\n\n';
    
    msg += '*Resumo do pedido:*\n';
    msg += '${resumirItens(pedido)}\n\n';
    
    msg += '*Subtotal:* R\$ ${pedido.subtotalItens.toStringAsFixed(2).replaceAll('.', ',')}\n';
    if (pedido.tipoEntrega == TipoEntrega.entrega) {
      msg += '*Entrega:* R\$ ${pedido.taxaEntrega.toStringAsFixed(2).replaceAll('.', ',')}\n';
    }
    msg += '*Total: R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}*\n\n';
    
    msg += '*Pagamento:* ${_formatarFormaPagamento(pedido.formaPagamento)}\n';
    
    if (pedido.formaPagamento == FormaPagamentoDraft.dinheiro && pedido.valorRecebido != null) {
      msg += '*Troco para:* R\$ ${pedido.valorRecebido!.toStringAsFixed(2).replaceAll('.', ',')}\n';
      msg += '*Troco previsto:* R\$ ${pedido.valorTroco.toStringAsFixed(2).replaceAll('.', ',')}\n';
    }

    msg += '\nEstamos preparando seu pedido. Em breve enviaremos nova atualização!';
    return msg.trim();
  }

  static String _formatarFormaPagamento(FormaPagamentoDraft fp) {
    switch (fp) {
      case FormaPagamentoDraft.pix: return 'PIX';
      case FormaPagamentoDraft.dinheiro: return 'Dinheiro';
      case FormaPagamentoDraft.cartao: return 'Cartão (Débito/Crédito)';
      case FormaPagamentoDraft.pendente: return 'A Combinar';
    }
  }
}
