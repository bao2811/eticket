package campweb.services;

import java.util.UUID;
import campweb.entities.OrderEntity;
import campweb.payload.OrderRequest;

public interface OrderService {
    OrderEntity getOrder(UUID orderId);
    OrderEntity createOrder(OrderRequest orderRequest);
}
