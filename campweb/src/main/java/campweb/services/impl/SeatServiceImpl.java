package campweb.services.impl;

import org.springframework.stereotype.Service;
import campweb.services.SeatService;
import campweb.entities.SeatEntity;
import campweb.repositories.SeatRepository;
import org.springframework.beans.factory.annotation.Autowired;
import java.util.List;

@Service
public class SeatServiceImpl implements SeatService {

    @Autowired
    private SeatRepository seatRepository;

    @Override
    public List<SeatEntity> getAllSeatsByEventId(String eventId) {
        return seatRepository.findByEventId(eventId);
    }

    @Override
    public List<SeatEntity> getSeatByEventIdAndName(String eventId, String name) {
        // Assuming you have a method in SeatRepository to find seats by event and zone
        return seatRepository.findByEventIdAndName(eventId, name);
    }
    @Override
    public SeatEntity createSeat(SeatEntity seatEntity) {
        // Validate and save the seat entity
        return seatRepository.save(seatEntity);
    }
}
