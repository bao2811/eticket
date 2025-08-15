package campweb.entities;

import jakarta.persistence.*;
import java.util.UUID;
import org.hibernate.annotations.GenericGenerator;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "events")
public class EventEntity {
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "id", updatable = false, nullable = false, columnDefinition = "VARCHAR(36)")
    @JdbcTypeCode(SqlTypes.VARCHAR)
    private UUID id;
    private String name;
    private String location;
    private String image;
    private String status;
    private String type;
    private Long maxBuy;
    private Long startedDate;
    private String address;
    private String description;
    private byte[] image_byte;;
    
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

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getDate() {
        return startedDate != null ? String.valueOf(startedDate) : null;
    }

    public void setDate(Long startedDate) {
        this.startedDate = startedDate;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Long getMaxBuy() {
        return maxBuy;
    }

    public void setMaxBuy(Long maxBuy) {
        this.maxBuy = maxBuy;
    }

    public String getImage() {
        return image;
    }

    public void setImage(String image) {
        this.image = image;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public byte[] getImage_byte() {
        return image_byte;
    }

    public void setImage_byte(byte[] image_byte) {
        this.image_byte = image_byte;
    }

    @Override
    public String toString() {
        return "EventEntity{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", location='" + location + '\'' +
                ", image='" + image + '\'' +
                ", status='" + status + '\'' +
                ", type='" + type + '\'' +
                ", maxBuy=" + maxBuy +
                ", startedDate=" + startedDate +
                ", address='" + address + '\'' +
                ", description='" + description + '\'' +
                '}';
    }
}
