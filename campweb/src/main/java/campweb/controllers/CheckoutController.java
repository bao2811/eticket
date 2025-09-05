package campweb.controllers;

import campweb.config.OnepayConfig;
import campweb.entities.OrderEntity;
import campweb.payload.CheckoutResponse;
import campweb.services.CheckoutService;
import campweb.services.OnepayService;
import campweb.services.OrderService;
import campweb.utils.JwtUtils;
import campweb.payload.OrderRequest;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Enumeration;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Value;
@RestController
@RequestMapping("/checkout")
public class CheckoutController {
    
    @Autowired
    private CheckoutService checkoutService;

    @Autowired
    private OnepayService onepayService;

    @Autowired
    private OrderService orderService;

    @Autowired
    private JwtUtils jwtUtils;

    @PostMapping
    public ResponseEntity<Object> checkout(@RequestBody OrderRequest orderRequest) {
        OrderEntity orderEntity = orderService.createOrder(orderRequest);
        //sửa lại cho chuẩn, trả về token và orderentity
        CheckoutResponse response = checkoutService.getCheckout(orderEntity);

        Map<String, List<Integer>> seats = orderRequest.getSeats();

        return ResponseEntity.ok(seats);
    }

    @Value("${onepay.virtual-payment-client-url}")
    private String virtualPaymentClientURL;

    @Value("${onepay.vpc-merchant}")
    private String vpcMerchant;

    @Value("${onepay.promotion-list}")
    private String promotionList;

    @Value("${onepay.vpc-access-code}")
    private String vpcAccessCode;

    @Value("${onepay.secure-secret}")
    private String secureSecret;


    // gửi dữ liệu cho onepay
    @PostMapping("/onepay")
    public ResponseEntity<CheckoutResponse> onepayCheckout(HttpServletRequest req) {
        try {
            // tạo mã ref giả
            String txnRef = "txn_" + System.currentTimeMillis();
            
            // ip của client
            String clientIp = req.getRemoteAddr();

            Map<String, Object> fields = new HashMap<>();
            fields.put("vpc_TicketNo", clientIp);
            fields.put("vpc_Merchant", vpcMerchant);
            fields.put("vpc_OrderInfo", txnRef);
            fields.put("vpc_AccessCode", vpcAccessCode);
            fields.put("virtualPaymentClientURL", virtualPaymentClientURL);
            fields.put("vpc_Version", OnepayConfig.VPC_VERSION);
            fields.put("vpc_Command", OnepayConfig.VPC_COMMAND);
            fields.put("AgainLink", OnepayConfig.AGAIN_LINK);
            fields.put("Title", OnepayConfig.TITLE);
            fields.put("vpc_ReturnURL", "http://localhost:8080" + OnepayConfig.VPC_RETURN_URL);

            String vpc_Locale = req.getParameter("vpc_Locale");
            if (vpc_Locale == null || vpc_Locale.length() == 0) {
                vpc_Locale = OnepayConfig.VPC_LOCALE;
            }

            fields.put("vpc_Locale", vpc_Locale);
            fields.put("vpc_Amount", String.valueOf(100000 * 100));
            fields.put("user_orderId", "id");


            // duyệt qua các tham số của request
            for (Enumeration<String> enum1 = req.getParameterNames(); enum1.hasMoreElements(); ) {
                String fieldName = enum1.nextElement();
                String fieldValue = req.getParameter(fieldName);
                if ((fieldValue != null) && (fieldValue.length() > 0)) {
                    // append the URL paramete
                fields.put(fieldName, fieldValue);
                }
            }

            String vpcURL = (String) fields.remove("virtualPaymentClientURL");
            fields.remove("SubButl");

            if (secureSecret != null && secureSecret.length() > 0) {
                // mã hóa dữ liệu
                String secureHash = onepayService.hashAllFields(fields);
                fields.put("vpc_SecureHash", secureHash);
            }

            StringBuffer buf = new StringBuffer();
            buf.append(vpcURL).append("?");
            
            OnepayConfig.appendQueryFields(buf, fields);

            String onepayUrl = buf.toString();
            String redirectUrl = onepayUrl;

            return ResponseEntity.ok(new CheckoutResponse(redirectUrl));
        }
        catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new CheckoutResponse("Error occurred"));
        }
    }

    // onepay gọi về và thông báo kết quả
    @GetMapping("/ipn")
    public ResponseEntity<String> ipn(HttpServletRequest req) {
         Enumeration<String> requestParams = req.getParameterNames();
        while(requestParams.hasMoreElements()){
            String paramName = requestParams.nextElement();
            String[] values =  req.getParameterValues(paramName);
            if ("vpc_TxnResponseCode".equals(paramName)){
                for (String value: values) {
                    if ("0".equals(value) || "00".equals(value)) {
                        System.out.println("Giao dịch thành công!");
                        // TODO: cập nhật đơn hàng trong DB, gửi mail, v.v....
                    } else {
                        System.out.println("Giao dịch thất bại. Mã lỗi: " + value);
                    }
                }
            }
        }
       return ResponseEntity.ok("URL_Frontend hiện thị thông báo giao dịch thành công hoặc thất bại");
    }

}
