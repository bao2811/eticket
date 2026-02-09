# 📊 Data Flow & Synchronization Guide

## Tổng quan

Trong kiến trúc microservices, mỗi service có database riêng và **KHÔNG** truy cập trực tiếp database của service khác. Thay vào đó, data được đồng bộ qua **Events** (RabbitMQ).

---

## 1. Mapping Entities cũ → Services mới

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MONOLITH → MICROSERVICES MAPPING                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  MONOLITH (campweb)                    MICROSERVICES                        │
│  ─────────────────                     ────────────────                      │
│                                                                              │
│  UserEntity                     →      User Service                         │
│  ├── id                                ├── eticket_users.users              │
│  ├── username                          │   ├── id (UUID)                    │
│  ├── password                          │   ├── username                     │
│  ├── email                             │   ├── password_hash                │
│  ├── phoneNumber                       │   ├── email                        │
│  └── address                           │   ├── phone_number                 │
│                                        │   ├── status                       │
│                                        │   └── role                         │
│                                        └── eticket_users.refresh_tokens     │
│                                                                              │
│  EventEntity                    →      Event Service                        │
│  ├── id                                ├── eticket_events.events            │
│  ├── name                              │   ├── id (UUID)                    │
│  ├── location                          │   ├── name                         │
│  ├── image                             │   ├── venue_name                   │
│  ├── status                            │   ├── banner_url                   │
│  ├── type                              │   ├── status                       │
│  ├── maxBuy                            │   ├── category_id                  │
│  ├── startedDate                       │   ├── max_tickets_per_order        │
│  ├── address                           │   ├── start_date                   │
│  └── description                       │   └── description                  │
│                                        └── eticket_events.categories        │
│                                                                              │
│  ZoneEntity                     →      Event Service                        │
│  ├── id                                └── eticket_events.zones             │
│  ├── name                                  ├── id (UUID)                    │
│  ├── price                                 ├── name                         │
│  ├── status                                ├── price                        │
│  ├── points                                ├── is_active                    │
│  ├── color                                 ├── seat_map_data                │
│  ├── quantity                              ├── color                        │
│  ├── bought                                ├── total_quantity               │
│  └── event_id (FK)                         ├── sold_quantity                │
│                                            └── event_id (FK)                │
│                                                                              │
│  SeatEntity                     →      Event Service                        │
│  ├── id                                └── eticket_events.seats             │
│  ├── name                                  ├── id (UUID)                    │
│  ├── eventId                               ├── seat_label                   │
│  ├── location                              ├── event_id                     │
│  ├── type                                  ├── pos_x, pos_y                 │
│  └── status                                ├── seat_type                    │
│                                            └── status                       │
│                                                                              │
│  OrderEntity                    →      Order Service                        │
│  ├── id                                ├── eticket_orders.orders            │
│  ├── customerName                      │   ├── id (UUID)                    │
│  ├── customerEmail                     │   ├── customer_name                │
│  ├── orderTime                         │   ├── customer_email               │
│  ├── totalAmount                       │   ├── created_at                   │
│  ├── status                            │   ├── total_amount                 │
│  ├── paymentUrl                        │   ├── status                       │
│  └── tickets (OneToMany)               │   └── payment_url                  │
│                                        ├── eticket_orders.order_items       │
│                                        └── eticket_orders.tickets           │
│                                                                              │
│  TicketEntity                   →      Order Service                        │
│  ├── id                                └── eticket_orders.tickets           │
│  ├── name                                  ├── id (UUID)                    │
│  ├── email                                 ├── holder_name                  │
│  ├── zone_id                               ├── holder_email                 │
│  ├── event_id                              ├── zone_id (reference)          │
│  ├── seatNumber                            ├── event_id (reference)         │
│  ├── seatId                                ├── seat_label                   │
│  └── order_id (FK)                         ├── seat_id (reference)          │
│                                            └── order_id (FK)                │
│                                                                              │
│  (NEW) Payment                  →      Payment Service                      │
│                                        ├── eticket_payments.payments        │
│                                        ├── eticket_payments.refunds         │
│                                        └── eticket_payments.transaction_logs│
│                                                                              │
│  (NEW) Notification             →      Notification Service                 │
│                                        ├── eticket_notifications.templates  │
│                                        └── eticket_notifications.notifications│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Cross-Service References

### ❌ Cách cũ (Monolith) - Foreign Keys

