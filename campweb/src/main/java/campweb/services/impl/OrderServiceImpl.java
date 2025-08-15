package campweb.services.impl;

import java.util.List;
import java.util.UUID;
import java.util.ArrayList;

import org.springframework.beans.factory.annotation.Autowired;

import campweb.entities.TicketEntity;
import campweb.model.SeatSelection;
import campweb.repositories.TicketRepository;

import campweb.repositories.OrderRepository;
import campweb.services.OrderService;
import campweb.entities.OrderEntity;
import campweb.payload.OrderRequest;

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
        Long totalAmount = 0L;

        OrderEntity orderEntity = new OrderEntity();
        orderEntity.setCustomerName(orderRequest.getCustomerName());
        orderEntity.setCustomerEmail(orderRequest.getCustomerEmail());
        orderEntity.setTotalAmount(totalAmount);
        orderEntity = orderRepository.save(orderEntity);

        List<SeatSelection> seatSelections = orderRequest.getSeatSelections();

        List<TicketEntity> newTickets = new ArrayList<>();

        for (SeatSelection seatSelection : seatSelections) {
            TicketEntity ticketEntity = new TicketEntity();
            ticketEntity.setName(orderEntity.getCustomerName());
            ticketEntity.setEmail(orderEntity.getCustomerEmail());
            ticketEntity.setOrder(orderEntity);
            ticketEntity.setZoneEntity(seatSelection.getZoneId());
            newTickets.add(ticketEntity);
        }

        ticketRepository.saveAll(newTickets);

        return orderEntity;
    }
}
 