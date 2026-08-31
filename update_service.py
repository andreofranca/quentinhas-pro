with open('backend/src/main/java/com/quentinhas/backend/service/ProdutoService.java', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("request.precoBase()", "request.precoBase());\n        if (request.estoqueAtual() != null) produto.setEstoqueAtual(request.estoqueAtual());\n        if (request.estoqueMinimo() != null) produto.setEstoqueMinimo(request.estoqueMinimo()")

content = content.replace("produto.getPrecoBase(),", "produto.getPrecoBase(),\n                produto.getEstoqueAtual(),\n                produto.getEstoqueMinimo(),")

with open('backend/src/main/java/com/quentinhas/backend/service/ProdutoService.java', 'w', encoding='utf-8') as f:
    f.write(content)
