package campweb.services;

import campweb.entities.SeatEntity;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public interface SeatService {
    List<SeatEntity> getAllSeatsByEventId(String eventId);
    List<SeatEntity> getSeatByEventIdAndName(String eventId, String name);
    SeatEntity createSeat(SeatEntity seatEntity);
}
