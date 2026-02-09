# 🗄️ Database Schema Design - Microservices

## 📋 Mục Lục

1. [Tổng Quan Phân Tách Database](#1-tổng-quan-phân-tách-database)
2. [Database Per Service](#2-database-per-service)
3. [Schema Chi Tiết Từng Service](#3-schema-chi-tiết-từng-service)
4. [Data Synchronization Strategy](#4-data-synchronization-strategy)
5. [SQL Scripts](#5-sql-scripts)

---

## 1. Tổng Quan Phân Tách Database

### 1.1 Monolith hiện tại → Microservices

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MONOLITH (Hiện tại)                                   │
│                                                                              │
│                      ┌─────────────────────┐                                │
│                      │   Single Database   │                                │
│                      │     (eticket)       │                                │
│                      ├─────────────────────┤                                │
│                      │  • users            │                                │
│                      │  • events           │                                │
│                      │  • zones            │                                │
│                      │  • seats            │                                │
│                      │  • orders           │                                │
│                      │  • tickets          │                                │
│                      └─────────────────────┘                                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Phân tách
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MICROSERVICES (Mới)                                   │
│                                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ user_db     │  │ event_db    │  │ order_db    │  │ payment_db  │        │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤  ├─────────────┤        │
│  │ • users     │  │ • events    │  │ • orders    │  │ • payments  │        │
│  │ • roles     │  │ • zones     │  │ • tickets   │  │ • refunds   │        │
│  │ • tokens    │  │ • seats     │  │ • order_    │  │ • txn_logs  │        │
│  │             │  │ • categories│  │   items     │  │             │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│         │                │                │                │                │
│         └────────────────┴────────────────┴────────────────┘                │
│                                   │                                          │
│                    ┌──────────────┴──────────────┐                          │
│                    │     Elasticsearch           │                          │
│                    │    (Read Model - CQRS)      │                          │
│                    ├─────────────────────────────┤                          │
│                    │  • users_index              │                          │
│                    │  • events_index             │                          │
│                    │  • orders_index             │                          │
│                    └─────────────────────────────┘                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Nguyên tắc phân tách

| Nguyên tắc                | Mô tả                                                     |
| ------------------------- | --------------------------------------------------------- |
| **Database per Service**  | Mỗi service có database riêng, không chia sẻ              |
| **No Direct DB Access**   | Service không truy cập trực tiếp DB của service khác      |
| **Event-Driven Sync**     | Đồng bộ data qua events (RabbitMQ)                        |
| **Eventually Consistent** | Chấp nhận eventual consistency thay vì strong consistency |
| **Reference by ID**       | Chỉ lưu ID tham chiếu, không lưu foreign key trực tiếp    |

---

## 2. Database Per Service

### 2.1 Mapping Service → Database

```
┌─────────────────────────────────────────────────────────────────┐
│                     SERVICE → DATABASE MAPPING                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────────────────┐  │
│  │   USER SERVICE   │ ──────→ │  Database: eticket_users     │  │
│  │                  │         │  Tables: users, roles,       │  │
│  │                  │         │          refresh_tokens      │  │
│  └──────────────────┘         └──────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────────────────┐  │
│  │  EVENT SERVICE   │ ──────→ │  Database: eticket_events    │  │
│  │                  │         │  Tables: events, zones,      │  │
│  │                  │         │          seats, categories   │  │
│  └──────────────────┘         └──────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────────────────┐  │
│  │  ORDER SERVICE   │ ──────→ │  Database: eticket_orders    │  │
│  │                  │         │  Tables: orders, tickets,    │  │
│  │                  │         │          order_items         │  │
│  └──────────────────┘         └──────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────────────────┐  │
│  │ PAYMENT SERVICE  │ ──────→ │  Database: eticket_payments  │  │
│  │                  │         │  Tables: payments, refunds,  │  │
│  │                  │         │          transaction_logs    │  │
│  └──────────────────┘         └──────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────────────────┐  │
│  │NOTIFICATION SVC  │ ──────→ │  Database: eticket_notif     │  │
│  │                  │         │  Tables: notifications,      │  │
│  │                  │         │          templates           │  │
│  └──────────────────┘         └──────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Ownership

| Entity     | Owner Service   | Referenced By              |
| ---------- | --------------- | -------------------------- |
| `users`    | User Service    | Order Service (user_id)    |
| `events`   | Event Service   | Order Service (event_id)   |
| `zones`    | Event Service   | Order Service (zone_id)    |
| `seats`    | Event Service   | Order Service (seat_id)    |
| `orders`   | Order Service   | Payment Service (order_id) |
| `tickets`  | Order Service   | -                          |
| `payments` | Payment Service | -                          |

---

## 3. Schema Chi Tiết Từng Service

### 3.1 USER SERVICE Database (`eticket_users`)

```sql
-- =====================================================
-- DATABASE: eticket_users
-- SERVICE: User Service
-- PURPOSE: Authentication, User Management
-- =====================================================

CREATE DATABASE IF NOT EXISTS eticket_users;
USE eticket_users;

-- ─────────────────────────────────────────────────────
-- Table: users
-- ─────────────────────────────────────────────────────
CREATE TABLE users (
    id              VARCHAR(36) PRIMARY KEY,
    username        VARCHAR(50) NOT NULL UNIQUE,
    email           VARCHAR(100) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    phone_number    VARCHAR(20),
    full_name       VARCHAR(100),
    avatar_url      VARCHAR(500),
    address         TEXT,

    -- Status & Role
    status          ENUM('ACTIVE', 'INACTIVE', 'BANNED', 'PENDING') DEFAULT 'PENDING',
    role            ENUM('USER', 'ADMIN', 'ORGANIZER') DEFAULT 'USER',
    email_verified  BOOLEAN DEFAULT FALSE,
    phone_verified  BOOLEAN DEFAULT FALSE,

    -- Audit fields
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at   TIMESTAMP NULL,

    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────
-- Table: refresh_tokens
-- ─────────────────────────────────────────────────────
CREATE TABLE refresh_tokens (
    id              VARCHAR(36) PRIMARY KEY,
    user_id         VARCHAR(36) NOT NULL,
    token           VARCHAR(500) NOT NULL UNIQUE,
    device_info     VARCHAR(255),
    ip_address      VARCHAR(45),
    expires_at      TIMESTAMP NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked_at      TIMESTAMP NULL,

    INDEX idx_user_id (user_id),
    INDEX idx_token (token),
    INDEX idx_expires (expires_at),

    CONSTRAINT fk_refresh_token_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────
-- Table: user_events (Outbox Pattern for Event Sourcing)
-- ─────────────────────────────────────────────────────
CREATE TABLE user_outbox_events (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    aggregate_id    VARCHAR(36) NOT NULL,
    event_type      VARCHAR(100) NOT NULL,
    payload         JSON NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP NULL,

    INDEX idx_unpublished (published_at),
    INDEX idx_aggregate (aggregate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3.2 EVENT SERVICE Database (`eticket_events`)

```sql
-- =====================================================
-- DATABASE: eticket_events
-- SERVICE: Event Service
-- PURPOSE: Event Management, Zones, Seats
-- =====================================================

CREATE DATABASE IF NOT EXISTS eticket_events;
USE eticket_events;

-- ─────────────────────────────────────────────────────
-- Table: categories
-- ─────────────────────────────────────────────────────
CREATE TABLE categories (
    id              VARCHAR(36) PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    slug            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    icon_url        VARCHAR(500),
    parent_id       VARCHAR(36),
    sort_order      INT DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_slug (slug),
    INDEX idx_parent (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────
-- Table: events
-- ─────────────────────────────────────────────────────
CREATE TABLE events (
    id              VARCHAR(36) PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,

    -- Organizer (reference to User Service)
    organizer_id    VARCHAR(36) NOT NULL,  -- Reference only, no FK
    organizer_name  VARCHAR(100),          -- Denormalized for read performance

    -- Category
    category_id     VARCHAR(36),

    -- Location
    venue_name      VARCHAR(255),
    address         TEXT,
    city            VARCHAR(100),
    latitude        DECIMAL(10, 8),
    longitude       DECIMAL(11, 8),

    -- Time
    start_date      TIMESTAMP NOT NULL,
    end_date        TIMESTAMP,
    doors_open_at   TIMESTAMP,

    -- Media
    banner_url      VARCHAR(500),
    thumbnail_url   VARCHAR(500),
    images          JSON,                  -- Array of image URLs

    -- Ticket info
    max_tickets_per_order   INT DEFAULT 10,
    total_capacity          INT DEFAULT 0,
    available_capacity      INT DEFAULT 0,
    min_price              BIGINT DEFAULT 0,
    max_price              BIGINT DEFAULT 0,

    -- Status
    status          ENUM('DRAFT', 'PUBLISHED', 'CANCELLED', 'COMPLETED', 'SOLDOUT') DEFAULT 'DRAFT',
    is_featured     BOOLEAN DEFAULT FALSE,

    -- SEO
    meta_title      VARCHAR(255),
    meta_description VARCHAR(500),

    -- Audit
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    published_at    TIMESTAMP NULL,

    INDEX idx_slug (slug),
    INDEX idx_status (status),
    INDEX idx_start_date (start_date),
    INDEX idx_category (category_id),
    INDEX idx_organizer (organizer_id),
    INDEX idx_city (city),
    INDEX idx_featured (is_featured, status),

    FULLTEXT INDEX ft_search (name, description, venue_name),

    CONSTRAINT fk_event_category
        FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────
-- Table: zones (Ticket zones within an event)
-- ─────────────────────────────────────────────────────
CREATE TABLE zones (
    id              VARCHAR(36) PRIMARY KEY,
    event_id        VARCHAR(36) NOT NULL,

    name            VARCHAR(100) NOT NULL,
    description     TEXT,
    color           VARCHAR(7),            -- Hex color (#FF5733)

    -- Pricing
    price           BIGINT NOT NULL,       -- Price in VND (smallest unit)
    original_price  BIGINT,                -- For showing discounts

    -- Capacity
    total_quantity  INT NOT NULL DEFAULT 0,
    sold_quantity   INT NOT NULL DEFAULT 0,
    reserved_quantity INT NOT NULL DEFAULT 0,

    -- Display
    sort_order      INT DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,

    -- Seat map (optional - for numbered seats)
    has_numbered_seats BOOLEAN DEFAULT FALSE,
    seat_map_config    JSON,               -- SVG path, coordinates, etc.

    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_event (event_id),
    INDEX idx_active (is_active),

    CONSTRAINT fk_zone_event
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────
-- Table: seats (Individual seats - for numbered seating)
-- ─────────────────────────────────────────────────────
CREATE TABLE seats (
    id              VARCHAR(36) PRIMARY KEY,
    zone_id         VARCHAR(36) NOT NULL,
    event_id        VARCHAR(36) NOT NULL,  -- Denormalized for faster queries

    -- Seat identification
    row_name        VARCHAR(10),           -- "A", "B", "C", etc.
    seat_number     INT,                   -- 1, 2, 3, etc.
    seat_label      VARCHAR(20),           -- "A-1", "B-12", etc.

    -- Position for seat map
    pos_x           DECIMAL(10, 2),
    pos_y           DECIMAL(10, 2),

    -- Status
    status          ENUM('AVAILABLE', 'RESERVED', 'SOLD', 'BLOCKED') DEFAULT 'AVAILABLE',

    -- Lock for reservation (distributed lock info)
    locked_by       VARCHAR(36),           -- Order ID that locked this seat
    locked_at       TIMESTAMP NULL,
    lock_expires_at TIMESTAMP NULL,

    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_zone (zone_id),
    INDEX idx_event (event_id),
    INDEX idx_status (status),
    INDEX idx_event_status (event_id, status),
    INDEX idx_locked (locked_by, lock_expires_at),

    UNIQUE INDEX uk_seat_position (zone_id, row_name, seat_number),

    CONSTRAINT fk_seat_zone
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE,
    CONSTRAINT fk_seat_event
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────
-- Table: event_outbox_events (Outbox Pattern)
-- ─────────────────────────────────────────────────────
CREATE TABLE event_outbox_events (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    aggregate_id    VARCHAR(36) NOT NULL,
    aggregate_type  VARCHAR(50) NOT NULL,  -- 'Event', 'Zone', 'Seat'
    event_type      VARCHAR(100) NOT NULL,
    payload         JSON NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP NULL,

    INDEX idx_unpublished (published_at),
    INDEX idx_aggregate (aggregate_type, aggregate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3.3 ORDER SERVICE Database (`eticket_orders`)

```sql
-- =====================================================
-- DATABASE: eticket_orders
-- SERVICE: Order Service
-- PURPOSE: Order Management, Tickets
-- =====================================================

CREATE DATABASE IF NOT EXISTS eticket_orders;
USE eticket_orders;

-- ─────────────────────────────────────────────────────
-- Table: orders
-- ─────────────────────────────────────────────────────
CREATE TABLE orders (
    id              VARCHAR(36) PRIMARY KEY,
    order_number    VARCHAR(20) NOT NULL UNIQUE,  -- Human readable: ORD-20260118-001

    -- Customer info (denormalized from User Service)
    user_id         VARCHAR(36),           -- NULL for guest checkout
    customer_name   VARCHAR(100) NOT NULL,
    customer_email  VARCHAR(100) NOT NULL,
    customer_phone  VARCHAR(20),

    -- Event info (denormalized from Event Service)
    event_id        VARCHAR(36) NOT NULL,
    event_name      VARCHAR(255) NOT NULL,
    event_date      TIMESTAMP NOT NULL,
    venue_name      VARCHAR(255),

    -- Pricing
    subtotal        BIGINT NOT NULL DEFAULT 0,
    discount_amount BIGINT NOT NULL DEFAULT 0,
    service_fee     BIGINT NOT NULL DEFAULT 0,
    total_amount    BIGINT NOT NULL DEFAULT 0,
    currency        VARCHAR(3) DEFAULT 'VND',

    -- Coupon/Promo
    coupon_code     VARCHAR(50),
    coupon_discount BIGINT DEFAULT 0,

    -- Status
    status          ENUM(
                        'PENDING',          -- Waiting for payment
                        'PAYMENT_PROCESSING', -- Payment in progress
                        'PAID',             -- Payment successful
                        'CONFIRMED',        -- Tickets confirmed
                        'CANCELLED',        -- Order cancelled
                        'REFUNDED',         -- Full refund
                        'PARTIALLY_REFUNDED', -- Partial refund
                        'EXPIRED'           -- Payment timeout
                    ) DEFAULT 'PENDING',

    -- Payment info
    payment_method  VARCHAR(50),           -- 'ONEPAY', 'VNPAY', 'MOMO', etc.
    payment_url     VARCHAR(1000),
    paid_at         TIMESTAMP NULL,

    -- Timestamps
    expires_at      TIMESTAMP,             -- Payment deadline
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Saga state
    saga_state      VARCHAR(50),
    saga_step       VARCHAR(50),

    INDEX idx_order_number (order_number),
    INDEX idx_user (user_id),
    INDEX idx_event (event_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at),
    INDEX idx_email (customer_email),
    INDEX idx_expires (expires_at, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────
-- Table: order_items (Line items in order)
-- ─────────────────────────────────────────────────────
CREATE TABLE order_items (
    id              VARCHAR(36) PRIMARY KEY,
    order_id        VARCHAR(36) NOT NULL,

    -- Zone info (denormalized from Event Service)
    zone_id         VARCHAR(36) NOT NULL,
    zone_name       VARCHAR(100) NOT NULL,

    -- Pricing at time of order
    unit_price      BIGINT NOT NULL,
    quantity        INT NOT NULL DEFAULT 1,
    subtotal        BIGINT NOT NULL,

    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_order (order_id),
    INDEX idx_zone (zone_id),

    CONSTRAINT fk_item_order
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────
-- Table: tickets (Generated tickets)
-- ─────────────────────────────────────────────────────
CREATE TABLE tickets (
    id              VARCHAR(36) PRIMARY KEY,
    ticket_number   VARCHAR(30) NOT NULL UNIQUE,  -- TKT-20260118-ABC123
    order_id        VARCHAR(36) NOT NULL,
    order_item_id   VARCHAR(36) NOT NULL,

    -- Event info (denormalized)
    event_id        VARCHAR(36) NOT NULL,
    event_name      VARCHAR(255) NOT NULL,
    event_date      TIMESTAMP NOT NULL,
    venue_name      VARCHAR(255),

    -- Zone & Seat info
    zone_id         VARCHAR(36) NOT NULL,
    zone_name       VARCHAR(100) NOT NULL,
    seat_id         VARCHAR(36),           -- NULL for general admission
    seat_label      VARCHAR(20),           -- "A-12" or NULL

    -- Ticket holder
    holder_name     VARCHAR(100),
    holder_email    VARCHAR(100),
    holder_phone    VARCHAR(20),

    -- Ticket details
    price           BIGINT NOT NULL,

    -- QR Code & Validation
    qr_code         VARCHAR(255) NOT NULL UNIQUE,
    barcode         VARCHAR(50),

    -- Status
    status          ENUM(
                        'PENDING',          -- Waiting for payment confirmation
                        'ACTIVE',           -- Valid ticket
                        'USED',             -- Already checked in
                        'CANCELLED',        -- Cancelled/Refunded
                        'EXPIRED'           -- Event passed
                    ) DEFAULT 'PENDING',

    -- Check-in
    checked_in_at   TIMESTAMP NULL,
    checked_in_by   VARCHAR(36),           -- Staff user ID
    check_in_gate   VARCHAR(50),

    -- Timestamps
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_ticket_number (ticket_number),
    INDEX idx_order (order_id),
    INDEX idx_event (event_id),
    INDEX idx_qr (qr_code),
    INDEX idx_status (status),
    INDEX idx_seat (seat_id),
    INDEX idx_holder_email (holder_email),

    CONSTRAINT fk_ticket_order
        FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_ticket_order_item
        FOREIGN KEY (order_item_id) REFERENCES order_items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────
-- Table: order_status_history
-- ─────────────────────────────────────────────────────
CREATE TABLE order_status_history (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id        VARCHAR(36) NOT NULL,
    from_status     VARCHAR(30),
    to_status       VARCHAR(30) NOT NULL,
    reason          TEXT,
    changed_by      VARCHAR(36),           -- User ID or 'SYSTEM'
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_order (order_id),

    CONSTRAINT fk_history_order
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────
-- Table: order_outbox_events (Outbox Pattern)
-- ─────────────────────────────────────────────────────
CREATE TABLE order_outbox_events (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    aggregate_id    VARCHAR(36) NOT NULL,
    aggregate_type  VARCHAR(50) NOT NULL,
    event_type      VARCHAR(100) NOT NULL,
    payload         JSON NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP NULL,

    INDEX idx_unpublished (published_at),
    INDEX idx_aggregate (aggregate_type, aggregate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3.4 PAYMENT SERVICE Database (`eticket_payments`)

```sql
-- =====================================================
-- DATABASE: eticket_payments
-- SERVICE: Payment Service
-- PURPOSE: Payment Processing, Transaction Logs
-- =====================================================

CREATE DATABASE IF NOT EXISTS eticket_payments;
USE eticket_payments;

-- ─────────────────────────────────────────────────────
-- Table: payments
-- ─────────────────────────────────────────────────────
CREATE TABLE payments (
    id              VARCHAR(36) PRIMARY KEY,
    payment_number  VARCHAR(30) NOT NULL UNIQUE,  -- PAY-20260118-001

    -- Order reference
    order_id        VARCHAR(36) NOT NULL UNIQUE,
    order_number    VARCHAR(20) NOT NULL,

    -- Customer
    user_id         VARCHAR(36),
    customer_email  VARCHAR(100) NOT NULL,

    -- Amount
    amount          BIGINT NOT NULL,
    currency        VARCHAR(3) DEFAULT 'VND',

    -- Payment Gateway
    gateway         ENUM('ONEPAY', 'VNPAY', 'MOMO', 'ZALOPAY', 'BANK_TRANSFER') NOT NULL,
    gateway_txn_id  VARCHAR(100),          -- Transaction ID from gateway
    gateway_response JSON,                  -- Full response from gateway

    -- Payment URL
    payment_url     VARCHAR(1000),
    return_url      VARCHAR(500),
    cancel_url      VARCHAR(500),
    ipn_url         VARCHAR(500),

    -- Status
    status          ENUM(
                        'PENDING',
                        'PROCESSING',
                        'SUCCESS',
                        'FAILED',
                        'CANCELLED',
                        'EXPIRED',
                        'REFUNDED',
                        'PARTIALLY_REFUNDED'
                    ) DEFAULT 'PENDING',

    failure_reason  TEXT,

    -- Timestamps
    expires_at      TIMESTAMP,
    paid_at         TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_payment_number (payment_number),
    INDEX idx_order (order_id),
    INDEX idx_gateway_txn (gateway_txn_id),
    INDEX idx_status (status),
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────
-- Table: refunds
-- ─────────────────────────────────────────────────────
CREATE TABLE refunds (
    id              VARCHAR(36) PRIMARY KEY,
    refund_number   VARCHAR(30) NOT NULL UNIQUE,
    payment_id      VARCHAR(36) NOT NULL,
    order_id        VARCHAR(36) NOT NULL,

    -- Amount
    amount          BIGINT NOT NULL,
    reason          TEXT,

    -- Gateway
    gateway_refund_id VARCHAR(100),
    gateway_response  JSON,

    -- Status
    status          ENUM('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED') DEFAULT 'PENDING',

    -- Processor
    requested_by    VARCHAR(36),           -- User ID
    processed_by    VARCHAR(36),           -- Admin ID

    -- Timestamps
    requested_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at    TIMESTAMP NULL,

    INDEX idx_payment (payment_id),
    INDEX idx_order (order_id),
    INDEX idx_status (status),

    CONSTRAINT fk_refund_payment
        FOREIGN KEY (payment_id) REFERENCES payments(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────
-- Table: transaction_logs (Audit trail)
-- ─────────────────────────────────────────────────────
CREATE TABLE transaction_logs (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_id      VARCHAR(36) NOT NULL,

    -- Log type
    log_type        ENUM('REQUEST', 'RESPONSE', 'CALLBACK', 'IPN', 'ERROR') NOT NULL,

    -- Details
    gateway         VARCHAR(20),
    endpoint        VARCHAR(255),
    method          VARCHAR(10),
    request_data    JSON,
    response_data   JSON,
    http_status     INT,

    -- IP & Headers
    ip_address      VARCHAR(45),
    user_agent      VARCHAR(500),

    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_payment (payment_id),
    INDEX idx_type (log_type),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────
-- Table: payment_outbox_events
-- ─────────────────────────────────────────────────────
CREATE TABLE payment_outbox_events (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    aggregate_id    VARCHAR(36) NOT NULL,
    event_type      VARCHAR(100) NOT NULL,
    payload         JSON NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP NULL,

    INDEX idx_unpublished (published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3.5 NOTIFICATION SERVICE Database (`eticket_notifications`)

```sql
-- =====================================================
-- DATABASE: eticket_notifications
-- SERVICE: Notification Service
-- PURPOSE: Notification logs, Templates
-- =====================================================

CREATE DATABASE IF NOT EXISTS eticket_notifications;
USE eticket_notifications;

-- ─────────────────────────────────────────────────────
-- Table: notification_templates
-- ─────────────────────────────────────────────────────
CREATE TABLE notification_templates (
    id              VARCHAR(36) PRIMARY KEY,
    code            VARCHAR(50) NOT NULL UNIQUE,
    name            VARCHAR(100) NOT NULL,

    -- Template type
    channel         ENUM('EMAIL', 'SMS', 'PUSH') NOT NULL,

    -- Content
    subject         VARCHAR(255),          -- For email
    body            TEXT NOT NULL,
    html_body       TEXT,                  -- For email HTML

    -- Variables
    variables       JSON,                  -- List of template variables

    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_code (code),
    INDEX idx_channel (channel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────
-- Table: notifications
-- ─────────────────────────────────────────────────────
CREATE TABLE notifications (
    id              VARCHAR(36) PRIMARY KEY,

    -- Recipient
    user_id         VARCHAR(36),
    recipient       VARCHAR(255) NOT NULL, -- Email, phone, or device token

    -- Type
    channel         ENUM('EMAIL', 'SMS', 'PUSH') NOT NULL,
    template_code   VARCHAR(50),

    -- Content
    subject         VARCHAR(255),
    body            TEXT NOT NULL,

    -- Context
    reference_type  VARCHAR(50),           -- 'ORDER', 'PAYMENT', 'EVENT'
    reference_id    VARCHAR(36),

    -- Status
    status          ENUM('PENDING', 'SENT', 'DELIVERED', 'FAILED', 'BOUNCED') DEFAULT 'PENDING',
    error_message   TEXT,

    -- Delivery info
    sent_at         TIMESTAMP NULL,
    delivered_at    TIMESTAMP NULL,
    opened_at       TIMESTAMP NULL,

    -- Retry
    retry_count     INT DEFAULT 0,
    next_retry_at   TIMESTAMP NULL,

    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_user (user_id),
    INDEX idx_recipient (recipient),
    INDEX idx_status (status),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_retry (status, next_retry_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 4. Data Synchronization Strategy

### 4.1 Event-Driven Data Sync

```
┌─────────────────────────────────────────────────────────────────────────────┐
│               DATA SYNCHRONIZATION FLOW (Eventual Consistency)               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────┐         ┌────────────┐         ┌────────────────────┐       │
│  │   Event    │ ──(1)─→ │  Outbox    │ ──(2)─→ │     RabbitMQ       │       │
│  │  Service   │  Save   │   Table    │ Publish │  (Message Broker)  │       │
│  │            │         │            │         │                    │       │
│  └────────────┘         └────────────┘         └─────────┬──────────┘       │
│                                                          │                   │
│                         ┌────────────────────────────────┼──────────────┐   │
│                         │                                │              │   │
│                         ▼                                ▼              ▼   │
│               ┌────────────────┐              ┌──────────────┐  ┌──────────┐│
│               │  Order Service │              │    Search    │  │  Other   ││
│               │                │              │   Indexer    │  │ Services ││
│               │ (3) Consume &  │              │              │  │          ││
│               │ Store event_id,│              │ (4) Index to │  │          ││
│               │ event_name     │              │ Elasticsearch│  │          ││
│               │ (denormalized) │              │              │  │          ││
│               └────────────────┘              └──────────────┘  └──────────┘│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

FLOW:
1. Event Service saves event + writes to outbox table (same transaction)
2. Outbox Publisher polls outbox table → publishes to RabbitMQ
3. Order Service consumes event → stores denormalized data (event_id, event_name)
4. Search Indexer consumes event → indexes to Elasticsearch
```

### 4.2 Denormalized Data trong Order Service

```sql
-- Order Service lưu trữ thông tin denormalized từ Event Service
-- Không cần JOIN, không cần call API

CREATE TABLE orders (
    id              VARCHAR(36) PRIMARY KEY,

    -- Reference ID (dùng để sync nếu cần)
    event_id        VARCHAR(36) NOT NULL,

    -- Denormalized data (snapshot tại thời điểm đặt hàng)
    event_name      VARCHAR(255) NOT NULL,
    event_date      TIMESTAMP NOT NULL,
    venue_name      VARCHAR(255),

    -- ... other fields
);

-- Khi Event được update, Order Service có thể:
-- 1. Giữ nguyên snapshot (recommended cho historical accuracy)
-- 2. Update denormalized data (nếu business yêu cầu)
```

### 4.3 Saga Pattern cho Distributed Transaction

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ORDER CREATION SAGA STEPS                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Step 1: CREATE ORDER (Order Service)                                        │
│  ├── Create order with status='PENDING'                                      │
│  ├── Publish: OrderCreatedEvent                                              │
│  └── Compensation: Delete order                                              │
│                                                                              │
│  Step 2: RESERVE SEATS (Event Service)                                       │
│  ├── Lock seats (distributed lock via Redis)                                 │
│  ├── Update seat status='RESERVED'                                           │
│  ├── Publish: SeatsReservedEvent                                             │
│  └── Compensation: Release seats, set status='AVAILABLE'                     │
│                                                                              │
│  Step 3: PROCESS PAYMENT (Payment Service)                                   │
│  ├── Create payment record                                                   │
│  ├── Call payment gateway                                                    │
│  ├── Wait for IPN callback                                                   │
│  ├── Publish: PaymentSuccessEvent / PaymentFailedEvent                       │
│  └── Compensation: Cancel payment (if supported)                             │
│                                                                              │
│  Step 4: CONFIRM ORDER (Order Service)                                       │
│  ├── Update order status='CONFIRMED'                                         │
│  ├── Generate tickets                                                        │
│  ├── Publish: OrderConfirmedEvent                                            │
│  └── No compensation (final step)                                            │
│                                                                              │
│  Step 5: SEND NOTIFICATION (Notification Service)                            │
│  ├── Send confirmation email                                                 │
│  ├── Send e-tickets                                                          │
│  └── No compensation (can retry)                                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

ROLLBACK SCENARIO:
If Step 3 (Payment) fails:
  → Compensate Step 2: Release seats
  → Compensate Step 1: Cancel order (status='CANCELLED')
```

---

## 5. SQL Scripts

### 5.1 Script khởi tạo tất cả databases

```sql
-- File: scripts/init-all-databases.sql

-- Create databases
CREATE DATABASE IF NOT EXISTS eticket_users;
CREATE DATABASE IF NOT EXISTS eticket_events;
CREATE DATABASE IF NOT EXISTS eticket_orders;
CREATE DATABASE IF NOT EXISTS eticket_payments;
CREATE DATABASE IF NOT EXISTS eticket_notifications;

-- Create service users with limited permissions
CREATE USER IF NOT EXISTS 'user_svc'@'%' IDENTIFIED BY 'user_svc_password';
CREATE USER IF NOT EXISTS 'event_svc'@'%' IDENTIFIED BY 'event_svc_password';
CREATE USER IF NOT EXISTS 'order_svc'@'%' IDENTIFIED BY 'order_svc_password';
CREATE USER IF NOT EXISTS 'payment_svc'@'%' IDENTIFIED BY 'payment_svc_password';
CREATE USER IF NOT EXISTS 'notification_svc'@'%' IDENTIFIED BY 'notification_svc_password';

-- Grant permissions (each service only accesses its own database)
GRANT ALL PRIVILEGES ON eticket_users.* TO 'user_svc'@'%';
GRANT ALL PRIVILEGES ON eticket_events.* TO 'event_svc'@'%';
GRANT ALL PRIVILEGES ON eticket_orders.* TO 'order_svc'@'%';
GRANT ALL PRIVILEGES ON eticket_payments.* TO 'payment_svc'@'%';
GRANT ALL PRIVILEGES ON eticket_notifications.* TO 'notification_svc'@'%';

FLUSH PRIVILEGES;
```

### 5.2 Docker Compose cho Multiple Databases

```yaml
# Có thể dùng 1 MySQL instance với nhiều databases
# Hoặc nhiều MySQL instances (recommended cho production)

version: "3.8"

services:
  # Option 1: Single MySQL with multiple databases
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root_password
    volumes:
      - ./scripts/init-all-databases.sql:/docker-entrypoint-initdb.d/01-init.sql
      - ./scripts/user-service-schema.sql:/docker-entrypoint-initdb.d/02-user.sql
      - ./scripts/event-service-schema.sql:/docker-entrypoint-initdb.d/03-event.sql
      - ./scripts/order-service-schema.sql:/docker-entrypoint-initdb.d/04-order.sql
      - ./scripts/payment-service-schema.sql:/docker-entrypoint-initdb.d/05-payment.sql
      - ./scripts/notification-service-schema.sql:/docker-entrypoint-initdb.d/06-notification.sql

  # Option 2: Separate MySQL for each service (Production recommended)
  # mysql-users:
  #   image: mysql:8.0
  #   environment:
  #     MYSQL_DATABASE: eticket_users
  #     MYSQL_USER: user_svc
  #     MYSQL_PASSWORD: user_svc_password
  #
  # mysql-events:
  #   image: mysql:8.0
  #   environment:
  #     MYSQL_DATABASE: eticket_events
  #     ...
```

---

## 📊 Tóm Tắt

| Service                  | Database                | Tables                              | Data Owned                 |
| ------------------------ | ----------------------- | ----------------------------------- | -------------------------- |
| **User Service**         | `eticket_users`         | users, refresh_tokens               | User credentials, profiles |
| **Event Service**        | `eticket_events`        | events, zones, seats, categories    | Event info, seating        |
| **Order Service**        | `eticket_orders`        | orders, order_items, tickets        | Orders, tickets            |
| **Payment Service**      | `eticket_payments`      | payments, refunds, transaction_logs | Payment records            |
| **Notification Service** | `eticket_notifications` | notifications, templates            | Notification history       |

---

**Version:** 1.0  
**Last Updated:** January 18, 2026
