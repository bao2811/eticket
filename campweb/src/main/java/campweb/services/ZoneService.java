package campweb.services;

import campweb.entities.ZoneEntity;
import campweb.payload.TicketCreateRequest;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;


@Service
public interface ZoneService {
    List<ZoneEntity> getAllZoneByIds(UUID ticketIds);
    ZoneEntity createZone(TicketCreateRequest ticketCreateRequest);
}
