import re

with open('lib/screens/gestao/tela_kds.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("_pedidoService.atualizarStatusLogistico(p.id, novoStatus);", "_dashboardService.atualizarStatus(p.numeroPedido, novoStatus);")
content = content.replace("p.id", "p.numeroPedido")

with open('lib/screens/gestao/tela_kds.dart', 'w', encoding='utf-8') as f:
    f.write(content)
