package campweb.utils;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

@Component
public class JwtUtils {
    private static final String SECRET_KEY = "thuyduongxinhgai0110"; // Replace with your actual secret key
    
    public String generateToken(UserDetails userdetail) {
        // Logic to generate JWT token using the SECRET_KEY and username
        // This is a placeholder for the actual implementation
        Map<String, Object> permissions = new HashMap<>();
        permissions.put("username", userdetail.getUsername());
        return createToken(permissions, userdetail.getUsername());
    }

    private String createToken(Map<String, Object> permissions, String userName) {
        // Logic to create a JWT token with the given claims and subject
        // This is a placeholder for the actual implementation
       return Jwts.builder()
                .setClaims(permissions)
                .setSubject(userName)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 1000 * 60 * 60 * 1)) // 1 hour
                .signWith(SignatureAlgorithm.HS256, SECRET_KEY)
                .compact();
    }

    public String extractUsername(String token) {
        // Logic to extract the username from the JWT token
        // This is a placeholder for the actual implementation
        return Jwts.parser()
                .setSigningKey(SECRET_KEY)
                .parseClaimsJws(token)
                .getBody()
                .getSubject();
    }

    public boolean validateToken(String token, UserDetails userDetails) {
        // Logic to validate the JWT token
        // This is a placeholder for the actual implementation
        final String username = this.extractUsername(token);
        if (username.equals(userDetails.getUsername()) && !getClaims(token).getExpiration().before(new Date())){
            return true;
        }
        return false;
    }

    public Claims getClaims(String token) {
        // Logic to get claims from the JWT token
        // This is a placeholder for the actual implementation
        return Jwts.parser()
                .setSigningKey(SECRET_KEY)
                .parseClaimsJws(token)
                .getBody();
    }
}
