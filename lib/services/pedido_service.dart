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
      'canalAtendimento': 'BALCAO',
      'taxaEntrega': draft.taxaEntrega,
      'tipoEntrega': draft.tipoEntrega == TipoEntrega.entrega ? 'ENTREGA' : 'RETIRADA',
      'enderecoEntrega': draft.endereco != null ? '${draft.endereco!.logradouro}, ${draft.endereco!.numero} - ${draft.endereco!.bairro}' : '',
      'total': draft.total,
      'observacao': draft.observacoes,
      'itens': draft.itens.map((item) {
        return {
          'ofertaId': item.tamanhoEscolhido.ofertaId,
          'quantidade': item.quantidade,
          'precoUnitario': item.tamanhoEscolhido.preco,
          'tamanho': item.tamanhoEscolhido.tamanho.sigla,
        };
      }).toList(),
      'pagamento': {
        'metodo': draft.formaPagamento.name.toUpperCase(),
        'valorRecebido': draft.valorRecebido ?? draft.total,
      }
    };

    try {
      final response = await _api.post('/api/pedidos', body: payload);
      if (response != null && response is Map) {
        return response['pedidoId'] ?? response['id'] ?? '';
      }
      return '';
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
