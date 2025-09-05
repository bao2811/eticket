package campweb.services;

import campweb.entities.OrderEntity;
import campweb.payload.CheckoutResponse;


public interface CheckoutService {
    CheckoutResponse getCheckout(OrderEntity orderEntity);
}
