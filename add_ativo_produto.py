import re
with open('backend/src/main/java/com/quentinhas/backend/model/Produto.java', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("private BigDecimal precoBase;\n", "private BigDecimal precoBase;\n\n    @Column(nullable = false)\n    private boolean ativo = true;\n")
content = content.replace("public BigDecimal getPrecoBase() { return precoBase; }\n", "public BigDecimal getPrecoBase() { return precoBase; }\n    public boolean isAtivo() { return ativo; }\n")
content = content.replace("public void setPrecoBase(BigDecimal precoBase) { this.precoBase = precoBase; }\n", "public void setPrecoBase(BigDecimal precoBase) { this.precoBase = precoBase; }\n    public void setAtivo(boolean ativo) { this.ativo = ativo; }\n")

with open('backend/src/main/java/com/quentinhas/backend/model/Produto.java', 'w', encoding='utf-8') as f:
    f.write(content)
