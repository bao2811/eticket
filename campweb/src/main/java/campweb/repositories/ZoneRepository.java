package campweb.repositories;

import campweb.entities.ZoneEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ZoneRepository extends JpaRepository<ZoneEntity, UUID> {
    @Query(value = "select * from tickets t where t.id = :ticketIds", nativeQuery = true)
    List<ZoneEntity> getAllTicketByIds(@Param("ticketIds") UUID ticketIds);
    List<ZoneEntity> findByEventId(UUID eventId);
}
