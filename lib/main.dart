import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const Color corPrimaria = Colors.deepOrange;
const Color corSidebar = Color(0xFF1E1E2C);
const Color corFundoEsmaecido = Color(0xFFF4F5F7);

void main() => runApp(const AppLanchonete());

// =============================================================================
// --- MODELO DE DADOS ---
// =============================================================================
class Usuario {
  final String idUsuario;
  String senha, nomeCompleto, cargo, cpf, telefone, email;
  String cep, logradouro, numero, complemento, bairro, cidade, uf;
  bool situacaoConta;

  Usuario({
    required this.idUsuario, required this.senha, required this.nomeCompleto, required this.cargo,
    this.cpf = "", this.telefone = "", this.email = "",
    this.cep = "", this.logradouro = "", this.numero = "", this.complemento = "", this.bairro = "", this.cidade = "", this.uf = "",
    this.situacaoConta = true,
  });

  Usuario copiarCom({
    String? nome, String? pwd, String? cargo, String? cpf, String? tel, String? email,
    String? cep, String? logradouro, String? numero, String? complemento, String? bairro, String? cidade, String? uf, bool? ativo
  }) {
    return Usuario(
      idUsuario: idUsuario,
      senha: pwd ?? senha, nomeCompleto: nome ?? nomeCompleto, cargo: cargo ?? this.cargo,
      cpf: cpf ?? this.cpf, telefone: tel ?? telefone, email: email ?? this.email,
      cep: cep ?? this.cep, logradouro: logradouro ?? this.logradouro, numero: numero ?? this.numero, complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro, cidade: cidade ?? this.cidade, uf: uf ?? this.uf,
      situacaoConta: ativo ?? situacaoConta,
    );
  }
}

List<Usuario> listaUsuarios = [
  Usuario(idUsuario: "ANDRE", senha: "123", nomeCompleto: "André Administrador", cargo: "ADMIN", cpf: "104.424.477-10"),
];

class AppLanchonete extends StatelessWidget {
  const AppLanchonete({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ERP Lanchonete',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: corPrimaria,
        scaffoldBackgroundColor: corFundoEsmaecido,
        appBarTheme: const AppBarTheme(backgroundColor: corPrimaria, foregroundColor: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: corPrimaria, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15))),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true, fillColor: Colors.white, 
          border: OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
      home: const TelaLogin(),
    );
  }
}

// =============================================================================
// --- TELA DE LOGIN ---
// =============================================================================
class TelaLogin extends StatefulWidget { const TelaLogin({super.key}); @override State<TelaLogin> createState() => _TelaLoginState(); }
class _TelaLoginState extends State<TelaLogin> {
  final _controleLogin = TextEditingController();
  final _controleSenha = TextEditingController();

