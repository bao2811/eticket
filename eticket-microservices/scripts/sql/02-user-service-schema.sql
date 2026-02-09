-- =====================================================
-- FILE: 02-user-service-schema.sql
-- DATABASE: eticket_users
-- SERVICE: User Service
-- PURPOSE: Authentication, Authorization, User Management
-- =====================================================

USE eticket_users;

-- Drop tables if exist (for clean reinstall)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS user_outbox_events;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- ─────────────────────────────────────────────────────
-- Table: users
-- Core user entity for authentication and profile
-- ─────────────────────────────────────────────────────
CREATE TABLE users (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    username        VARCHAR(50) NOT NULL UNIQUE COMMENT 'Login username',
    email           VARCHAR(100) NOT NULL UNIQUE COMMENT 'Email address',
    password_hash   VARCHAR(255) NOT NULL COMMENT 'BCrypt hashed password',
    
    -- Profile info
    full_name       VARCHAR(100) COMMENT 'Display name',
    phone_number    VARCHAR(20) COMMENT 'Phone with country code',
    avatar_url      VARCHAR(500) COMMENT 'Profile image URL',
    address         TEXT COMMENT 'Delivery address',
    
    -- Status & Role
    status          ENUM('ACTIVE', 'INACTIVE', 'BANNED', 'PENDING_VERIFICATION') 
                    NOT NULL DEFAULT 'PENDING_VERIFICATION' 
                    COMMENT 'Account status',
    role            ENUM('USER', 'ADMIN', 'ORGANIZER') 
                    NOT NULL DEFAULT 'USER' 
                    COMMENT 'User role for authorization',
    
    -- Verification
    email_verified      BOOLEAN NOT NULL DEFAULT FALSE,
    email_verified_at   TIMESTAMP NULL,
    phone_verified      BOOLEAN NOT NULL DEFAULT FALSE,
    phone_verified_at   TIMESTAMP NULL,
    
    -- Audit fields
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at   TIMESTAMP NULL COMMENT 'Last successful login',
    last_login_ip   VARCHAR(45) COMMENT 'Last login IP address',
    
    -- Indexes
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_status (status),
    INDEX idx_role (role),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='User accounts for authentication and profiles';

-- ─────────────────────────────────────────────────────
-- Table: refresh_tokens
-- JWT refresh tokens for session management
-- ─────────────────────────────────────────────────────
CREATE TABLE refresh_tokens (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    user_id         VARCHAR(36) NOT NULL COMMENT 'FK to users',
    
    -- Token
    token_hash      VARCHAR(255) NOT NULL UNIQUE COMMENT 'Hashed refresh token',
    token_family    VARCHAR(36) NOT NULL COMMENT 'Token family for rotation detection',
    
    -- Device info
    device_id       VARCHAR(100) COMMENT 'Device identifier',
    device_name     VARCHAR(100) COMMENT 'Device name/model',
    device_type     ENUM('WEB', 'MOBILE_IOS', 'MOBILE_ANDROID', 'DESKTOP') DEFAULT 'WEB',
    user_agent      VARCHAR(500) COMMENT 'Browser user agent',
    ip_address      VARCHAR(45) COMMENT 'IP address at token creation',
    
    -- Status
    is_revoked      BOOLEAN NOT NULL DEFAULT FALSE,
    revoked_at      TIMESTAMP NULL,
    revoked_reason  VARCHAR(100) COMMENT 'Reason for revocation',
    
    -- Timestamps
    expires_at      TIMESTAMP NOT NULL COMMENT 'Token expiration time',
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at    TIMESTAMP NULL COMMENT 'Last time token was used',
    
    -- Indexes
    INDEX idx_user_id (user_id),
    INDEX idx_token_hash (token_hash),
    INDEX idx_token_family (token_family),
    INDEX idx_expires (expires_at),
    INDEX idx_active (user_id, is_revoked, expires_at),
    
    -- Foreign Key
    CONSTRAINT fk_refresh_token_user 
        FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
  COMMENT='Refresh tokens for JWT session management';

-- ─────────────────────────────────────────────────────
-- Table: user_outbox_events
-- Outbox pattern for reliable event publishing
-- ─────────────────────────────────────────────────────
CREATE TABLE user_outbox_events (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    -- Aggregate info
    aggregate_id    VARCHAR(36) NOT NULL COMMENT 'User ID',
    aggregate_type  VARCHAR(50) NOT NULL DEFAULT 'User' COMMENT 'Entity type',
    
    -- Event info
    event_type      VARCHAR(100) NOT NULL COMMENT 'Event type: UserCreated, UserUpdated, etc.',
    event_version   INT NOT NULL DEFAULT 1 COMMENT 'Event schema version',
    payload         JSON NOT NULL COMMENT 'Event payload as JSON',
    metadata        JSON COMMENT 'Additional metadata (correlation ID, etc.)',
    
    -- Publishing status
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP NULL COMMENT 'When event was published to message broker',
    publish_attempts INT NOT NULL DEFAULT 0 COMMENT 'Number of publish attempts',
    last_error      TEXT COMMENT 'Last publish error message',
    
    -- Indexes
    INDEX idx_unpublished (published_at, created_at),
    INDEX idx_aggregate (aggregate_type, aggregate_id),
    INDEX idx_event_type (event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
  COMMENT='Outbox table for reliable event publishing';

-- ─────────────────────────────────────────────────────
-- Insert sample data (for development)
-- ─────────────────────────────────────────────────────
INSERT INTO users (id, username, email, password_hash, full_name, status, role, email_verified) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'admin', 'admin@eticket.vn', 
 '$2a$10$rG8K.8WqXQXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', 
 'System Admin', 'ACTIVE', 'ADMIN', TRUE),
('550e8400-e29b-41d4-a716-446655440002', 'organizer1', 'organizer@example.com',
 '$2a$10$rG8K.8WqXQXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
 'Event Organizer', 'ACTIVE', 'ORGANIZER', TRUE),
('550e8400-e29b-41d4-a716-446655440003', 'user1', 'user@example.com',
 '$2a$10$rG8K.8WqXQXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
 'Normal User', 'ACTIVE', 'USER', TRUE);
