with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
    
idx1 = content.find('class TelaGestaoProdutos extends')
idx2 = content.find('class TelaCadastroProduto extends', idx1)
print(content[idx1:idx2])