  void _tentarLogin() {
    try {
      Usuario user = listaUsuarios.firstWhere((u) => u.idUsuario == _controleLogin.text && u.senha == _controleSenha.text);
      if (!user.situacaoConta) throw Exception("INATIVO");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TelaDashboard(usuarioLogado: user)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Acesso Negado ou Usuário Inativo."), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400), padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fastfood, size: 80, color: corPrimaria), const SizedBox(height: 40),
              TextField(
                controller: _controleLogin, autofocus: true, textInputAction: TextInputAction.next,
                inputFormatters: [UpperCaseTextFormatter()],
                decoration: const InputDecoration(labelText: 'USUÁRIO', hintText: 'Ex: ANDRE', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controleSenha, obscureText: true, onSubmitted: (_) => _tentarLogin(),
                decoration: const InputDecoration(labelText: 'SENHA', hintText: '***', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 30),
              SizedBox(height: 55, child: ElevatedButton(onPressed: _tentarLogin, child: const Text("ENTRAR"))),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// --- DASHBOARD ---
// =============================================================================
class TelaDashboard extends StatefulWidget {
  final Usuario usuarioLogado;
  const TelaDashboard({super.key, required this.usuarioLogado});
  @override State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  int _indiceMenuSelecionado = 0;

  Widget _obterTelaAtual() {
    switch (_indiceMenuSelecionado) {
      case 0: return _PainelResumo(usuario: widget.usuarioLogado);
      case 1: return TelaGestaoUsuarios(usuarioLogado: widget.usuarioLogado);
      default: return const Center(child: Text("Módulo em Construção", style: TextStyle(fontSize: 24, color: Colors.grey)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: corSidebar,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  color: Colors.black26,
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 40, backgroundColor: corPrimaria, child: Icon(Icons.person, size: 40, color: Colors.white)),
                      const SizedBox(height: 10),
                      Text(widget.usuarioLogado.nomeCompleto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      Text(widget.usuarioLogado.cargo, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _ItemMenu(icone: Icons.dashboard, titulo: "Visão Geral", ativo: _indiceMenuSelecionado == 0, onTap: () => setState(() => _indiceMenuSelecionado = 0)),
                      _ItemMenu(icone: Icons.badge, titulo: "Equipe / Acessos", ativo: _indiceMenuSelecionado == 1, onTap: () => setState(() => _indiceMenuSelecionado = 1)),
                      _ItemMenu(icone: Icons.inventory, titulo: "Estoque & Ficha Tec.", ativo: _indiceMenuSelecionado == 2, onTap: () => setState(() => _indiceMenuSelecionado = 2)),
                      _ItemMenu(icone: Icons.groups, titulo: "Clientes", ativo: _indiceMenuSelecionado == 3, onTap: () => setState(() => _indiceMenuSelecionado = 3)),
                      _ItemMenu(icone: Icons.local_shipping, titulo: "Fornecedores", ativo: _indiceMenuSelecionado == 4, onTap: () => setState(() => _indiceMenuSelecionado = 4)),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Sair do Sistema", style: TextStyle(color: Colors.redAccent)),
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TelaLogin())),
                )
              ],
            ),
          ),
          Expanded(child: Container(color: corFundoEsmaecido, child: _obterTelaAtual()))
        ],
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icone; final String titulo; final bool ativo; final VoidCallback onTap;
  const _ItemMenu({required this.icone, required this.titulo, required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: ativo ? corPrimaria : Colors.grey),
      title: Text(titulo, style: TextStyle(color: ativo ? Colors.white : Colors.grey, fontWeight: ativo ? FontWeight.bold : FontWeight.normal)),
      selected: ativo,
      selectedTileColor: Colors.white10,
      onTap: onTap,
    );
  }
}

class _PainelResumo extends StatelessWidget {
  final Usuario usuario;
  const _PainelResumo({required this.usuario});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Central de Operações", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          const SizedBox(height: 20),
          Text("Olá, ${usuario.nomeCompleto}! Acompanhe o movimento e gerencie sua lanchonete por aqui.", style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
        ],
      ),
    );
  }
}

// =============================================================================
// --- TELA DE GESTÃO DA EQUIPE ---
// =============================================================================
class TelaGestaoUsuarios extends StatefulWidget {
  final Usuario usuarioLogado;
  const TelaGestaoUsuarios({super.key, required this.usuarioLogado});
  @override State<TelaGestaoUsuarios> createState() => _TelaGestaoUsuariosState();
}

