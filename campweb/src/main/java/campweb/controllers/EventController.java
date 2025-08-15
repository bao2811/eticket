package campweb.controllers;

import campweb.entities.EventEntity;
import campweb.services.EventService;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/events")
public class EventController {
    @Autowired
    private EventService eventService;

    // private Map<UUID, EventEntity> eventList;

    @GetMapping
    public ResponseEntity<List<EventEntity>> getAllEvents() {
        // eventList = eventService.getListEvent().stream()
        //     .collect(java.util.stream.Collectors.toMap(EventEntity::getId, e -> e));
        List<EventEntity> events = eventService.getListEvent();
        System.out.println("Events data: " + events);
        return ResponseEntity.ok(eventService.getListEvent());
    }

   @GetMapping("title-event")
    public ResponseEntity<?> getEventsByTitle(@RequestParam String idString) {
        List<EventEntity> matched;
        try {
            UUID uuid = UUID.fromString(idString);
            matched = eventService.getListEvent().stream()
                    .filter(event -> event.getId().equals(uuid))
                    .toList();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(400).body("Invalid UUID format: " + idString);
        }

        if (matched.isEmpty()) {
            return ResponseEntity.status(404).body("No event found with id: " + idString);
        }

        return ResponseEntity.ok(matched);
    }

    
    @PostMapping
    public EventEntity createEvent(@RequestBody EventEntity eventEntity) {
        return eventService.createEvent(eventEntity);
    }

    // @GetMapping("event-by-id")
    // public ResponseEntity<EventEntity> getEventById(@RequestParam String id) {
    //     EventEntity event = eventList.get(UUID.fromString(id));
    //     if (event == null) {
    //         return ResponseEntity.status(404).body(null);
    //     }
    //     return ResponseEntity.ok(event);
    // }

}