package campweb.payload;

import campweb.model.SeatSelection;
import java.util.List;

public class OrderRequest {
    private String customerName;
    private String customerEmail;
    private List<SeatSelection> seatSelections;

    public String getCustomerName() {
        return customerName;
    }
    public void setCustomerName(String customerName) {
        this.customerName = customerName;
    }

    public String getCustomerEmail() {
        return customerEmail;
    }
    
    public void setCustomerEmail(String customerEmail) {
        this.customerEmail = customerEmail;
    }   

    public List<SeatSelection> getSeatSelections() {
        return seatSelections;
    }

    public void setSeatSelections(List<SeatSelection> seatSelections) {
        this.seatSelections = seatSelections;
    }


}
