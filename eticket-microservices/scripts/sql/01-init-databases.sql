-- =====================================================
-- FILE: 01-init-databases.sql
-- PURPOSE: Initialize all databases and service users
-- RUN: First, by MySQL root user
-- =====================================================

-- Create databases
CREATE DATABASE IF NOT EXISTS eticket_users 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS eticket_events 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS eticket_orders 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS eticket_payments 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS eticket_notifications 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- =====================================================
-- Create service users with limited permissions
-- Each service can ONLY access its own database
-- =====================================================

-- User Service
CREATE USER IF NOT EXISTS 'user_svc'@'%' IDENTIFIED BY 'User$vc2026!';
GRANT ALL PRIVILEGES ON eticket_users.* TO 'user_svc'@'%';
GRANT USAGE ON *.* TO 'user_svc'@'%';

-- Event Service
CREATE USER IF NOT EXISTS 'event_svc'@'%' IDENTIFIED BY 'Event$vc2026!';
GRANT ALL PRIVILEGES ON eticket_events.* TO 'event_svc'@'%';
GRANT USAGE ON *.* TO 'event_svc'@'%';

-- Order Service
CREATE USER IF NOT EXISTS 'order_svc'@'%' IDENTIFIED BY 'Order$vc2026!';
GRANT ALL PRIVILEGES ON eticket_orders.* TO 'order_svc'@'%';
GRANT USAGE ON *.* TO 'order_svc'@'%';

-- Payment Service
CREATE USER IF NOT EXISTS 'payment_svc'@'%' IDENTIFIED BY 'Payment$vc2026!';
GRANT ALL PRIVILEGES ON eticket_payments.* TO 'payment_svc'@'%';
GRANT USAGE ON *.* TO 'payment_svc'@'%';

-- Notification Service
CREATE USER IF NOT EXISTS 'notification_svc'@'%' IDENTIFIED BY 'Notif$vc2026!';
GRANT ALL PRIVILEGES ON eticket_notifications.* TO 'notification_svc'@'%';
GRANT USAGE ON *.* TO 'notification_svc'@'%';

FLUSH PRIVILEGES;

-- Verify databases created
SHOW DATABASES LIKE 'eticket_%';

-- Verify users created
SELECT User, Host FROM mysql.user WHERE User LIKE '%_svc';
