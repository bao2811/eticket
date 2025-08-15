package campweb.entities;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Data;
import org.hibernate.annotations.UuidGenerator;


@Data
@Entity
@Table(name = "zones")
public class ZoneEntity {
    @Id
    @GeneratedValue(generator = "UUID")
    @UuidGenerator
    private UUID id;
    private String name;
    private Long price;
    private String status;
    private String points;
    private String color;
    private Integer quantity;
    private Integer bought;


    @ManyToOne
    @JoinColumn(name = "event_id")
    private EventEntity event;


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

    public Long getPrice() {
        return price;
    }

    public void setPrice(Long price) {
        this.price = price;
    }

    public EventEntity getEvent() {
        return event;
    }

    public void setEvent(EventEntity event) {
        this.event = event;
    }
}
