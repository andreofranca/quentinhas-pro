import 'api_client.dart';

class UsuarioEquipe {
  final String id;
  final String nome;
  final String email;
  final String role;
  final bool ativo;

  const UsuarioEquipe({required this.id, required this.nome, required this.email, required this.role, required this.ativo});

  factory UsuarioEquipe.fromJson(Map<String, dynamic> json) => UsuarioEquipe(
    id: json['id'].toString(), nome: json['nome'] as String, email: json['email'] as String,
    role: json['role'] as String, ativo: json['ativo'] as bool? ?? true,
  );
}

class GestaoUsuariosService {
  final ApiClient _api = ApiClient.instance;

  Future<List<UsuarioEquipe>> listar() async => ((await _api.get('/api/gestao/usuarios')) as List)
      .map((item) => UsuarioEquipe.fromJson(item as Map<String, dynamic>)).toList();

  Future<UsuarioEquipe> criar(Map<String, dynamic> dados) async =>
      UsuarioEquipe.fromJson(await _api.post('/api/gestao/usuarios', body: dados));

  Future<UsuarioEquipe> atualizar(String id, Map<String, dynamic> dados) async =>
      UsuarioEquipe.fromJson(await _api.put('/api/gestao/usuarios/$id', body: dados));

  Future<UsuarioEquipe> autenticarAdmin(String email, String senha) async {
    final payload = await _api.post('/api/auth/login', body: {'email': email.trim(), 'senha': senha});
    final usuarioMap = payload['usuario'] as Map<String, dynamic>;
    final usuario = UsuarioEquipe.fromJson(usuarioMap);

    if (usuario.role != 'ADMIN' && usuario.role != 'GERENTE') {
      throw Exception('Usuário sem permissão de administração.');
    }

    return usuario;
  }
}
