package campweb.repositories;

import campweb.entities.EventEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


@Repository
public interface EventRepository extends JpaRepository<EventEntity, UUID> {

    Optional<EventEntity> findByName(String name);
    boolean existsByName(String name);

}
