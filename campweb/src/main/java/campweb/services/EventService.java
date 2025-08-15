package campweb.services;

import campweb.entities.EventEntity;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public interface EventService {
	List<EventEntity> getListEvent();
	EventEntity createEvent(EventEntity eventEntity);

}
