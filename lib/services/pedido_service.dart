import 'package:lanchonete_controle/services/api_client.dart';
import 'package:lanchonete_controle/models/models_quentinha.dart';

class CaixaService {
  final ApiClient _api = ApiClient.instance;

  Future<String> getCaixaAtivoId() async {
    try {
      final response = await _api.get('/api/caixas/ativo');
      if (response != null && response is Map && response.containsKey('id')) {
        return response['id'];
      }
      throw Exception('Caixa ativo no encontrado no formato esperado.');
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Nenhum caixa aberto encontrado. Por favor, abra um caixa.');
      }
      throw Exception('Erro ao buscar caixa ativo: ${e.message}');
    }
  }

  Future<String> abrirCaixa(double saldoInicial) async {
    try {
      final response = await _api.post('/api/caixas/abrir', body: {
        'saldoInicial': saldoInicial
      });
      if (response != null && response is Map && response.containsKey('id')) {
        return response['id'];
      }
      throw Exception('Falha ao abrir caixa. Resposta inesperada.');
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw Exception('J existia um caixa aberto. Tente finalizar a venda novamente.');
      }
      throw Exception('Erro ao abrir caixa: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> fecharCaixa(double saldoInformado) async {
    try {
      final response = await _api.post('/api/caixas/fechar', body: {
        'saldoInformado': saldoInformado
      });
      if (response != null && response is Map) {
        return response as Map<String, dynamic>;
      }
      throw Exception('Falha ao fechar caixa. Resposta inesperada.');
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Nenhum caixa aberto para fechar.');
      }
      throw Exception('Erro ao fechar caixa: ${e.message}');
    }
  }
}

class PedidoService {
  final ApiClient _api = ApiClient.instance;

  Future<String> criarPedido(PedidoDraft draft, String caixaId) async {
    final Map<String, dynamic> payload = {
      'caixaId': caixaId,
      'cliente': {
        'nome': draft.cliente!.nome,
        'telefone': draft.cliente!.telefoneWhatsApp,
      },
      'modalidade': draft.tipoEntrega == TipoEntrega.entrega ? 'ENTREGA' : 'RETIRADA',
      'taxaEntrega': draft.taxaEntrega,
      'enderecoEntrega': draft.endereco != null ? '${draft.endereco!.logradouro}, ${draft.endereco!.numero} - ${draft.endereco!.bairro}' : '',
      'observacoes': draft.observacoes,
      'total': draft.total,
      'itens': draft.itens.map((item) {
        return {
          'variacaoId': item.tamanhoEscolhido.ofertaId,
          'quantidade': item.quantidade,
          'adicionaisIds': item.adicionais.map((a) => a.id).toList(),
          'precoUnitario': item.tamanhoEscolhido.preco,
          'subtotal': (item.quantidade * item.tamanhoEscolhido.preco),
        };
      }).toList(),
      'pagamento': {
        'formaPagamento': draft.formaPagamento.name.toUpperCase(),
        'valor': draft.total,
        'valorRecebido': draft.valorRecebido ?? draft.total,
        'troco': ((draft.valorRecebido ?? draft.total) - draft.total) > 0 ? ((draft.valorRecebido ?? draft.total) - draft.total) : 0.0,
      },
      'provedorEvento': 'APP',
      'externalEventId': 'evt-${DateTime.now().millisecondsSinceEpoch}'
    };

    try {
      final response = await _api.post('/api/pedidos', body: payload);
      if (response != null && response is Map) {
        return response['numeroComercial'] ?? response['pedidoId'] ?? response['id'] ?? '';
      }
      return '';
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

