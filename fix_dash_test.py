import re

with open('test/dashboard_operacional_test.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Make it pump the Dashboard directly instead of the whole App
content = content.replace("await tester.pumpWidget(AppLanchonete(whatsappService: fakeService));", "await tester.pumpWidget(MaterialApp(home: TelaDashboardQuentinhas(whatsappService: fakeService, usuarioLogado: Usuario(idUsuario: '1', nomeCompleto: 'Admin', cargo: 'ADMIN', senha: '123', email: 'a@a.com', cep: '', logradouro: '', numero: '', complemento: '', bairro: '', cidade: '', uf: '', situacaoConta: true))));")

# We also need to import TelaDashboardQuentinhas
content = content.replace("import 'package:lanchonete_controle/main.dart';", "import 'package:lanchonete_controle/main.dart';\nimport 'package:lanchonete_controle/screens/dashboard/tela_dashboard_quentinhas.dart';\nimport 'package:lanchonete_controle/models/dominio.dart';")

with open('test/dashboard_operacional_test.dart', 'w', encoding='utf-8') as f:
    f.write(content)
