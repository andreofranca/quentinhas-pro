with open("lib/main.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "final categorias = _estoque.map((p) => p.categoria)" in line:
        # Check context
        if "final lista = cardapio.where" in lines[i+1] or "_TelaSelecaoProdutoDialogState" in "".join(lines[i-20:i]):
            lines[i] = line.replace("_estoque", "cardapio")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)
