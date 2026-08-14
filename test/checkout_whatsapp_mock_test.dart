import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_controle/models/models_quentinha.dart';
import 'package:lanchonete_controle/services/whatsapp_service.dart';
import 'package:lanchonete_controle/utils/whatsapp_message_builder.dart';

class FakeWhatsAppService implements WhatsAppService {
  bool foiAcionado = false;
  List<String> telefonesEnviados = [];
  List<String> mensagensEnviadas = [];

  @override
  Future<void> enviarMensagem({required String telefone, required String mensagem}) async {
    foiAcionado = true;
    telefonesEnviados.add(telefone);
    mensagensEnviadas.add(mensagem);
  }
}

void main() {
  group('Fluxo WhatsApp Mock (EOS-004.7.2)', () {
    late FakeWhatsAppService fakeService;
    late OfertaQuentinha bifeOferta;
    late ClienteContato clienteValido;

    setUp(() {
      fakeService = FakeWhatsAppService();
      bifeOferta = OfertaQuentinha(
        id: 'bife1',
        nome: 'Bife Acebolado',
        descricao: 'Acompanha fritas',
        tamanhos: [
          TamanhoOpcao(tamanho: TamanhoQuentinha.P, preco: 18.0),
          TamanhoOpcao(tamanho: TamanhoQuentinha.G, preco: 25.0),
        ],
      );
      // O clienteContato agora usa o WhatsAppPhoneNormalizer internamente no construtor
      clienteValido = ClienteContato(nome: 'André', telefoneWhatsApp: '(21) 99999-9999');
    });

    test('Draft Válido (Retirada, Dinheiro com Troco) gera dois disparos distintos', () async {
      final draft = PedidoDraft(
        itens: [
          ItemCarrinhoQuentinha(idItem: 'i1', oferta: bifeOferta, tamanhoEscolhido: bifeOferta.tamanhos[0], quantidade: 1), // 1x P
        ],
        subtotalItens: 18.0,
        cliente: clienteValido,
        tipoEntrega: TipoEntrega.retirada,
        formaPagamento: FormaPagamentoDraft.dinheiro,
        valorRecebido: 50.0,
        observacoes: 'Sem cebola',
      );

      final msgOperacional = WhatsAppMessageBuilder.buildOperacional(draft);
      final msgCliente = WhatsAppMessageBuilder.buildCliente(draft);
      
      const whatsappCozinhaMock = '5511999999999';

      await fakeService.enviarMensagem(telefone: whatsappCozinhaMock, mensagem: msgOperacional);
      await fakeService.enviarMensagem(telefone: draft.cliente!.telefoneWhatsApp, mensagem: msgCliente);

      expect(fakeService.foiAcionado, isTrue);
      expect(fakeService.mensagensEnviadas.length, 2);

      // Verificações na mensagem Operacional (Fábrica)
      final op = fakeService.mensagensEnviadas[0];
      expect(op.contains('NOVO PEDIDO'), isTrue);
      expect(op.contains('RETIRADA NO BALCÃO'), isTrue);
      expect(op.contains('Sem cebola'), isTrue);
      expect(op.contains('Troco'), isFalse); // Fábrica não precisa saber de troco explicitamente agora (ou poderia, mas vamos testar que é diferente do cliente)
      
      // Verificações na mensagem do Cliente (Recibo)
      final cl = fakeService.mensagensEnviadas[1];
      expect(cl.contains('Olá, André!'), isTrue);
      expect(cl.contains('*Total: R\$ 18,00*'), isTrue);
      expect(cl.contains('*Troco para:* R\$ 50,00'), isTrue);
      expect(cl.contains('*Troco previsto:* R\$ 32,00'), isTrue);
      expect(fakeService.telefonesEnviados[1], '5521999999999'); // Telefone foi normalizado!
    });

    test('Draft Válido (Entrega) calcula taxa e exige endereço', () async {
      final draft = PedidoDraft(
        itens: [
          ItemCarrinhoQuentinha(idItem: 'i2', oferta: bifeOferta, tamanhoEscolhido: bifeOferta.tamanhos[1], quantidade: 2), // 2x G
        ],
        subtotalItens: 50.0,
        cliente: clienteValido,
        tipoEntrega: TipoEntrega.entrega,
        endereco: EnderecoEntrega(
          cep: '20000-000',
          logradouro: 'Avenida Rio Branco',
          numero: '123',
          bairro: 'Centro',
          cidade: 'Rio de Janeiro',
          uf: 'RJ',
        ),
        taxaEntrega: 5.0,
        formaPagamento: FormaPagamentoDraft.pix,
      );

      final msgCliente = WhatsAppMessageBuilder.buildCliente(draft);
      await fakeService.enviarMensagem(telefone: draft.cliente!.telefoneWhatsApp, mensagem: msgCliente);

      expect(fakeService.foiAcionado, isTrue);
      expect(fakeService.mensagensEnviadas.last.contains('*Entrega:* R\$ 5,00'), isTrue);
      expect(fakeService.mensagensEnviadas.last.contains('*Total: R\$ 55,00*'), isTrue); // 50 + 5
      expect(fakeService.mensagensEnviadas.last.contains('PIX'), isTrue);
      
      final msgOp = WhatsAppMessageBuilder.buildOperacional(draft);
      expect(msgOp.contains('Avenida Rio Branco'), isTrue);
      expect(msgOp.contains('123'), isTrue);
    });
  });
}
