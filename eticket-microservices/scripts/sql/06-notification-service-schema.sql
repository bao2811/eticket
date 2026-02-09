-- =====================================================
-- FILE: 06-notification-service-schema.sql
-- DATABASE: eticket_notifications
-- SERVICE: Notification Service
-- PURPOSE: Email, SMS, Push Notifications
-- =====================================================

USE eticket_notifications;

-- Drop tables if exist (for clean reinstall)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS notification_outbox_events;
DROP TABLE IF EXISTS notification_queue;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS notification_templates;
DROP TABLE IF EXISTS user_preferences;
SET FOREIGN_KEY_CHECKS = 1;

-- ─────────────────────────────────────────────────────
-- Table: notification_templates
-- Email/SMS/Push templates
-- ─────────────────────────────────────────────────────
CREATE TABLE notification_templates (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    code            VARCHAR(50) NOT NULL UNIQUE COMMENT 'Template identifier',
    name            VARCHAR(100) NOT NULL COMMENT 'Template display name',
    description     TEXT COMMENT 'Template description',
    
    -- Channel
    channel         ENUM('EMAIL', 'SMS', 'PUSH', 'IN_APP') NOT NULL,
    
    -- Language
    language        VARCHAR(5) NOT NULL DEFAULT 'vi' COMMENT 'vi, en',
    
    -- Content
    subject         VARCHAR(255) COMMENT 'Email subject (supports variables)',
    body            TEXT NOT NULL COMMENT 'Plain text body',
    html_body       TEXT COMMENT 'HTML body for emails',
    
    -- Variables
    variables       JSON COMMENT 'List of template variables with descriptions',
    sample_data     JSON COMMENT 'Sample data for preview',
    
    -- Category
    category        VARCHAR(50) COMMENT 'ORDER, PAYMENT, EVENT, MARKETING, SYSTEM',
    
    -- Status
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    is_system       BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'System template, cannot delete',
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by      VARCHAR(36),
    updated_by      VARCHAR(36),
    
    -- Indexes
    INDEX idx_code (code),
    INDEX idx_channel (channel),
    INDEX idx_category (category),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Notification templates';

-- ─────────────────────────────────────────────────────
-- Table: user_preferences
-- User notification preferences
-- ─────────────────────────────────────────────────────
CREATE TABLE user_preferences (
    id              VARCHAR(36) PRIMARY KEY,
    user_id         VARCHAR(36) NOT NULL UNIQUE COMMENT 'Reference to User Service',
    
    -- Email preferences
    email_enabled           BOOLEAN NOT NULL DEFAULT TRUE,
    email_order_updates     BOOLEAN NOT NULL DEFAULT TRUE,
    email_event_reminders   BOOLEAN NOT NULL DEFAULT TRUE,
    email_marketing         BOOLEAN NOT NULL DEFAULT FALSE,
    email_newsletter        BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- SMS preferences
    sms_enabled             BOOLEAN NOT NULL DEFAULT TRUE,
    sms_order_updates       BOOLEAN NOT NULL DEFAULT TRUE,
    sms_event_reminders     BOOLEAN NOT NULL DEFAULT FALSE,
    sms_marketing           BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Push preferences
    push_enabled            BOOLEAN NOT NULL DEFAULT TRUE,
    push_order_updates      BOOLEAN NOT NULL DEFAULT TRUE,
    push_event_reminders    BOOLEAN NOT NULL DEFAULT TRUE,
    push_marketing          BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Device tokens for push
    device_tokens           JSON COMMENT 'Array of {token, device_type, device_name}',
    
    -- Timezone
    timezone                VARCHAR(50) DEFAULT 'Asia/Ho_Chi_Minh',
    
    -- Quiet hours
    quiet_hours_enabled     BOOLEAN DEFAULT FALSE,
    quiet_hours_start       TIME COMMENT 'e.g., 22:00',
    quiet_hours_end         TIME COMMENT 'e.g., 08:00',
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='User notification preferences';

-- ─────────────────────────────────────────────────────
-- Table: notifications
-- Sent notification records
-- ─────────────────────────────────────────────────────
CREATE TABLE notifications (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    
    -- Recipient
    user_id         VARCHAR(36) COMMENT 'Reference to User Service (NULL for guest)',
    recipient       VARCHAR(255) NOT NULL COMMENT 'Email/Phone/Device token',
    recipient_name  VARCHAR(100) COMMENT 'Recipient name for personalization',
    
    -- Type & Template
    channel         ENUM('EMAIL', 'SMS', 'PUSH', 'IN_APP') NOT NULL,
    template_code   VARCHAR(50) COMMENT 'Template used',
    template_id     VARCHAR(36) COMMENT 'FK to templates',
    
    -- Content
    subject         VARCHAR(255),
    body            TEXT NOT NULL COMMENT 'Final rendered content',
    html_body       TEXT COMMENT 'HTML content for email',
    
    -- Attachments (for email)
    attachments     JSON COMMENT 'Array of {filename, url, content_type}',
    
    -- Context/Reference
    reference_type  VARCHAR(50) COMMENT 'ORDER, PAYMENT, EVENT, USER',
    reference_id    VARCHAR(36) COMMENT 'Related entity ID',
    
    -- Priority
    priority        ENUM('LOW', 'NORMAL', 'HIGH', 'URGENT') DEFAULT 'NORMAL',
    
    -- Status
    status          ENUM(
                        'PENDING',          -- Queued for sending
                        'SENDING',          -- Being sent
                        'SENT',             -- Sent to provider
                        'DELIVERED',        -- Confirmed delivered
                        'FAILED',           -- Failed to send
                        'BOUNCED',          -- Email bounced
                        'REJECTED',         -- Rejected by provider
                        'OPENED',           -- Email opened
                        'CLICKED'           -- Link clicked
                    ) NOT NULL DEFAULT 'PENDING',
    
    error_code      VARCHAR(50),
    error_message   TEXT,
    
    -- Provider info
    provider        VARCHAR(50) COMMENT 'SendGrid, Twilio, FCM, etc.',
    provider_message_id VARCHAR(100) COMMENT 'ID from provider',
    
    -- Tracking
    sent_at         TIMESTAMP NULL,
    delivered_at    TIMESTAMP NULL,
    opened_at       TIMESTAMP NULL,
    clicked_at      TIMESTAMP NULL,
    failed_at       TIMESTAMP NULL,
    
    -- Retry
    retry_count     INT NOT NULL DEFAULT 0,
    max_retries     INT NOT NULL DEFAULT 3,
    next_retry_at   TIMESTAMP NULL,
    
    -- Metadata
    metadata        JSON COMMENT 'Additional context data',
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_user (user_id),
    INDEX idx_recipient (recipient),
    INDEX idx_channel (channel),
    INDEX idx_status (status),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_template (template_code),
    INDEX idx_created (created_at),
    INDEX idx_retry (status, next_retry_at),
    INDEX idx_provider_msg (provider_message_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Sent notification records';

-- ─────────────────────────────────────────────────────
-- Table: notification_queue
-- Queue for pending notifications (processed by workers)
-- ─────────────────────────────────────────────────────
CREATE TABLE notification_queue (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    notification_id VARCHAR(36) NOT NULL COMMENT 'FK to notifications',
    
    -- Processing
    priority        INT NOT NULL DEFAULT 5 COMMENT '1=highest, 10=lowest',
    scheduled_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Worker assignment
    worker_id       VARCHAR(50) COMMENT 'Worker processing this',
    picked_at       TIMESTAMP NULL,
    
    -- Status
    status          ENUM('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED') DEFAULT 'PENDING',
    
    attempts        INT NOT NULL DEFAULT 0,
    last_error      TEXT,
    
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_pending (status, priority, scheduled_at),
    INDEX idx_notification (notification_id),
    INDEX idx_worker (worker_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Notification processing queue';

-- ─────────────────────────────────────────────────────
-- Table: notification_outbox_events
-- Outbox pattern (not really needed for this service, but for consistency)
-- ─────────────────────────────────────────────────────
CREATE TABLE notification_outbox_events (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    aggregate_id    VARCHAR(36) NOT NULL,
    aggregate_type  VARCHAR(50) NOT NULL DEFAULT 'Notification',
    event_type      VARCHAR(100) NOT NULL,
    event_version   INT NOT NULL DEFAULT 1,
    payload         JSON NOT NULL,
    metadata        JSON,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP NULL,
    publish_attempts INT NOT NULL DEFAULT 0,
    last_error      TEXT,
    
    INDEX idx_unpublished (published_at, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Outbox for Notification Service events';

-- ─────────────────────────────────────────────────────
-- Insert default templates
-- ─────────────────────────────────────────────────────
INSERT INTO notification_templates (id, code, name, channel, subject, body, html_body, variables, category, is_system) VALUES

-- Order Confirmation Email
('tpl-001', 'ORDER_CONFIRMED', 'Order Confirmation', 'EMAIL',
 'Xác nhận đơn hàng #{{order_number}} - {{event_name}}',
 'Xin chào {{customer_name}},\n\nĐơn hàng #{{order_number}} của bạn đã được xác nhận.\n\nSự kiện: {{event_name}}\nNgày: {{event_date}}\nĐịa điểm: {{venue_name}}\n\nSố lượng vé: {{ticket_count}}\nTổng tiền: {{total_amount}}\n\nVé điện tử của bạn đã được đính kèm trong email này.\n\nCảm ơn bạn đã đặt vé!',
 '<h1>Xác nhận đơn hàng</h1><p>Xin chào <strong>{{customer_name}}</strong>,</p><p>Đơn hàng <strong>#{{order_number}}</strong> của bạn đã được xác nhận.</p>',
 '["order_number", "customer_name", "event_name", "event_date", "venue_name", "ticket_count", "total_amount"]',
 'ORDER', TRUE),

-- Payment Success Email
('tpl-002', 'PAYMENT_SUCCESS', 'Payment Successful', 'EMAIL',
 'Thanh toán thành công - Đơn hàng #{{order_number}}',
 'Xin chào {{customer_name}},\n\nThanh toán cho đơn hàng #{{order_number}} đã thành công.\n\nSố tiền: {{amount}}\nPhương thức: {{payment_method}}\nMã giao dịch: {{transaction_id}}\n\nCảm ơn bạn!',
 NULL,
 '["order_number", "customer_name", "amount", "payment_method", "transaction_id"]',
 'PAYMENT', TRUE),

-- Event Reminder Email
('tpl-003', 'EVENT_REMINDER', 'Event Reminder', 'EMAIL',
 'Nhắc nhở: {{event_name}} sẽ diễn ra vào {{event_date}}',
 'Xin chào {{customer_name}},\n\nĐây là lời nhắc nhở rằng sự kiện {{event_name}} sẽ diễn ra vào {{event_date}} tại {{venue_name}}.\n\nĐừng quên mang theo vé điện tử!\n\nHẹn gặp bạn tại sự kiện!',
 NULL,
 '["customer_name", "event_name", "event_date", "venue_name"]',
 'EVENT', TRUE),

-- Order Confirmation SMS
('tpl-004', 'ORDER_CONFIRMED_SMS', 'Order Confirmation SMS', 'SMS',
 NULL,
 'eTicket: Don hang #{{order_number}} da duoc xac nhan. {{ticket_count}} ve cho {{event_name}} ngay {{event_date}}. Check email de nhan ve.',
 NULL,
 '["order_number", "ticket_count", "event_name", "event_date"]',
 'ORDER', TRUE),

-- Event Reminder Push
('tpl-005', 'EVENT_REMINDER_PUSH', 'Event Reminder Push', 'PUSH',
 'Nhắc nhở sự kiện',
 '{{event_name}} sẽ diễn ra trong {{hours_until}} giờ nữa tại {{venue_name}}. Đừng quên mang vé!',
 NULL,
 '["event_name", "hours_until", "venue_name"]',
 'EVENT', TRUE);
