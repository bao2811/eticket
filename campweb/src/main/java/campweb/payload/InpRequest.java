package campweb.payload;

import lombok.Data;

@Data
public class InpRequest {
    String vpc_Version;
    String vpc_Currency;
    String secureCode;
    Long amount;
    String txnRef;
}