```sql
-- Monolith: Direct FK references
CREATE TABLE tickets (
    order_id INT REFERENCES orders(id),      -- Direct FK
    event_id INT REFERENCES events(id),      -- Direct FK
    zone_id INT REFERENCES zones(id)         -- Direct FK
);
```

### ✅ Cách mới (Microservices) - Reference by ID + Denormalization

```sql
-- Microservices: Store reference ID + denormalized data
CREATE TABLE tickets (
    order_id VARCHAR(36) NOT NULL,           -- Reference ID only (local FK OK)

    -- Event data (denormalized - SNAPSHOT at order time)
    event_id VARCHAR(36) NOT NULL,           -- Reference ID (no FK)
    event_name VARCHAR(255) NOT NULL,        -- Denormalized
    event_date TIMESTAMP NOT NULL,           -- Denormalized

    -- Zone data (denormalized)
    zone_id VARCHAR(36) NOT NULL,            -- Reference ID (no FK)
    zone_name VARCHAR(100) NOT NULL,         -- Denormalized

    -- Seat data
    seat_id VARCHAR(36),                     -- Reference ID (no FK)
    seat_label VARCHAR(20)                   -- Denormalized
);
```

---

## 3. Event-Driven Data Sync

### 3.1 Domain Events

| Service             | Event Type            | Payload                        | Consumers                    |
| ------------------- | --------------------- | ------------------------------ | ---------------------------- |
| **User Service**    | `UserCreated`         | {id, email, name}              | Notification                 |
| **User Service**    | `UserUpdated`         | {id, fields_changed}           | Search Indexer               |
| **Event Service**   | `EventCreated`        | {id, name, date, venue, zones} | Search Indexer               |
| **Event Service**   | `EventPublished`      | {id, name}                     | Notification                 |
| **Event Service**   | `SeatsReserved`       | {event_id, seat_ids, order_id} | Order Service                |
| **Event Service**   | `SeatsReleased`       | {event_id, seat_ids}           | Order Service                |
| **Event Service**   | `ZoneCapacityUpdated` | {zone_id, available}           | Search Indexer               |
| **Order Service**   | `OrderCreated`        | {id, event_id, seats, amount}  | Event, Payment               |
| **Order Service**   | `OrderConfirmed`      | {id, tickets}                  | Notification                 |
| **Order Service**   | `OrderCancelled`      | {id, reason}                   | Event, Payment, Notification |
| **Payment Service** | `PaymentSucceeded`    | {order_id, amount, txn_id}     | Order Service                |
| **Payment Service** | `PaymentFailed`       | {order_id, reason}             | Order Service                |
| **Payment Service** | `RefundCompleted`     | {order_id, amount}             | Order, Notification          |

