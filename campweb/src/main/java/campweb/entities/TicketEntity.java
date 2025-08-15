package campweb.entities;

import jakarta.persistence.*;
import java.util.UUID;
import org.hibernate.annotations.UuidGenerator;

@Entity
@Table(name = "tickets")
public class TicketEntity {
    @Id
    @GeneratedValue(generator = "UUID")
    @UuidGenerator
    private UUID id;

    private String name;
    private String email;
    private Long amount;

    private UUID zoneEntity;

    @ManyToOne
    @JoinColumn(name = "event_id")
    private OrderEntity order;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Long getAmount() {
        return amount;
    }

    public void setAmount(Long amount) {
        this.amount = amount;
    }

    public UUID getZoneEntity() {
        return zoneEntity;
    }

    public void setZoneEntity(UUID zoneEntity) {
        this.zoneEntity = zoneEntity;
    }

    public OrderEntity getOrder() {
        return order;
    }

    public void setOrder(OrderEntity order) {
        this.order = order;
    }
}