class _TelaGestaoUsuariosState extends State<TelaGestaoUsuarios> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Gestão de Colaboradores", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaCadastroUsuario())).then((_) => setState((){})), 
                icon: const Icon(Icons.add), label: const Text("NOVO COLABORADOR")
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: listaUsuarios.length,
              itemBuilder: (context, index) {
                final u = listaUsuarios[index];
                return Card(
                  child: ListTile(
                    title: Text(u.nomeCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Cargo: ${u.cargo} | CPF: ${u.cpf}\nCidade: ${u.cidade}/${u.uf}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue), 
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TelaCadastroUsuario(usuarioOriginal: u))).then((_) => setState((){}))
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// --- TELA DE CADASTRO ---
// =============================================================================
class TelaCadastroUsuario extends StatefulWidget {
  final Usuario? usuarioOriginal;
  const TelaCadastroUsuario({super.key, this.usuarioOriginal});
  @override State<TelaCadastroUsuario> createState() => _TelaCadastroUsuarioState();
}

class _TelaCadastroUsuarioState extends State<TelaCadastroUsuario> {
  final _chaveForm = GlobalKey<FormState>();
  
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _cep = TextEditingController();
  final _logradouro = TextEditingController();
  final _numero = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  final _uf = TextEditingController();
  final _complemento = TextEditingController();
  final _login = TextEditingController();
  final _senha = TextEditingController();
  String _cargo = 'FUNCIONARIO';
  bool _buscandoCep = false;

  // OS TRÊS "OUVINTES" (FocusNodes) PARA VALIDAÇÃO EM TEMPO REAL
  final FocusNode _cpfFocus = FocusNode();
  final FocusNode _telefoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  
  // Variáveis para guardar os erros que aparecem na tela
  String? _erroCpfDinamico; 
  String? _erroTelefoneDinamico;
  String? _erroEmailDinamico;

  @override
  void initState() {
    super.initState();
    if (widget.usuarioOriginal != null) {
      final u = widget.usuarioOriginal!;
      _nome.text = u.nomeCompleto; _cpf.text = u.cpf; _telefone.text = u.telefone; _email.text = u.email;
      _cep.text = u.cep; _logradouro.text = u.logradouro; _numero.text = u.numero; _complemento.text = u.complemento; _bairro.text = u.bairro; _cidade.text = u.cidade; _uf.text = u.uf;
      _login.text = u.idUsuario; _senha.text = u.senha; _cargo = u.cargo;
    }

    // LISTENER DO CPF
    _cpfFocus.addListener(() {
      if (_cpfFocus.hasFocus) {
        _cpf.selection = TextSelection(baseOffset: 0, extentOffset: _cpf.text.length);
      } else { 
        setState(() => _erroCpfDinamico = _validarCPFLogica(_cpf.text));
      }
    });

    // LISTENER DO TELEFONE
    _telefoneFocus.addListener(() {
      if (_telefoneFocus.hasFocus) {
        _telefone.selection = TextSelection(baseOffset: 0, extentOffset: _telefone.text.length);
      } else {
        setState(() => _erroTelefoneDinamico = _validarTelefoneLogica(_telefone.text));
      }
    });

    // LISTENER DO E-MAIL
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _email.selection = TextSelection(baseOffset: 0, extentOffset: _email.text.length);
      } else {
        setState(() => _erroEmailDinamico = _validarEmailLogica(_email.text));
      }
    });
  }

  @override
  void dispose() {
    _nome.dispose(); _cpf.dispose(); _telefone.dispose(); _email.dispose();
    _cep.dispose(); _logradouro.dispose(); _numero.dispose(); _complemento.dispose();
    _bairro.dispose(); _cidade.dispose(); _uf.dispose(); _login.dispose(); _senha.dispose();
    _cpfFocus.dispose(); _telefoneFocus.dispose(); _emailFocus.dispose();
    super.dispose();
  }

  // --- FUNÇÃO CENTRAL DE DUPLICIDADE ---
  bool _isDuplicado(String campo, String valor) {
    if (valor.isEmpty) return false;
    for (var u in listaUsuarios) {
      if (widget.usuarioOriginal != null && u.idUsuario == widget.usuarioOriginal!.idUsuario) continue;
      if (campo == 'cpf' && u.cpf == valor) return true;
      if (campo == 'telefone' && u.telefone == valor) return true;
      if (campo == 'email' && u.email == valor) return true;
    }
    return false;
  }

  // --- LÓGICAS INDIVIDUAIS DE VALIDAÇÃO ---
  String? _validarCPFLogica(String? valor) {
    if (valor == null || valor.isEmpty) return 'CPF é obrigatório';
    String cpfLimpo = valor.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpfLimpo.length != 11) return 'CPF incompleto';
    if (RegExp(r'^(\d)\1*$').hasMatch(cpfLimpo)) return 'CPF não pode ter números repetidos'; 
    
    int soma = 0;
    for (int i = 0; i < 9; i++) { soma += int.parse(cpfLimpo[i]) * (10 - i); }
    int resto = 11 - (soma % 11);
    int digito1 = resto >= 10 ? 0 : resto;
    if (digito1 != int.parse(cpfLimpo[9])) return 'Dígito verificador inválido';

    soma = 0;
    for (int i = 0; i < 10; i++) { soma += int.parse(cpfLimpo[i]) * (11 - i); }
    resto = 11 - (soma % 11);
    int digito2 = resto >= 10 ? 0 : resto;
    if (digito2 != int.parse(cpfLimpo[10])) return 'Dígito verificador inválido';

    if (_isDuplicado('cpf', valor)) return 'CPF já cadastrado em outro usuário.';
    return null; 
  }

  String? _validarTelefoneLogica(String? valor) {
    if (valor != null && valor.isNotEmpty && _isDuplicado('telefone', valor)) return 'Telefone já cadastrado.';
    return null;
  }

  String? _validarEmailLogica(String? valor) {
    if (valor != null && valor.isNotEmpty) {
      if (!valor.contains('@')) return 'E-mail inválido';
      if (_isDuplicado('email', valor)) return 'E-mail já cadastrado.';
    }
    return null;
  }

  Future<void> _buscarCEP() async {
    String cep = _cep.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;

    setState(() => _buscandoCep = true);
    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        var dados = jsonDecode(response.body);
        if (dados['erro'] == null) {
          setState(() {
            _logradouro.text = dados['logradouro'] ?? '';
            _bairro.text = dados['bairro'] ?? '';
            _cidade.text = dados['localidade'] ?? '';
            _uf.text = dados['uf'] ?? '';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro de conexão ao buscar CEP.")));
    } finally {
      setState(() => _buscandoCep = false);
    }
  }

  void _salvar() {
    // Força a validação de todos antes de tentar salvar
    setState(() { 
      _erroCpfDinamico = _validarCPFLogica(_cpf.text); 
      _erroTelefoneDinamico = _validarTelefoneLogica(_telefone.text);
      _erroEmailDinamico = _validarEmailLogica(_email.text);
    });

    if (_chaveForm.currentState!.validate() && _erroCpfDinamico == null && _erroTelefoneDinamico == null && _erroEmailDinamico == null) {
      bool ehEdicao = widget.usuarioOriginal != null;
      if (ehEdicao) {
        int idx = listaUsuarios.indexWhere((u) => u.idUsuario == widget.usuarioOriginal!.idUsuario);
        listaUsuarios[idx] = widget.usuarioOriginal!.copiarCom(
          nome: _nome.text, cpf: _cpf.text, tel: _telefone.text, email: _email.text,
          cep: _cep.text, logradouro: _logradouro.text, numero: _numero.text, complemento: _complemento.text, bairro: _bairro.text, cidade: _cidade.text, uf: _uf.text, pwd: _senha.text, cargo: _cargo
        );
      } else {
        listaUsuarios.add(Usuario(
          idUsuario: _login.text.toUpperCase(), senha: _senha.text, nomeCompleto: _nome.text, cargo: _cargo,
          cpf: _cpf.text, telefone: _telefone.text, email: _email.text,
          cep: _cep.text, logradouro: _logradouro.text, numero: _numero.text, complemento: _complemento.text, bairro: _bairro.text, cidade: _cidade.text, uf: _uf.text
        ));
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool ehEdicao = widget.usuarioOriginal != null;
    return Scaffold(
      appBar: AppBar(title: Text(ehEdicao ? "Editar Cadastro" : "Novo Colaborador")),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _chaveForm,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1. Dados Pessoais", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Expanded(flex: 2, child: TextFormField(
                        controller: _nome, autofocus: true, textInputAction: TextInputAction.next,
                        inputFormatters: [PrimeiraLetraMaiusculaFormatter()],
                        decoration: const InputDecoration(labelText: 'Nome Completo', hintText: 'Ex: João da Silva'),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      )),
                      const SizedBox(width: 15),
                      Expanded(child: TextFormField(
                        controller: _cpf, focusNode: _cpfFocus, keyboardType: TextInputType.number, textInputAction: TextInputAction.next,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'CPF', hintText: '000.000.000-00', 
                          errorText: _erroCpfDinamico, 
                          errorMaxLines: 2,
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: TextFormField(
                        controller: _telefone, focusNode: _telefoneFocus, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, TelefoneInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Celular/WhatsApp', hintText: '(00) 00000-0000',
                          errorText: _erroTelefoneDinamico,
                        ),
                      )),
                      const SizedBox(width: 15),
                      Expanded(flex: 2, child: TextFormField(
                        controller: _email, focusNode: _emailFocus, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'E-mail', hintText: 'email@exemplo.com',
                          errorText: _erroEmailDinamico,
                        ),
                      )),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text("2. Endereço (Integração Correios)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: TextFormField(
                        controller: _cep, keyboardType: TextInputType.number, textInputAction: TextInputAction.next,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, CepInputFormatter()],
                        decoration: InputDecoration(labelText: 'CEP', hintText: '00000-000', suffixIcon: _buscandoCep ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search)),
                        onChanged: (v) { if (v.length == 9) _buscarCEP(); },
                      )),
                      const SizedBox(width: 15),
                      Expanded(flex: 2, child: TextFormField(controller: _logradouro, decoration: const InputDecoration(labelText: 'Logradouro', hintText: 'Rua, Avenida...'))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: TextFormField(
                        controller: _numero, textInputAction: TextInputAction.next,
                        inputFormatters: [NumeroEnderecoFormatter()],
                        decoration: const InputDecoration(labelText: 'Número', hintText: 'Ex: 123 ou SN'),
                      )),
                      const SizedBox(width: 15),
                      Expanded(flex: 2, child: TextFormField(
                        controller: _complemento, textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Complemento', hintText: 'Apto, Bloco...'),
                      )),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _bairro, decoration: const InputDecoration(labelText: 'Bairro'))),
                      const SizedBox(width: 15),
                      Expanded(child: TextFormField(controller: _cidade, decoration: const InputDecoration(labelText: 'Cidade'))),
                      const SizedBox(width: 15),
                      SizedBox(width: 80, child: TextFormField(controller: _uf, decoration: const InputDecoration(labelText: 'UF', hintText: 'RJ'), inputFormatters: [UpperCaseTextFormatter()])),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text("3. Acesso ao Sistema", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: TextFormField(
                        controller: _login, enabled: !ehEdicao, inputFormatters: [UpperCaseTextFormatter()], textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'Login', hintText: 'EX: ANDRE123', fillColor: ehEdicao ? Colors.grey[200] : Colors.white),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      )),
                      const SizedBox(width: 15),
                      Expanded(child: TextFormField(
                        controller: _senha, obscureText: true, onFieldSubmitted: (_) => _salvar(),
                        decoration: const InputDecoration(labelText: 'Senha', hintText: '***'),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      )),
                      const SizedBox(width: 15),
                      Expanded(child: DropdownButtonFormField<String>(
                        value: _cargo, items: ['ADMIN', 'FUNCIONARIO'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _cargo = v!), decoration: const InputDecoration(labelText: 'Perfil de Acesso'),
                      )),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.cancel), label: const Text("CANCELAR")),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(onPressed: _salvar, icon: const Icon(Icons.save), label: const Text("SALVAR CADASTRO")),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// --- NOSSOS FORMATADORES CUSTOMIZADOS ---
