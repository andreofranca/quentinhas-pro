import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.nio.file.Files;
import java.nio.file.Paths;

public class InitSchema {
    public static void main(String[] args) {
        try {
            Connection conn = DriverManager.getConnection("jdbc:postgresql://localhost:5440/quentinhas_test", "quentinhas_app", "app_password");
            Statement stmt = conn.createStatement();
            
            String v1 = new String(Files.readAllBytes(Paths.get("backend/src/main/resources/db/migration/V1__init_schema.sql")));
            stmt.execute(v1);
            
            String v2 = new String(Files.readAllBytes(Paths.get("backend/src/main/resources/db/migration/V2__add_ativo_oferta.sql")));
            stmt.execute(v2);

            String v3 = new String(Files.readAllBytes(Paths.get("backend/src/main/resources/db/migration/V3__add_ativo_produto.sql")));
            stmt.execute(v3);

            System.out.println("Initialized schema.");
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
