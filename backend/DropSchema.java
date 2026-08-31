import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class DropSchema {
    public static void main(String[] args) {
        try {
            Connection conn = DriverManager.getConnection("jdbc:postgresql://localhost:5440/quentinhas_test", "quentinhas_app", "app_password");
            Statement stmt = conn.createStatement();
            stmt.execute("DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO quentinhas_app;");
            System.out.println("Dropped and recreated schema.");
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