// =============================================================================

class NumeroEnderecoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String textoDigitado = newValue.text.toUpperCase();
    if (textoDigitado.isEmpty) return newValue;
    if (RegExp(r'^[0-9]+$').hasMatch(textoDigitado) || textoDigitado == 'S' || textoDigitado == 'SN') {
      return TextEditingValue(text: textoDigitado, selection: newValue.selection);
    }
    return oldValue; 
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) => TextEditingValue(text: n.text.toUpperCase(), selection: n.selection);
}

class PrimeiraLetraMaiusculaFormatter extends TextInputFormatter {
  @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    if (n.text.isEmpty) return n;
    String formatado = n.text.split(' ').map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1).toLowerCase()).join(' ');
    return TextEditingValue(text: formatado, selection: n.selection);
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var text = n.text; if (text.length > 11) text = text.substring(0, 11);
    var formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) formatted += '.'; if (i == 9) formatted += '-';
      formatted += text[i];
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class TelefoneInputFormatter extends TextInputFormatter {
  @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var text = n.text; if (text.length > 11) text = text.substring(0, 11);
    var formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 0) formatted += '('; if (i == 2) formatted += ') '; if (i == 7) formatted += '-';
      formatted += text[i];
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class CepInputFormatter extends TextInputFormatter {
  @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var text = n.text; if (text.length > 8) text = text.substring(0, 8);
    var formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 5) formatted += '-';
      formatted += text[i];
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}