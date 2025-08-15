package campweb.controllers;

import campweb.entities.ZoneEntity;
import campweb.services.ZoneService;

import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/zones")
public class ZoneController {
    @Autowired
    private ZoneService zoneService;

    @GetMapping("zone-event")
    public ResponseEntity<List<ZoneEntity>> getEventZone(@RequestParam String id) {
        UUID eventId = UUID.fromString(id);
        List<ZoneEntity> zones = zoneService.getAllZoneByIds(eventId);
        if (zones.isEmpty()) {
            return ResponseEntity.status(404).body(null);
        }
        System.out.println("Zones data: " + zones);
        return ResponseEntity.ok(zones);
    }

}