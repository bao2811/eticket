package campweb.controllers;

import campweb.entities.SeatEntity;
import campweb.services.SeatService;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.http.ResponseEntity;

@Controller
@RequestMapping("/seats")
public class SeatController {
    
    @Autowired
    private SeatService seatService;


    @GetMapping("/list/{eventId}")
    public ResponseEntity<List<SeatEntity>> listSeats(@PathVariable String eventId) {
        List<SeatEntity> seats = seatService.getAllSeatsByEventId(eventId);
        return ResponseEntity.ok(seats);
    }

}
