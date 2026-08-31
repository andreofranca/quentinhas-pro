with open('backend/src/test/java/com/quentinhas/backend/controller/ProdutoIntegrationTest.java', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("@Autowired\n    private ObjectMapper objectMapper;", "private ObjectMapper objectMapper = new ObjectMapper();")

with open('backend/src/test/java/com/quentinhas/backend/controller/ProdutoIntegrationTest.java', 'w', encoding='utf-8') as f:
    f.write(content)
