with open('backend/src/main/java/com/quentinhas/backend/model/Produto.java', 'r', encoding='utf-8') as f:
    content = f.read()

# Add fields
content = content.replace(
    "private boolean ativo = true;",
    "private boolean ativo = true;\n\n    @Column(name = \"estoque_atual\", nullable = false)\n    private int estoqueAtual = 0;\n\n    @Column(name = \"estoque_minimo\", nullable = false)\n    private int estoqueMinimo = 8;"
)

# Add getters
content = content.replace(
    "public boolean isAtivo() { return ativo; }",
    "public boolean isAtivo() { return ativo; }\n    public int getEstoqueAtual() { return estoqueAtual; }\n    public int getEstoqueMinimo() { return estoqueMinimo; }"
)

# Add setters
content = content.replace(
    "public void setAtivo(boolean ativo) { this.ativo = ativo; }",
    "public void setAtivo(boolean ativo) { this.ativo = ativo; }\n    public void setEstoqueAtual(int estoqueAtual) { this.estoqueAtual = estoqueAtual; }\n    public void setEstoqueMinimo(int estoqueMinimo) { this.estoqueMinimo = estoqueMinimo; }"
)

with open('backend/src/main/java/com/quentinhas/backend/model/Produto.java', 'w', encoding='utf-8') as f:
    f.write(content)
