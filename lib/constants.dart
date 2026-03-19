import 'package:flutter/material.dart';

// ============================================================================
// CORES DO TEMA
// ============================================================================
const Color corPrimaria = Colors.deepOrange;
const Color corSidebar = Color(0xFF1E1E2C);
const Color corFundoEsmaecido = Color(0xFFF4F5F7);

// ============================================================================
// DADOS DE CONTATO
// ============================================================================
const String whatsappLanchonete = "5521999999999";
const String whatsappPais = "55";
const String whatsappRegiao = "21";

// ============================================================================
// VALORES FIXOS DE NEGÓCIO
// ============================================================================
const double taxaEntregaFixa = 7.00;
const int estoqueDefault = 50;
const int quantidadeMaximaCarrinho = 99;
const Duration tempoSnackbar = Duration(seconds: 2);

// ============================================================================
// STRINGS GENÉRICAS (UI)
// ============================================================================
const String labelTotal = "TOTAL:";
const String labelSubtotal = "SUBTOTAL:";
const String labelTaxaEntrega = "Taxa de Entrega:";
const String labelItensDoCarrinho = "ITENS DO CARRINHO:";
const String labelItensDopedido = "ITENS DO PEDIDO:";
const String labelFormaPagamento = "Forma de Pagamento";
const String labelPagamento = "Pagamento:";
const String labelStatus = "Status:";
const String labelData = "Data:";

// ============================================================================
// DINHEIRO - FORMATAÇÃO
// ============================================================================
const String simboloMoeda = "R\$";
const String separadorDecimal = ",";
const String separadorMilhar = ".";

// ============================================================================
// VALIDAÇÃO
// ============================================================================
const int tamanhoMinimoCep = 8;
const int tamanhoMinimoTelefone = 14;
const int tamanhoMinimoSenha = 3;

// ============================================================================
// OPÇÕES DE NEGÓCIO
// ============================================================================
const List<String> categoriasMenu = ['Lanches', 'Porções', 'Bebidas', 'Sobremesas'];
const List<String> formasPagamento = ['PIX', 'CRÉDITO', 'DÉBITO', 'DINHEIRO'];
const List<String> statusPedidos = ['NOVO', 'PREPARANDO', 'DESPACHADO', 'ENTREGUE', 'CANCELADO'];
const List<String> tiposEntrega = ['ENTREGA', 'RETIRADA'];
const List<String> cargosUsuario = ['FUNCIONARIO', 'ADMIN'];

// ============================================================================
// ENDPOINTS / APIS
// ============================================================================
const String viaCepBaseUrl = 'https://viacep.com.br/ws';

// ============================================================================
// MENSAGENS DE ERRO
// ============================================================================
const String msgCampoObrigatorio = "Obrigatório";
const String msgTelefoneInvalido = "Telefone inválido";
const String msgEstoqueEsgotado = "Estoque esgotado!";
const String msgEstoqueMaximo = "Estoque máximo atingido!";
const String msgValorTrocoInvalido = "O valor para troco deve ser maior que o total!";
const String msgErroAutenticacao = "Acesso Negado. Verifique usuário e senha.";
const String msgContaBloqueada = "Acesso Bloqueado. Conta inativada.";
const String msgLoginDuplicado = "Este Login já existe!";
const String msgPedidoVazio = "Adicione itens ao carrinho antes de finalizar.";
const String msgPedidoCancelado = "Pedido cancelado com sucesso.";
const String msgProdutoAdicionado = "adicionado!";

// ============================================================================
// MENSAGENS DE SUCESSO
// ============================================================================
const String msgEnviandoImpressora = "Enviando comando para a impressora térmica...";
const String msgErroWhatsapp = "WhatsApp bloqueado";
const String msgErroApiBuscaCep = "Erro ao buscar CEP. Tente novamente.";
const String msgCepNaoEncontrado = "CEP não encontrado.";
