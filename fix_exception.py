with open('backend/src/main/java/com/quentinhas/backend/service/ProdutoService.java', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import com.quentinhas.backend.exception.ResourceNotFoundException;\n", "")
content = content.replace("new ResourceNotFoundException", "new IllegalArgumentException")

with open('backend/src/main/java/com/quentinhas/backend/service/ProdutoService.java', 'w', encoding='utf-8') as f:
    f.write(content)
