-- =====================================================
-- FILE: 04-order-service-schema.sql
-- DATABASE: eticket_orders
-- SERVICE: Order Service
-- PURPOSE: Order Management, Tickets
-- =====================================================

USE eticket_orders;

-- Drop tables if exist (for clean reinstall)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS order_outbox_events;
DROP TABLE IF EXISTS order_status_history;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS saga_instances;
SET FOREIGN_KEY_CHECKS = 1;

-- ─────────────────────────────────────────────────────
-- Table: orders
-- Main order entity
-- ─────────────────────────────────────────────────────
CREATE TABLE orders (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    order_number    VARCHAR(20) NOT NULL UNIQUE COMMENT 'Human readable: ORD-YYYYMMDD-XXX',
    
    -- Customer info (denormalized from User Service)
    user_id         VARCHAR(36) COMMENT 'Reference to User Service, NULL for guest',
    customer_name   VARCHAR(100) NOT NULL COMMENT 'Customer full name',
    customer_email  VARCHAR(100) NOT NULL COMMENT 'Customer email',
    customer_phone  VARCHAR(20) COMMENT 'Customer phone',
    
    -- Event info (denormalized from Event Service - SNAPSHOT at order time)
    event_id        VARCHAR(36) NOT NULL COMMENT 'Reference to Event Service',
    event_name      VARCHAR(255) NOT NULL COMMENT 'Event name at order time',
    event_date      TIMESTAMP NOT NULL COMMENT 'Event start date',
    event_end_date  TIMESTAMP COMMENT 'Event end date',
    venue_name      VARCHAR(255) COMMENT 'Venue name',
    venue_address   TEXT COMMENT 'Venue address',
    
    -- Pricing breakdown
    subtotal        BIGINT NOT NULL DEFAULT 0 COMMENT 'Sum of line items (VND)',
    discount_amount BIGINT NOT NULL DEFAULT 0 COMMENT 'Total discounts',
    service_fee     BIGINT NOT NULL DEFAULT 0 COMMENT 'Service/booking fee',
    tax_amount      BIGINT NOT NULL DEFAULT 0 COMMENT 'Tax if applicable',
    total_amount    BIGINT NOT NULL DEFAULT 0 COMMENT 'Final amount to pay',
    currency        VARCHAR(3) NOT NULL DEFAULT 'VND',
    
    -- Coupon/Promotion
    coupon_id       VARCHAR(36) COMMENT 'Applied coupon ID',
    coupon_code     VARCHAR(50) COMMENT 'Coupon code used',
    coupon_discount BIGINT NOT NULL DEFAULT 0 COMMENT 'Discount from coupon',
    
    -- Order Status
    status          ENUM(
                        'PENDING',              -- Waiting for payment
                        'PAYMENT_PROCESSING',   -- Payment in progress
                        'PAID',                 -- Payment received
                        'CONFIRMING',           -- Confirming with event service
                        'CONFIRMED',            -- Order confirmed, tickets issued
                        'PARTIALLY_REFUNDED',   -- Some tickets refunded
                        'REFUNDED',             -- Full refund
                        'CANCELLED',            -- Order cancelled
                        'EXPIRED',              -- Payment timeout
                        'FAILED'                -- Order failed
                    ) NOT NULL DEFAULT 'PENDING',
    
    status_reason   TEXT COMMENT 'Reason for current status',
    
    -- Payment info
    payment_method  VARCHAR(50) COMMENT 'ONEPAY, VNPAY, MOMO, etc.',
    payment_id      VARCHAR(36) COMMENT 'Reference to Payment Service',
    payment_url     VARCHAR(1000) COMMENT 'Redirect URL for payment',
    paid_at         TIMESTAMP NULL COMMENT 'When payment was received',
    
    -- Ticket summary
    total_tickets   INT NOT NULL DEFAULT 0 COMMENT 'Total ticket count',
    
    -- Time constraints
    expires_at      TIMESTAMP COMMENT 'Payment deadline',
    
    -- Saga state (for distributed transaction management)
    saga_id         VARCHAR(36) COMMENT 'Saga instance ID',
    saga_state      VARCHAR(50) COMMENT 'Current saga state',
    saga_step       INT DEFAULT 0 COMMENT 'Current saga step',
    
    -- Source tracking
    source          VARCHAR(50) DEFAULT 'WEB' COMMENT 'WEB, MOBILE_APP, API',
    ip_address      VARCHAR(45) COMMENT 'Customer IP address',
    user_agent      VARCHAR(500) COMMENT 'Browser user agent',
    
    -- Notes
    customer_notes  TEXT COMMENT 'Notes from customer',
    admin_notes     TEXT COMMENT 'Internal admin notes',
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    confirmed_at    TIMESTAMP NULL,
    cancelled_at    TIMESTAMP NULL,
    
    -- Indexes
    INDEX idx_order_number (order_number),
    INDEX idx_user (user_id),
    INDEX idx_event (event_id),
    INDEX idx_status (status),
    INDEX idx_email (customer_email),
    INDEX idx_created (created_at),
    INDEX idx_expires (expires_at, status),
    INDEX idx_payment (payment_id),
    INDEX idx_event_date (event_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Main order entity';

-- ─────────────────────────────────────────────────────
-- Table: order_items
-- Line items in an order (one per zone)
-- ─────────────────────────────────────────────────────
CREATE TABLE order_items (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    order_id        VARCHAR(36) NOT NULL COMMENT 'FK to orders',
    
    -- Zone info (denormalized from Event Service - SNAPSHOT)
    zone_id         VARCHAR(36) NOT NULL COMMENT 'Reference to Event Service',
    zone_name       VARCHAR(100) NOT NULL COMMENT 'Zone name at order time',
    zone_color      VARCHAR(7) COMMENT 'Zone color for display',
    
    -- Pricing at time of order
    unit_price      BIGINT NOT NULL COMMENT 'Price per ticket (VND)',
    quantity        INT NOT NULL DEFAULT 1 COMMENT 'Number of tickets',
    subtotal        BIGINT NOT NULL COMMENT 'unit_price * quantity',
    
    -- For numbered seating: linked seats
    -- Seats are stored in tickets table
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_order (order_id),
    INDEX idx_zone (zone_id),
    
    -- Foreign Key
    CONSTRAINT fk_item_order 
        FOREIGN KEY (order_id) REFERENCES orders(id) 
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Order line items';

-- ─────────────────────────────────────────────────────
-- Table: tickets
-- Individual tickets generated from order
-- ─────────────────────────────────────────────────────
CREATE TABLE tickets (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    ticket_number   VARCHAR(30) NOT NULL UNIQUE COMMENT 'TKT-YYYYMMDD-XXXXXX',
    
    -- Order link
    order_id        VARCHAR(36) NOT NULL COMMENT 'FK to orders',
    order_item_id   VARCHAR(36) NOT NULL COMMENT 'FK to order_items',
    
    -- Event info (denormalized - SNAPSHOT)
    event_id        VARCHAR(36) NOT NULL,
    event_name      VARCHAR(255) NOT NULL,
    event_date      TIMESTAMP NOT NULL,
    venue_name      VARCHAR(255),
    venue_address   TEXT,
    
    -- Zone info (denormalized - SNAPSHOT)
    zone_id         VARCHAR(36) NOT NULL,
    zone_name       VARCHAR(100) NOT NULL,
    
    -- Seat info (for numbered seating)
    seat_id         VARCHAR(36) COMMENT 'Reference to Event Service seats',
    seat_label      VARCHAR(20) COMMENT 'e.g., A-12, B-5',
    row_name        VARCHAR(10) COMMENT 'Row identifier',
    seat_number     INT COMMENT 'Seat number in row',
    
    -- Ticket holder (can be different from purchaser)
    holder_name     VARCHAR(100) COMMENT 'Ticket holder name',
    holder_email    VARCHAR(100) COMMENT 'Ticket holder email',
    holder_phone    VARCHAR(20) COMMENT 'Ticket holder phone',
    holder_id_number VARCHAR(20) COMMENT 'ID/Passport number if required',
    
    -- Pricing
    price           BIGINT NOT NULL COMMENT 'Ticket price (VND)',
    
    -- QR Code & Validation
    qr_code         VARCHAR(255) NOT NULL UNIQUE COMMENT 'Unique QR code data',
    qr_code_url     VARCHAR(500) COMMENT 'QR code image URL',
    barcode         VARCHAR(50) COMMENT 'Barcode if needed',
    secret_code     VARCHAR(10) COMMENT 'Additional verification code',
    
    -- Ticket Status
    status          ENUM(
                        'PENDING',      -- Waiting for order confirmation
                        'ACTIVE',       -- Valid, ready to use
                        'USED',         -- Already checked in
                        'CANCELLED',    -- Cancelled/Refunded
                        'EXPIRED',      -- Event has passed
                        'TRANSFERRED'   -- Transferred to another person
                    ) NOT NULL DEFAULT 'PENDING',
    
    -- Check-in info
    checked_in_at   TIMESTAMP NULL COMMENT 'Check-in timestamp',
    checked_in_by   VARCHAR(36) COMMENT 'Staff user ID who checked in',
    check_in_gate   VARCHAR(50) COMMENT 'Gate/entrance used',
    check_in_device VARCHAR(100) COMMENT 'Device used for check-in',
    check_in_notes  TEXT COMMENT 'Notes during check-in',
    
    -- Transfer info
    transferred_at      TIMESTAMP NULL,
    transferred_from    VARCHAR(36) COMMENT 'Original ticket ID',
    original_holder     VARCHAR(100) COMMENT 'Original holder name',
    
    -- PDF ticket
    pdf_url         VARCHAR(500) COMMENT 'PDF ticket download URL',
    pdf_generated_at TIMESTAMP NULL,
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    activated_at    TIMESTAMP NULL COMMENT 'When ticket became active',
    
    -- Indexes
    INDEX idx_ticket_number (ticket_number),
    INDEX idx_order (order_id),
    INDEX idx_order_item (order_item_id),
    INDEX idx_event (event_id),
    INDEX idx_qr (qr_code),
    INDEX idx_status (status),
    INDEX idx_seat (seat_id),
    INDEX idx_holder_email (holder_email),
    INDEX idx_event_status (event_id, status),
    INDEX idx_check_in (event_id, checked_in_at),
    
    -- Foreign Keys
    CONSTRAINT fk_ticket_order 
        FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_ticket_order_item 
        FOREIGN KEY (order_item_id) REFERENCES order_items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Individual tickets';

-- ─────────────────────────────────────────────────────
-- Table: order_status_history
-- Track all status changes
-- ─────────────────────────────────────────────────────
CREATE TABLE order_status_history (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id        VARCHAR(36) NOT NULL COMMENT 'FK to orders',
    
    -- Status change
    from_status     VARCHAR(30) COMMENT 'Previous status',
    to_status       VARCHAR(30) NOT NULL COMMENT 'New status',
    reason          TEXT COMMENT 'Reason for change',
    
    -- Who made the change
    changed_by      VARCHAR(36) COMMENT 'User ID or SYSTEM',
    changed_by_type ENUM('SYSTEM', 'USER', 'ADMIN', 'PAYMENT_CALLBACK') DEFAULT 'SYSTEM',
    
    -- Additional context
    metadata        JSON COMMENT 'Additional info about the change',
    
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_order (order_id),
    INDEX idx_status (to_status),
    INDEX idx_created (created_at),
    
    CONSTRAINT fk_history_order 
        FOREIGN KEY (order_id) REFERENCES orders(id) 
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Order status change history';

-- ─────────────────────────────────────────────────────
-- Table: saga_instances
-- Track saga executions for distributed transactions
-- ─────────────────────────────────────────────────────
CREATE TABLE saga_instances (
    id              VARCHAR(36) PRIMARY KEY,
    saga_type       VARCHAR(50) NOT NULL COMMENT 'OrderCreationSaga, RefundSaga, etc.',
    
    -- Related entity
    order_id        VARCHAR(36) NOT NULL,
    
    -- State
    current_step    VARCHAR(50) NOT NULL,
    state_data      JSON NOT NULL COMMENT 'Full saga state',
    
    -- Status
    status          ENUM('RUNNING', 'COMPLETED', 'COMPENSATING', 'FAILED') DEFAULT 'RUNNING',
    
    -- Error handling
    last_error      TEXT,
    retry_count     INT DEFAULT 0,
    next_retry_at   TIMESTAMP NULL,
    
    -- Timestamps
    started_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at    TIMESTAMP NULL,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_order (order_id),
    INDEX idx_status (status),
    INDEX idx_retry (status, next_retry_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Saga instance tracking';

-- ─────────────────────────────────────────────────────
-- Table: order_outbox_events
-- Outbox pattern for reliable event publishing
-- ─────────────────────────────────────────────────────
CREATE TABLE order_outbox_events (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    -- Aggregate info
    aggregate_id    VARCHAR(36) NOT NULL,
    aggregate_type  VARCHAR(50) NOT NULL DEFAULT 'Order',
    
    -- Event info
    event_type      VARCHAR(100) NOT NULL,
    event_version   INT NOT NULL DEFAULT 1,
    payload         JSON NOT NULL,
    metadata        JSON,
    
    -- Publishing status
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP NULL,
    publish_attempts INT NOT NULL DEFAULT 0,
    last_error      TEXT,
    
    INDEX idx_unpublished (published_at, created_at),
    INDEX idx_aggregate (aggregate_type, aggregate_id),
    INDEX idx_event_type (event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Outbox for Order Service domain events';
