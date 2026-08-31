with open('lib/models/models_quentinha.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_idx = content.find('final List<OfertaQuentinha> mockCardapioHoje = [')
if start_idx != -1:
    end_idx = content.find('];', start_idx) + 2
    content = content[:start_idx] + content[end_idx:]

with open('lib/models/models_quentinha.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
