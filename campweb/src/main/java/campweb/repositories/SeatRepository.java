package campweb.repositories;

import campweb.entities.SeatEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SeatRepository extends JpaRepository<SeatEntity, UUID> {
    // Define custom query methods if needed
    // For example, find seats by event ID or status


    List<SeatEntity> findByEventId(String eventId);
    List<SeatEntity> findByStatus(String status);
    List<SeatEntity> findByEventIdAndName(String eventId, String name);
}
