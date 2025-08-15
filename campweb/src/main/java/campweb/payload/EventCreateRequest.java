package campweb.payload;

public class EventCreateRequest {
    private String name;
    private String description;
    private String date;
    private String location;
    private String status;
    private String type;
    private Long maxBuy;


    public String getName() {
        return name;
    }
}
