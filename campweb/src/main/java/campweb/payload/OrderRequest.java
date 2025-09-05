package campweb.payload;

import java.util.List;
import java.util.Map;
import lombok.Data;

@Data
public class OrderRequest {
    private String customerName;
    private String customerEmail;
    private Map<String, List<Integer>> seats;
    private long totalAmount;
    private long orderTime;
    private String status;

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

}
