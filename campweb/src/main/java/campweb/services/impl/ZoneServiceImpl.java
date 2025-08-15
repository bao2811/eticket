package campweb.services.impl;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import campweb.entities.EventEntity;
import campweb.entities.ZoneEntity;
import campweb.payload.TicketCreateRequest;
import campweb.repositories.EventRepository;
import campweb.repositories.ZoneRepository;
import campweb.services.ZoneService; 
import org.springframework.stereotype.Service;
import java.util.UUID;

@Service
public class ZoneServiceImpl implements ZoneService {
    @Autowired
    private ZoneRepository zoneRepository;

    @Autowired
    private EventRepository eventRepository;

    @Override
    public List<ZoneEntity> getAllZoneByIds(UUID eventId) {
      List<ZoneEntity> zones = zoneRepository.findByEventId(eventId);
      return zones;
    }
    
    @Override
    public ZoneEntity createZone(TicketCreateRequest ticketCreateRequest) {
        EventEntity eventEntity = eventRepository.findById(ticketCreateRequest.getEventId())
            .orElseThrow(() -> new RuntimeException("Event not found"));

        ZoneEntity zoneEntity = new ZoneEntity();
        zoneEntity.setName(ticketCreateRequest.getName());
        zoneEntity.setPrice(ticketCreateRequest.getPrice());
        zoneEntity.setEvent(eventEntity);
        zoneEntity = zoneRepository.save(zoneEntity);
        return zoneEntity;
    }
}