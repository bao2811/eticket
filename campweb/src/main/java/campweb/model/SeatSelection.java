package campweb.model;
import java.util.List;
import java.util.Map;

public abstract class SeatSelection {

    private Map<String, List<Integer>> seats;

    public Map<String, List<Integer>> getSeats() {
        return seats;
    }

    public void setSeats(Map<String, List<Integer>> seats) {
        this.seats = seats;
    }
}