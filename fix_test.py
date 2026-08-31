with open('backend/src/test/java/com/quentinhas/backend/controller/ProdutoIntegrationTest.java', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;", "import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;")

with open('backend/src/test/java/com/quentinhas/backend/controller/ProdutoIntegrationTest.java', 'w', encoding='utf-8') as f:
    f.write(content)