### 3.2 Event Flow Example: Order Creation

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ORDER CREATION FLOW                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. User clicks "Buy Tickets"                                                │
│     │                                                                        │
│     ▼                                                                        │
│  ┌─────────────────┐                                                        │
│  │  Order Service  │ ─── Create Order (PENDING) ───→ DB: eticket_orders     │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│           │ Publish: OrderCreatedEvent                                       │
│           │ {order_id, event_id, zone_id, seat_ids, quantity}                │
│           ▼                                                                  │
│  ┌─────────────────┐                                                        │
│  │    RabbitMQ     │                                                        │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│           ▼                                                                  │
│  ┌─────────────────┐                                                        │
│  │  Event Service  │ ─── Reserve Seats ───→ DB: eticket_events              │
│  │                 │     (Update status = RESERVED)                          │
│  │                 │     (Lock for 15 minutes)                               │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│           │ Publish: SeatsReservedEvent                                      │
│           │ {order_id, seat_ids, lock_expires_at}                            │
│           ▼                                                                  │
│  ┌─────────────────┐                                                        │
│  │    RabbitMQ     │                                                        │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│           ▼                                                                  │
│  ┌─────────────────┐                                                        │
│  │  Order Service  │ ─── Update Order ───→ Create Payment Request           │
│  │                 │     (seats_reserved = true)                             │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│           │ Call: Payment Service (Sync or Async)                            │
│           ▼                                                                  │
│  ┌─────────────────┐                                                        │
│  │ Payment Service │ ─── Create Payment ───→ DB: eticket_payments           │
│  │                 │     Call OnePay/VNPay API                               │
│  │                 │     Return payment_url                                  │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│           │ Return: payment_url to Order Service                             │
│           ▼                                                                  │
│  ┌─────────────────┐                                                        │
│  │  Order Service  │ ─── Update Order ───→ status = PAYMENT_PROCESSING      │
│  │                 │     Return payment_url to Frontend                      │
│  └─────────────────┘                                                        │
│                                                                              │
│  2. User completes payment on gateway                                        │
│     │                                                                        │
│     ▼                                                                        │
│  ┌─────────────────┐                                                        │
│  │ Payment Gateway │ ─── IPN Callback ───→ Payment Service                  │
│  └─────────────────┘                                                        │
│                                                                              │
│  ┌─────────────────┐                                                        │
│  │ Payment Service │ ─── Update Payment ───→ status = SUCCESS               │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│           │ Publish: PaymentSucceededEvent                                   │
│           │ {order_id, payment_id, amount, txn_id}                           │
│           ▼                                                                  │
│  ┌─────────────────┐                                                        │
│  │    RabbitMQ     │                                                        │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│           ▼                                                                  │
│  ┌─────────────────┐                                                        │
│  │  Order Service  │ ─── Confirm Order ───→ status = CONFIRMED              │
│  │                 │     Generate Tickets                                    │
│  │                 │     Generate QR Codes                                   │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│           │ Publish: OrderConfirmedEvent                                     │
│           │ {order_id, tickets, customer_email}                              │
│           ▼                                                                  │
│  ┌─────────────────┐                                                        │
│  │    RabbitMQ     │                                                        │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│    ┌──────┴──────┐                                                          │
│    │             │                                                           │
│    ▼             ▼                                                           │
│  ┌──────────┐  ┌────────────────────┐                                       │
│  │  Event   │  │  Notification      │                                       │
│  │ Service  │  │  Service           │                                       │
│  │          │  │                    │                                       │
│  │ Confirm  │  │ Send confirmation  │                                       │
│  │ seats    │  │ email with         │                                       │
│  │ as SOLD  │  │ e-tickets          │                                       │
│  └──────────┘  └────────────────────┘                                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Data Consistency Strategies

### 4.1 Outbox Pattern (Guaranteed Delivery)

```java
@Transactional
public Order createOrder(CreateOrderRequest request) {
    // 1. Save order in local DB
    Order order = orderRepository.save(new Order(request));

    // 2. Save event to outbox table (SAME TRANSACTION)
    OutboxEvent event = new OutboxEvent(
        order.getId(),
        "OrderCreated",
        toJson(new OrderCreatedPayload(order))
    );
    outboxRepository.save(event);

    return order;
}

// Background job polls outbox and publishes to RabbitMQ
@Scheduled(fixedRate = 1000)
public void publishOutboxEvents() {
    List<OutboxEvent> events = outboxRepository.findUnpublished();
    for (OutboxEvent event : events) {
        try {
            rabbitTemplate.convertAndSend(event.getEventType(), event.getPayload());
            event.setPublishedAt(Instant.now());
            outboxRepository.save(event);
        } catch (Exception e) {
            event.incrementRetryCount();
            event.setLastError(e.getMessage());
            outboxRepository.save(event);
        }
    }
}
```

### 4.2 Saga Pattern (Distributed Transaction)

```java
// Saga Orchestrator in Order Service
public class OrderCreationSaga {

    public void execute(CreateOrderCommand cmd) {
        // Step 1: Create Order
        Order order = orderService.createOrder(cmd);
        sagaState.setStep("ORDER_CREATED");

        try {
            // Step 2: Reserve Seats (via event)
            eventPublisher.publish(new ReserveSeatsCommand(order.getSeats()));
            // Wait for SeatsReservedEvent

            // Step 3: Create Payment
            Payment payment = paymentService.createPayment(order);
            sagaState.setStep("PAYMENT_CREATED");

            // Wait for PaymentSucceededEvent

            // Step 4: Confirm Order
            orderService.confirmOrder(order.getId());
            sagaState.setStep("COMPLETED");

        } catch (SagaException e) {
            // Compensate: rollback previous steps
            compensate(sagaState);
        }
    }

    private void compensate(SagaState state) {
        switch (state.getStep()) {
            case "PAYMENT_CREATED":
                paymentService.cancelPayment(state.getPaymentId());
                // fall through
            case "SEATS_RESERVED":
                eventPublisher.publish(new ReleaseSeatsCommand(state.getSeatIds()));
                // fall through
            case "ORDER_CREATED":
                orderService.cancelOrder(state.getOrderId());
                break;
        }
    }
}
```

