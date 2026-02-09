-- =====================================================
-- FILE: 05-payment-service-schema.sql
-- DATABASE: eticket_payments
-- SERVICE: Payment Service
-- PURPOSE: Payment Processing, Refunds, Transaction Logs
-- =====================================================

USE eticket_payments;

-- Drop tables if exist (for clean reinstall)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS payment_outbox_events;
DROP TABLE IF EXISTS transaction_logs;
DROP TABLE IF EXISTS refunds;
DROP TABLE IF EXISTS payments;
SET FOREIGN_KEY_CHECKS = 1;

-- ─────────────────────────────────────────────────────
-- Table: payments
-- Payment records for orders
-- ─────────────────────────────────────────────────────
CREATE TABLE payments (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    payment_number  VARCHAR(30) NOT NULL UNIQUE COMMENT 'PAY-YYYYMMDD-XXXXX',
    
    -- Order reference (from Order Service - no FK across services)
    order_id        VARCHAR(36) NOT NULL UNIQUE COMMENT 'Reference to Order Service',
    order_number    VARCHAR(20) NOT NULL COMMENT 'Order number for display',
    
    -- Customer info (denormalized)
    user_id         VARCHAR(36) COMMENT 'Reference to User Service',
    customer_email  VARCHAR(100) NOT NULL,
    customer_phone  VARCHAR(20),
    customer_name   VARCHAR(100),
    
    -- Amount
    amount          BIGINT NOT NULL COMMENT 'Amount in VND',
    currency        VARCHAR(3) NOT NULL DEFAULT 'VND',
    
    -- Payment Gateway
    gateway         ENUM('ONEPAY', 'VNPAY', 'MOMO', 'ZALOPAY', 'BANK_TRANSFER', 'CASH', 'FREE') NOT NULL,
    gateway_config  VARCHAR(50) COMMENT 'Gateway config profile used',
    
    -- Gateway transaction info
    gateway_txn_id      VARCHAR(100) COMMENT 'Transaction ID from gateway',
    gateway_order_id    VARCHAR(100) COMMENT 'Order ID sent to gateway',
    gateway_request     JSON COMMENT 'Request sent to gateway',
    gateway_response    JSON COMMENT 'Response from gateway',
    
    -- URLs for payment flow
    payment_url     VARCHAR(1000) COMMENT 'Redirect URL for customer',
    return_url      VARCHAR(500) COMMENT 'Return URL after payment',
    cancel_url      VARCHAR(500) COMMENT 'Cancel return URL',
    ipn_url         VARCHAR(500) COMMENT 'IPN callback URL',
    
    -- Payment Status
    status          ENUM(
                        'PENDING',              -- Waiting for payment
                        'PROCESSING',           -- Payment in progress at gateway
                        'AWAITING_CAPTURE',     -- Authorized, awaiting capture
                        'SUCCESS',              -- Payment successful
                        'FAILED',               -- Payment failed
                        'CANCELLED',            -- Cancelled by user
                        'EXPIRED',              -- Payment timeout
                        'REFUNDED',             -- Full refund processed
                        'PARTIALLY_REFUNDED'    -- Partial refund processed
                    ) NOT NULL DEFAULT 'PENDING',
    
    failure_code    VARCHAR(50) COMMENT 'Error code from gateway',
    failure_reason  TEXT COMMENT 'Human readable failure reason',
    
    -- Card/Bank info (masked for security)
    card_type       VARCHAR(20) COMMENT 'VISA, MASTERCARD, etc.',
    card_last4      VARCHAR(4) COMMENT 'Last 4 digits',
    card_brand      VARCHAR(50) COMMENT 'Card brand name',
    bank_code       VARCHAR(20) COMMENT 'Bank code if bank transfer',
    bank_name       VARCHAR(100) COMMENT 'Bank name',
    
    -- Refund tracking
    total_refunded  BIGINT NOT NULL DEFAULT 0 COMMENT 'Total refunded amount',
    refund_count    INT NOT NULL DEFAULT 0 COMMENT 'Number of refunds',
    
    -- Timestamps
    expires_at      TIMESTAMP COMMENT 'Payment deadline',
    authorized_at   TIMESTAMP NULL COMMENT 'When authorized',
    captured_at     TIMESTAMP NULL COMMENT 'When captured/paid',
    paid_at         TIMESTAMP NULL COMMENT 'Alias for captured_at',
    failed_at       TIMESTAMP NULL,
    
    -- IP & Device
    customer_ip     VARCHAR(45),
    user_agent      VARCHAR(500),
    
    -- Metadata
    metadata        JSON COMMENT 'Additional metadata',
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_payment_number (payment_number),
    INDEX idx_order (order_id),
    INDEX idx_gateway_txn (gateway_txn_id),
    INDEX idx_gateway_order (gateway_order_id),
    INDEX idx_status (status),
    INDEX idx_user (user_id),
    INDEX idx_gateway (gateway),
    INDEX idx_created (created_at),
    INDEX idx_expires (expires_at, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Payment records';

-- ─────────────────────────────────────────────────────
-- Table: refunds
-- Refund transactions
-- ─────────────────────────────────────────────────────
CREATE TABLE refunds (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    refund_number   VARCHAR(30) NOT NULL UNIQUE COMMENT 'REF-YYYYMMDD-XXXXX',
    
    -- Links
    payment_id      VARCHAR(36) NOT NULL COMMENT 'FK to payments',
    order_id        VARCHAR(36) NOT NULL COMMENT 'Reference to Order Service',
    
    -- Refund amount
    amount          BIGINT NOT NULL COMMENT 'Refund amount in VND',
    currency        VARCHAR(3) NOT NULL DEFAULT 'VND',
    
    -- Type
    refund_type     ENUM('FULL', 'PARTIAL') NOT NULL,
    
    -- Reason
    reason_code     VARCHAR(50) COMMENT 'Predefined reason code',
    reason          TEXT COMMENT 'Detailed reason',
    
    -- Gateway info
    gateway_refund_id VARCHAR(100) COMMENT 'Refund ID from gateway',
    gateway_request   JSON COMMENT 'Request sent to gateway',
    gateway_response  JSON COMMENT 'Response from gateway',
    
    -- Status
    status          ENUM('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED', 'CANCELLED') 
                    NOT NULL DEFAULT 'PENDING',
    failure_reason  TEXT,
    
    -- Tickets being refunded
    ticket_ids      JSON COMMENT 'Array of ticket IDs being refunded',
    
    -- Processor info
    requested_by    VARCHAR(36) COMMENT 'User who requested refund',
    requested_by_type ENUM('CUSTOMER', 'ADMIN', 'SYSTEM') DEFAULT 'CUSTOMER',
    processed_by    VARCHAR(36) COMMENT 'Admin who processed',
    
    -- Timestamps
    requested_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at    TIMESTAMP NULL,
    completed_at    TIMESTAMP NULL,
    
    -- Notes
    customer_notes  TEXT,
    admin_notes     TEXT,
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_refund_number (refund_number),
    INDEX idx_payment (payment_id),
    INDEX idx_order (order_id),
    INDEX idx_status (status),
    INDEX idx_gateway_refund (gateway_refund_id),
    INDEX idx_requested (requested_at),
    
    -- Foreign Key
    CONSTRAINT fk_refund_payment 
        FOREIGN KEY (payment_id) REFERENCES payments(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Refund transactions';

-- ─────────────────────────────────────────────────────
-- Table: transaction_logs
-- Audit trail for all gateway communications
-- ─────────────────────────────────────────────────────
CREATE TABLE transaction_logs (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    -- Links
    payment_id      VARCHAR(36) COMMENT 'FK to payments',
    refund_id       VARCHAR(36) COMMENT 'FK to refunds (if refund related)',
    
    -- Log type
    log_type        ENUM(
                        'PAYMENT_INIT',         -- Payment initiated
                        'PAYMENT_REQUEST',      -- Request to gateway
                        'PAYMENT_RESPONSE',     -- Response from gateway
                        'PAYMENT_CALLBACK',     -- Return URL callback
                        'IPN_RECEIVED',         -- IPN callback received
                        'IPN_PROCESSED',        -- IPN processed
                        'REFUND_REQUEST',       -- Refund request to gateway
                        'REFUND_RESPONSE',      -- Refund response
                        'QUERY_REQUEST',        -- Status query request
                        'QUERY_RESPONSE',       -- Status query response
                        'ERROR',                -- Error occurred
                        'WEBHOOK'               -- Webhook received
                    ) NOT NULL,
    
    -- Gateway info
    gateway         VARCHAR(20),
    
    -- Request/Response
    direction       ENUM('OUTBOUND', 'INBOUND') NOT NULL,
    endpoint        VARCHAR(255) COMMENT 'API endpoint called',
    method          VARCHAR(10) COMMENT 'HTTP method',
    
    -- Data
    request_headers JSON COMMENT 'Request headers (sensitive filtered)',
    request_body    JSON COMMENT 'Request body',
    response_status INT COMMENT 'HTTP status code',
    response_headers JSON COMMENT 'Response headers',
    response_body   JSON COMMENT 'Response body',
    
    -- Timing
    request_at      TIMESTAMP(3) COMMENT 'Request timestamp with ms',
    response_at     TIMESTAMP(3) COMMENT 'Response timestamp with ms',
    duration_ms     INT COMMENT 'Request duration in milliseconds',
    
    -- Client info
    client_ip       VARCHAR(45),
    user_agent      VARCHAR(500),
    
    -- Signature verification (for callbacks)
    signature_valid BOOLEAN COMMENT 'Was signature verified',
    
    -- Error info
    error_code      VARCHAR(50),
    error_message   TEXT,
    
    -- Metadata
    correlation_id  VARCHAR(36) COMMENT 'Request correlation ID',
    metadata        JSON,
    
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_payment (payment_id),
    INDEX idx_refund (refund_id),
    INDEX idx_type (log_type),
    INDEX idx_gateway (gateway),
    INDEX idx_created (created_at),
    INDEX idx_correlation (correlation_id),
    INDEX idx_error (error_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Transaction audit logs';

-- ─────────────────────────────────────────────────────
-- Table: payment_outbox_events
-- Outbox pattern for reliable event publishing
-- ─────────────────────────────────────────────────────
CREATE TABLE payment_outbox_events (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    -- Aggregate info
    aggregate_id    VARCHAR(36) NOT NULL,
    aggregate_type  VARCHAR(50) NOT NULL DEFAULT 'Payment',
    
    -- Event info
    event_type      VARCHAR(100) NOT NULL COMMENT 'PaymentSucceeded, PaymentFailed, RefundCompleted, etc.',
    event_version   INT NOT NULL DEFAULT 1,
    payload         JSON NOT NULL,
    metadata        JSON,
    
    -- Publishing status
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP NULL,
    publish_attempts INT NOT NULL DEFAULT 0,
    last_error      TEXT,
    
    -- Indexes
    INDEX idx_unpublished (published_at, created_at),
    INDEX idx_aggregate (aggregate_type, aggregate_id),
    INDEX idx_event_type (event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Outbox for Payment Service domain events';

-- ─────────────────────────────────────────────────────
-- Gateway configuration reference (stored in config/env)
-- ─────────────────────────────────────────────────────
/*
Gateway configurations should be stored in environment variables or config files:

ONEPAY:
  - ONEPAY_MERCHANT_ID
  - ONEPAY_ACCESS_CODE
  - ONEPAY_SECURE_SECRET
  - ONEPAY_API_URL

VNPAY:
  - VNPAY_TMN_CODE
  - VNPAY_HASH_SECRET
  - VNPAY_API_URL

MOMO:
  - MOMO_PARTNER_CODE
  - MOMO_ACCESS_KEY
  - MOMO_SECRET_KEY
  - MOMO_API_URL

ZALOPAY:
  - ZALOPAY_APP_ID
  - ZALOPAY_KEY1
  - ZALOPAY_KEY2
  - ZALOPAY_API_URL
*/
