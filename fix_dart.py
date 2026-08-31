with open('lib/services/gestao_produtos_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()
    
content = content.replace("'/api/gestao/produtos/' + id", "'/api/gestao/produtos/$id'")

with open('lib/services/gestao_produtos_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
