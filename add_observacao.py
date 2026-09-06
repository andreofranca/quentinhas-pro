import re

with open('lib/models/dominio.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final String? enderecoCompleto;", "final String? enderecoCompleto;\n  final String? observacao;")
content = content.replace("this.enderecoCompleto,", "this.enderecoCompleto,\n    this.observacao,")
content = content.replace("enderecoCompleto: json['endereco_entrega'],", "enderecoCompleto: json['endereco_entrega'],\n      observacao: json['observacoes'],")

with open('lib/models/dominio.dart', 'w', encoding='utf-8') as f:
    f.write(content)
