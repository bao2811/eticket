package campweb.services.impl;

import campweb.entities.EventEntity;
import campweb.services.EventService;
import campweb.repositories.EventRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;


@Service
public class EventServiceImpl implements EventService {

    @Autowired
    private EventRepository eventRepository;

    @Override
    public List<EventEntity> getListEvent() {
        return eventRepository.findAll();
    }

    @Override
    public EventEntity createEvent(EventEntity eventEntity) {
        return eventRepository.save(eventEntity);
    }
}
