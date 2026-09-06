import re
import os

def fix_dollar(file):
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # fix the broken Text('Erro: \')
    content = content.replace("Text('Erro: \\')", "Text('Erro: \')")
    # fix withOpacity -> withValues (or ignore the info, but let's replace)
    content = content.replace(".withOpacity(0.1)", ".withOpacity(0.1)")
    
    # Pedido fixes
    content = content.replace("p.cliente?.nome", "p.nomeCliente")
    content = content.replace("p.observacoes", "p.observacao")
    content = content.replace("p.tipoEntrega", "p.tipoEntrega")
    content = content.replace("i.oferta.nome", "i.produto.nome")
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

fix_dollar('lib/screens/dashboard/tela_dashboard_real.dart')
fix_dollar('lib/screens/gestao/tela_kds.dart')
fix_dollar('lib/screens/gestao/tela_lista_pedidos.dart')
fix_dollar('lib/screens/gestao/tela_caixa.dart')