---

## 5. Data Migration Script

```sql
-- Script to migrate data from monolith to microservices
-- Run this AFTER creating new schema

-- 1. Migrate Users
INSERT INTO eticket_users.users (id, username, email, password_hash, phone_number, address, status, role, created_at)
SELECT
    UUID() as id,  -- Generate new UUID
    username,
    email,
    password as password_hash,
    phoneNumber as phone_number,
    address,
    'ACTIVE' as status,
    'USER' as role,
    NOW() as created_at
FROM campweb.users;  -- Old monolith table

-- 2. Migrate Events
INSERT INTO eticket_events.events (id, name, slug, description, venue_name, venue_address, start_date, banner_url, status, max_tickets_per_order, created_at)
SELECT
    UUID() as id,
    name,
    LOWER(REPLACE(name, ' ', '-')) as slug,
    description,
    location as venue_name,
    address as venue_address,
    startedDate as start_date,
    image as banner_url,
    CASE status
        WHEN 'ACTIVE' THEN 'PUBLISHED'
        ELSE status
    END as status,
    maxBuy as max_tickets_per_order,
    NOW() as created_at
FROM campweb.events;

-- 3. Migrate Zones (with UUID mapping)
-- Create temporary mapping table
CREATE TEMPORARY TABLE zone_id_mapping (
    old_id INT,
    new_id VARCHAR(36)
);

INSERT INTO zone_id_mapping (old_id, new_id)
SELECT id, UUID() FROM campweb.zones;

INSERT INTO eticket_events.zones (id, event_id, name, description, price, color, total_quantity, sold_quantity, created_at)
SELECT
    m.new_id as id,
    (SELECT new_id FROM event_id_mapping WHERE old_id = z.event_id) as event_id,
    z.name,
    '' as description,
    z.price,
    z.color,
    z.quantity as total_quantity,
    z.bought as sold_quantity,
    NOW() as created_at
FROM campweb.zones z
JOIN zone_id_mapping m ON z.id = m.old_id;

-- Similar for other tables...
```

---

## 6. Query Patterns

### 6.1 Joining Data Across Services (DON'T DO THIS)

```sql
-- ❌ WRONG: Cross-database join (NOT POSSIBLE in microservices)
SELECT o.*, e.name as event_name, u.email as user_email
FROM eticket_orders.orders o
JOIN eticket_events.events e ON o.event_id = e.id
JOIN eticket_users.users u ON o.user_id = u.id;
```

### 6.2 Correct Approach: Denormalization

```sql
-- ✅ CORRECT: Data already denormalized in Order Service
SELECT
    id,
    order_number,
    customer_name,
    customer_email,
    event_id,
    event_name,      -- Denormalized!
    event_date,      -- Denormalized!
    venue_name,      -- Denormalized!
    total_amount,
    status
FROM eticket_orders.orders
WHERE status = 'CONFIRMED';
```

### 6.3 API Composition (When Real-time Data Needed)

```java
// API Gateway or BFF composes data from multiple services
public OrderDetailResponse getOrderDetail(String orderId) {
    // 1. Get order from Order Service
    OrderDto order = orderServiceClient.getOrder(orderId);

    // 2. Get latest event info from Event Service (if needed)
    EventDto event = eventServiceClient.getEvent(order.getEventId());

    // 3. Get user profile from User Service (if needed)
    UserDto user = userServiceClient.getUser(order.getUserId());

    // 4. Compose response
    return OrderDetailResponse.builder()
        .order(order)
        .event(event)  // Latest event info
        .user(user)    // User profile
        .build();
}
```

---

## Tóm tắt

| Aspect                | Monolith            | Microservices                     |
| --------------------- | ------------------- | --------------------------------- |
| **Database**          | Single shared DB    | Database per service              |
| **FK References**     | Direct foreign keys | Reference by ID only              |
| **Joins**             | SQL JOINs           | Denormalization + API Composition |
| **Consistency**       | ACID transactions   | Eventual consistency (Saga)       |
| **Data Sync**         | N/A                 | Event-driven (RabbitMQ)           |
| **Query Performance** | JOIN queries        | Pre-denormalized data             |
