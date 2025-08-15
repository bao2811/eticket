package campweb.services.impl;

import org.springframework.beans.factory.annotation.Autowired;

import campweb.payload.CheckoutResponse;
import campweb.services.CheckoutService;
import jakarta.servlet.http.HttpServletRequest;
import campweb.entities.OrderEntity;

public class CheckoutServiceImpl implements CheckoutService {
    private final HttpServletRequest request;

    @Autowired
    public CheckoutServiceImpl(HttpServletRequest request) {
        this.request = request;
    }

    @Override
    public CheckoutResponse getCheckout(OrderEntity orderEntity) {
        CheckoutResponse response = new CheckoutResponse();
        return response;
    }
}
