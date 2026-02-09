package campweb.services;

import campweb.entities.OrderEntity;
import campweb.payload.CheckoutResponse;
import org.springframework.stereotype.Service;

@Service
public interface CheckoutService {
    CheckoutResponse getCheckout(OrderEntity orderEntity);
}
