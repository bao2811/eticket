package campweb.services.impl;

import campweb.entities.OrderEntity;
import campweb.entities.TicketEntity;
import campweb.model.SeatSelection;
import campweb.payload.OrderRequest;
import campweb.repositories.OrderRepository;
import campweb.repositories.TicketRepository;
import campweb.services.OrderService;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class OrderServiceImpl implements OrderService {

    @Autowired
    private TicketRepository ticketRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Override
    public OrderEntity getOrder(UUID orderId) {
        return orderRepository.findById(orderId).orElseThrow(() -> new RuntimeException("Order not found"));
    }

    @Override
    public OrderEntity createOrder(OrderRequest orderRequest) {

        Map<String, List<Integer>> seats = orderRequest.getSeats();

        // Ví dụ duyệt qua từng hàng ghế, và lưu các

        Long totalAmount = 0L;

        OrderEntity orderEntity = new OrderEntity();
        orderEntity.setCustomerName(orderRequest.getCustomerName());
        orderEntity.setCustomerEmail(orderRequest.getCustomerEmail());
        orderEntity.setTotalAmount(totalAmount);
        orderEntity = orderRepository.save(orderEntity);
        
        List<TicketEntity> newTickets = new ArrayList<>();

        for (Map.Entry<String, List<Integer>> entry : seats.entrySet()) {
            String row = entry.getKey();             // "A", "B", "C"
            List<Integer> numbers = entry.getValue();// [1,2,3,...]
            
            // lưu hàng và só ghế vào ticketEntity và tính số tiền

            for (Integer number : numbers) {
                TicketEntity ticketEntity = new TicketEntity();
                ticketEntity.setName(orderEntity.getCustomerName());
                ticketEntity.setEmail(orderEntity.getCustomerEmail());
                ticketEntity.setOrder(orderEntity);
                newTickets.add(ticketEntity);
            }
        }

        // ticketRepository.saveAll(newTickets);

        return orderEntity;
        // trả về đối tượng orderEntity và danh sách ticketEntity...
    }
}
 