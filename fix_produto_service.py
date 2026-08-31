with open("backend/src/main/java/com/quentinhas/backend/service/ProdutoService.java", "r", encoding="utf-8") as f:
    content = f.read()

import re

# Fix toResponse
new_toResponse = """    private ProdutoResponse toResponse(Produto produto) {
        return new ProdutoResponse(
                produto.getId(),
                produto.getNome(),
                produto.getDescricao(),
                produto.getCategoria(),
                produto.getPrecoBase(),
                produto.getEstoqueAtual(),
                produto.getEstoqueMinimo(),
                produto.isAtivo()
        );
    }"""
content = re.sub(r'    private ProdutoResponse toResponse\(Produto produto\) \{.*?    \}', new_toResponse, content, flags=re.DOTALL)

with open("backend/src/main/java/com/quentinhas/backend/service/ProdutoService.java", "w", encoding="utf-8") as f:
    f.write(content)
