import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_controle/models/models_quentinha.dart';
import 'package:lanchonete_controle/utils/whatsapp_message_builder.dart';

void main() {
  group('Domínio: PedidoDraft e Invariantes (EOS-004.4)', () {
    late OfertaQuentinha frangoOferta;
    late TamanhoOpcao tamanhoP;
    late TamanhoOpcao tamanhoM;
    late ClienteContato clienteNormal;

    setUp(() {
      tamanhoP = TamanhoOpcao(tamanho: TamanhoQuentinha.P, preco: 15.0);
      tamanhoM = TamanhoOpcao(tamanho: TamanhoQuentinha.M, preco: 18.0);
      frangoOferta = OfertaQuentinha(
        id: '1',
        nome: 'Frango Assado',
        descricao: 'Com batatas',
        tamanhos: [tamanhoP, tamanhoM],
      );
      clienteNormal = ClienteContato(nome: 'Maria', telefoneWhatsApp: '11999999999');
    });

    test('Draft válido de Retirada passa nas validações', () {
      final draft = PedidoDraft(
        cliente: clienteNormal,
        tipoEntrega: TipoEntrega.retirada,
        itens: [
          ItemCarrinhoQuentinha(idItem: 'i1', oferta: frangoOferta, tamanhoEscolhido: tamanhoM, quantidade: 2)
        ],
        subtotalItens: 36.0,
      );
      expect(draft.total, 36.0);
      expect(draft.itens.first.tamanhoEscolhido.tamanho.sigla, 'M');
    });

    test('Draft inválido: Cliente sem nome ou telefone lança exceção', () {
      expect(
        () => PedidoDraft(
          cliente: ClienteContato(nome: '', telefoneWhatsApp: '123'),
          itens: [ItemCarrinhoQuentinha(idItem: 'i1', oferta: frangoOferta, tamanhoEscolhido: tamanhoM, quantidade: 1)],
          subtotalItens: 18.0,
        ),
        throwsException,
      );
    });

    test('Draft inválido: Sem itens lança exceção', () {
      expect(
        () => PedidoDraft(cliente: clienteNormal, itens: [], subtotalItens: 0.0),
        throwsException,
      );
    });

    test('Draft inválido: Item com quantidade zero ou negativa lança exceção', () {
      expect(
        () => PedidoDraft(
          cliente: clienteNormal,
          itens: [ItemCarrinhoQuentinha(idItem: 'i1', oferta: frangoOferta, tamanhoEscolhido: tamanhoM, quantidade: 0)],
          subtotalItens: 18.0,
        ),
        throwsException,
      );
    });

    test('Draft inválido: Subtotal informado não bate com itens lança exceção', () {
      expect(
        () => PedidoDraft(
          cliente: clienteNormal,
          itens: [ItemCarrinhoQuentinha(idItem: 'i1', oferta: frangoOferta, tamanhoEscolhido: tamanhoM, quantidade: 1)], // 18.0
          subtotalItens: 20.0, // Errado
        ),
        throwsException,
      );
    });

    test('Draft inválido: Retirada com taxa de entrega lança exceção', () {
      expect(
        () => PedidoDraft(
          cliente: clienteNormal,
          tipoEntrega: TipoEntrega.retirada,
          taxaEntrega: 5.0, // Errado
          itens: [ItemCarrinhoQuentinha(idItem: 'i1', oferta: frangoOferta, tamanhoEscolhido: tamanhoM, quantidade: 1)],
          subtotalItens: 18.0,
        ),
        throwsException,
      );
    });

    test('Draft inválido: Entrega sem endereço lança exceção', () {
      expect(
        () => PedidoDraft(
          cliente: clienteNormal,
          tipoEntrega: TipoEntrega.entrega,
          endereco: null, // Errado
          itens: [ItemCarrinhoQuentinha(idItem: 'i1', oferta: frangoOferta, tamanhoEscolhido: tamanhoM, quantidade: 1)],
          subtotalItens: 18.0,
        ),
        throwsException,
      );
    });

    test('WhatsAppMessageBuilder com sigla canônica (P/M/G)', () {
      final draft = PedidoDraft(
        cliente: clienteNormal,
        tipoEntrega: TipoEntrega.retirada,
        itens: [
          ItemCarrinhoQuentinha(idItem: 'i1', oferta: frangoOferta, tamanhoEscolhido: tamanhoP, quantidade: 1),
          ItemCarrinhoQuentinha(idItem: 'i2', oferta: frangoOferta, tamanhoEscolhido: tamanhoM, quantidade: 3),
        ],
        subtotalItens: 69.0, // 15 + 18*3
      );

      final msg = WhatsAppMessageBuilder.buildCliente(draft);
      expect(msg.contains('1x Frango Assado (P)'), isTrue);
      expect(msg.contains('3x Frango Assado (M)'), isTrue);
    });

    test('Invariantes de Troco em Pagamento com Dinheiro', () {
      // Válido: Total 36, paga 50
      final draftValido = PedidoDraft(
        cliente: clienteNormal,
        itens: [ItemCarrinhoQuentinha(idItem: 'i1', oferta: frangoOferta, tamanhoEscolhido: tamanhoM, quantidade: 2)],
        subtotalItens: 36.0,
        formaPagamento: FormaPagamentoDraft.dinheiro,
        valorRecebido: 50.0,
      );
      expect(draftValido.valorTroco, 14.0);

      // Válido: Total 36, paga 36
      final draftExato = PedidoDraft(
        cliente: clienteNormal,
        itens: [ItemCarrinhoQuentinha(idItem: 'i1', oferta: frangoOferta, tamanhoEscolhido: tamanhoM, quantidade: 2)],
        subtotalItens: 36.0,
        formaPagamento: FormaPagamentoDraft.dinheiro,
        valorRecebido: 36.0,
      );
      expect(draftExato.valorTroco, 0.0);

      // Inválido: Total 36, paga 30
      expect(
        () => PedidoDraft(
          cliente: clienteNormal,
          itens: [ItemCarrinhoQuentinha(idItem: 'i1', oferta: frangoOferta, tamanhoEscolhido: tamanhoM, quantidade: 2)],
          subtotalItens: 36.0,
          formaPagamento: FormaPagamentoDraft.dinheiro,
          valorRecebido: 30.0,
        ),
        throwsException,
      );
    });
  });
}
