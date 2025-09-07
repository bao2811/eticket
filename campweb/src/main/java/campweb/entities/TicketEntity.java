package campweb.entities;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Data;
import org.hibernate.annotations.UuidGenerator;

@Entity
@Table(name = "tickets")
@Data
public class TicketEntity {
    @Id
    @GeneratedValue(generator = "UUID")
    @UuidGenerator
    private UUID id;

    private String name;
    private String email;

    private UUID zone_id;   // nếu có quan hệ ZoneEntity thì nên đổi sang ManyToOne
    private UUID event_id;  // nếu có EventEntity thì nên đổi sang ManyToOne
    private String seatNumber;
    private UUID seatId;

    // 👇 Đây là quan hệ với OrderEntity
    @ManyToOne
    @JoinColumn(name = "order_id", referencedColumnName = "id") // FK trong bảng tickets
    private OrderEntity order;
}
