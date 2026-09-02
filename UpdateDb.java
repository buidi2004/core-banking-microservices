import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class UpdateDb {
    public static void main(String[] args) throws Exception {
        String url = "jdbc:postgresql://localhost:30000/walletdb";
        String user = "walletuser";
        String pass = "walletpassword";
        
        try (Connection conn = DriverManager.getConnection(url, user, pass)) {
            System.out.println("Connected to DB.");
            
            // Give names to known test numbers
            conn.createStatement().executeUpdate("UPDATE users SET full_name = 'NGUYEN VAN A' WHERE phone_number = '999999999'");
            conn.createStatement().executeUpdate("UPDATE users SET full_name = 'BUI DINH THI' WHERE phone_number = '2222222222'");
            conn.createStatement().executeUpdate("UPDATE users SET full_name = 'NGUYEN VAN B' WHERE phone_number = '888888888'");
            
            // Set default name for any other user with null name
            int count = conn.createStatement().executeUpdate("UPDATE users SET full_name = 'KHACH HANG ' || substring(phone_number from length(phone_number)-3 for 4) WHERE full_name IS NULL");
            System.out.println("Updated " + count + " other users.");
        }
    }
}
