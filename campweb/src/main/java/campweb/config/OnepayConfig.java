package campweb.config;

import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;


public class OnepayConfig {
    static public final String VPC_COMMAND = "pay";

    static public final String VPC_RETURN_URL = "/checkout/ipn";
    static public final String VPC_VERSION = "2";
    static public final String AGAIN_LINK = "onepay.vn";
    static public final String TITLE = "Marathon-VPBank";
    static public final String VPC_LOCALE = "vn";
    static public final char[] HEX_TABLE = new char[]{
            '0', '1', '2', '3', '4', '5', '6', '7',
            '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};
    private static byte[] decodeHexArray = new byte[103];

    static {
        int i = 0;
        for (byte b : new byte[]{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'}) {
            decodeHexArray[b] = (byte) i++;
        }
        decodeHexArray['a'] = decodeHexArray['A'];
        decodeHexArray['b'] = decodeHexArray['B'];
        decodeHexArray['c'] = decodeHexArray['C'];
        decodeHexArray['d'] = decodeHexArray['D'];
        decodeHexArray['e'] = decodeHexArray['E'];
        decodeHexArray['f'] = decodeHexArray['F'];
    }




    public static void appendQueryFields(StringBuffer buf, Map fields) {

        List fieldNames = new ArrayList(fields.keySet());
        Iterator itr = fieldNames.iterator();
        while (itr.hasNext()) {
            String fieldName = (String) itr.next();
            String fieldValue = (String) fields.get(fieldName);
            if ((fieldValue != null) && (fieldValue.length() > 0)) {
                // append the URL parameters
                buf.append(URLEncoder.encode(fieldName));
                buf.append('=');
                buf.append(URLEncoder.encode(fieldValue));
            }
            if (itr.hasNext()) {
                buf.append('&');
            }

        }

    }

    public static String getResponseDescription(String vResponseCode) {
        Map<String, String> map_result = new HashMap<String, String>() {
            {
                put("0", "Giao dịch thành công");
                put("1", "Ngân hàng từ chối giao dịch");
                put("3", "Mã đơn vị không tồn tại");
                put("4", "Không đúng access code");
                put("5", "Số tiền không hợp lệ");
                put("6", "Mã tiền tệ không tồn tại");
                put("7", "Lỗi không xác định");
                put("8", "Số thẻ không đúng");
                put("9", "Tên chủ thẻ không đúng");
                put("10", "Thẻ hết hạn/Thẻ bị khóa");
                put("11", "Thẻ chưa đăng ký sử dụng dịch vụ");
                put("12", "Ngày phát hành/Hết hạn không đúng");
                put("13", "Vượt quá hạn mức thanh toán");
                put("21", "Số tiền không đủ để thanh toán");
                put("22", "Giao dịch không thành công. Thông tin tài khoản không đúng. Vui lòng kiểm tra và thực hiện thanh toán lại");
                put("23", "Giao dịch không thành công. Tài khoản bị khóa.Vui lòng liên hê ngân hàng theo số điện thoại sau mặt thẻ để được hỗ trợ");
                put("24", "Giao dịch không thành công. Thông tin thẻ không đúng. Vui lòng kiểm tra và thực hiện thanh toán lại");
                put("25", "Giao dịch không thành công. OTP không đúng.Vui lòng kiểm tra và thực hiện thanh toán lạ");
                put("253", "Giao dịch không thành công. Quá thời gian thanh toán. Vui lòng thực hiện thanh toán lại");
                put("99", "Giao dịch không thành công. Người sử dụng hủy giao dịch");
                put("B", "Giao dịch không thành công do không xác thực được 3D-Secure. Vui lòng liên hệ ngân hàng theo số điện thoại sau mặt thẻ được hỗ trợ chi tiết.");
                put("E", "Giao dịch không thành công do nhập sai CSC (Card Security Card) hoặc ngân hàng từ chối cấp phép cho giao dịch. Vui lòng liên hệ ngân hàng theo số điện thoại sau mặt thẻ được hỗ trợ chi tiết.");
                put("F", "Giao dịch không thành công do không xác thực được 3D-Secure. Vui lòng liên hệ ngân hàng theo số điện thoại sau mặt thẻ được hỗ trợ chi tiết.");
                put("Z", "Giao dịch của bạn bị từ chối. Vui lòng liên hệ Đơn vị chấp nhận thẻ để được hỗ trợ.");
            }
        };
        String result = "";
        result = map_result.get(vResponseCode);
        if (result != null) return result;
        else return "No Value Returned";
    }

    public static String null2unknown(String in) {
        if (in == null || in.length() == 0) {
            return "No Value Returned";
        } else {
            return in;
        }
    }
}
