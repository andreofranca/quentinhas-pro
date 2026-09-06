import re

with open('pom.xml', 'r', encoding='utf-8') as f:
    content = f.read()

plugin = '''
            <plugin>
                <groupId>org.flywaydb</groupId>
                <artifactId>flyway-maven-plugin</artifactId>
                <version>10.17.2</version>
            </plugin>
'''

content = content.replace("</plugins>", plugin + "</plugins>")

with open('pom.xml', 'w', encoding='utf-8') as f:
    f.write(content)
