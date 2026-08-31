import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.nio.file.Files;
import java.nio.file.Paths;

public class InitLocalSchema {
    public static void main(String[] args) {
        try {
            Connection conn = DriverManager.getConnection("jdbc:postgresql://localhost:5440/quentinhas", "quentinhas_app", "app_password");
            Statement stmt = conn.createStatement();
            
            String v3 = new String(Files.readAllBytes(Paths.get("backend/src/main/resources/db/migration/V3__add_ativo_produto.sql")));
            stmt.execute(v3);

            System.out.println("V3 applied to local schema.");
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
