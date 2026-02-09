-- =====================================================
-- FILE: 03-event-service-schema.sql
-- DATABASE: eticket_events
-- SERVICE: Event Service
-- PURPOSE: Event Management, Zones, Seats
-- =====================================================

USE eticket_events;

-- Drop tables if exist (for clean reinstall)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS event_outbox_events;
DROP TABLE IF EXISTS seats;
DROP TABLE IF EXISTS zones;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS categories;
SET FOREIGN_KEY_CHECKS = 1;

-- ─────────────────────────────────────────────────────
-- Table: categories
-- Event categories/types
-- ─────────────────────────────────────────────────────
CREATE TABLE categories (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    name            VARCHAR(100) NOT NULL COMMENT 'Category name',
    slug            VARCHAR(100) NOT NULL UNIQUE COMMENT 'URL-friendly slug',
    description     TEXT COMMENT 'Category description',
    icon_url        VARCHAR(500) COMMENT 'Category icon URL',
    
    -- Hierarchy
    parent_id       VARCHAR(36) COMMENT 'Parent category ID for nested categories',
    level           INT NOT NULL DEFAULT 0 COMMENT 'Nesting level (0 = root)',
    path            VARCHAR(500) COMMENT 'Materialized path: /parent1/parent2/current',
    
    -- Display
    sort_order      INT NOT NULL DEFAULT 0 COMMENT 'Display order',
    color           VARCHAR(7) COMMENT 'Category color (#HEX)',
    
    -- Status
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    event_count     INT NOT NULL DEFAULT 0 COMMENT 'Denormalized event count',
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_slug (slug),
    INDEX idx_parent (parent_id),
    INDEX idx_active (is_active, sort_order),
    
    CONSTRAINT fk_category_parent 
        FOREIGN KEY (parent_id) REFERENCES categories(id) 
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Event categories and types';

-- ─────────────────────────────────────────────────────
-- Table: events
-- Main event entity
-- ─────────────────────────────────────────────────────
CREATE TABLE events (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    
    -- Basic info
    name            VARCHAR(255) NOT NULL COMMENT 'Event name',
    slug            VARCHAR(255) NOT NULL UNIQUE COMMENT 'URL-friendly slug',
    description     TEXT COMMENT 'Full event description (HTML allowed)',
    short_description VARCHAR(500) COMMENT 'Brief description for cards',
    
    -- Organizer (reference to User Service - NO FK)
    organizer_id    VARCHAR(36) NOT NULL COMMENT 'Reference to User Service',
    organizer_name  VARCHAR(100) COMMENT 'Denormalized organizer name',
    organizer_logo  VARCHAR(500) COMMENT 'Denormalized organizer logo',
    
    -- Category
    category_id     VARCHAR(36) COMMENT 'FK to categories',
    
    -- Location
    venue_name      VARCHAR(255) COMMENT 'Venue/Location name',
    venue_address   TEXT COMMENT 'Full address',
    city            VARCHAR(100) COMMENT 'City name',
    district        VARCHAR(100) COMMENT 'District/Area',
    country         VARCHAR(50) DEFAULT 'Vietnam',
    latitude        DECIMAL(10, 8) COMMENT 'GPS latitude',
    longitude       DECIMAL(11, 8) COMMENT 'GPS longitude',
    google_maps_url VARCHAR(500) COMMENT 'Google Maps link',
    
    -- Time
    start_date      TIMESTAMP NOT NULL COMMENT 'Event start datetime',
    end_date        TIMESTAMP COMMENT 'Event end datetime',
    doors_open_at   TIMESTAMP COMMENT 'When doors open',
    timezone        VARCHAR(50) DEFAULT 'Asia/Ho_Chi_Minh',
    
    -- Media
    banner_url      VARCHAR(500) COMMENT 'Large banner image',
    thumbnail_url   VARCHAR(500) COMMENT 'Thumbnail for cards',
    mobile_banner_url VARCHAR(500) COMMENT 'Mobile-optimized banner',
    video_url       VARCHAR(500) COMMENT 'Promo video URL',
    gallery         JSON COMMENT 'Array of gallery image URLs',
    
    -- Ticket info (aggregated)
    max_tickets_per_order INT NOT NULL DEFAULT 10 COMMENT 'Max tickets per transaction',
    total_capacity  INT NOT NULL DEFAULT 0 COMMENT 'Total available tickets',
    sold_count      INT NOT NULL DEFAULT 0 COMMENT 'Total tickets sold',
    available_count INT NOT NULL DEFAULT 0 COMMENT 'Currently available',
    min_price       BIGINT NOT NULL DEFAULT 0 COMMENT 'Lowest ticket price (VND)',
    max_price       BIGINT NOT NULL DEFAULT 0 COMMENT 'Highest ticket price (VND)',
    
    -- Status
    status          ENUM('DRAFT', 'PENDING_REVIEW', 'PUBLISHED', 'CANCELLED', 'POSTPONED', 'COMPLETED', 'SOLDOUT') 
                    NOT NULL DEFAULT 'DRAFT',
    cancellation_reason TEXT COMMENT 'Reason if cancelled/postponed',
    
    -- Flags
    is_featured     BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Show in featured section',
    is_hot          BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Trending/hot event',
    is_free         BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Free admission event',
    allow_refund    BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Allow ticket refunds',
    
    -- SEO
    meta_title      VARCHAR(255) COMMENT 'SEO title',
    meta_description VARCHAR(500) COMMENT 'SEO description',
    meta_keywords   VARCHAR(255) COMMENT 'SEO keywords',
    
    -- Settings
    settings        JSON COMMENT 'Additional event settings',
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    published_at    TIMESTAMP NULL COMMENT 'When event was published',
    
    -- Indexes
    INDEX idx_slug (slug),
    INDEX idx_status (status),
    INDEX idx_start_date (start_date),
    INDEX idx_category (category_id),
    INDEX idx_organizer (organizer_id),
    INDEX idx_city (city),
    INDEX idx_featured (is_featured, status, start_date),
    INDEX idx_hot (is_hot, status),
    INDEX idx_price_range (min_price, max_price),
    INDEX idx_available (status, available_count),
    
    -- Full-text search
    FULLTEXT INDEX ft_search (name, description, venue_name, city),
    
    -- Foreign Keys
    CONSTRAINT fk_event_category 
        FOREIGN KEY (category_id) REFERENCES categories(id) 
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Main event entity';

-- ─────────────────────────────────────────────────────
-- Table: zones
-- Ticket zones/areas within an event
-- ─────────────────────────────────────────────────────
CREATE TABLE zones (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    event_id        VARCHAR(36) NOT NULL COMMENT 'FK to events',
    
    -- Basic info
    name            VARCHAR(100) NOT NULL COMMENT 'Zone name: VIP, Standard, etc.',
    description     TEXT COMMENT 'Zone description',
    
    -- Visual
    color           VARCHAR(7) COMMENT 'Zone color on seat map (#HEX)',
    icon            VARCHAR(50) COMMENT 'Zone icon identifier',
    
    -- Pricing
    price           BIGINT NOT NULL COMMENT 'Ticket price in VND',
    original_price  BIGINT COMMENT 'Original price (for discount display)',
    
    -- Capacity
    total_quantity      INT NOT NULL DEFAULT 0 COMMENT 'Total tickets in zone',
    sold_quantity       INT NOT NULL DEFAULT 0 COMMENT 'Tickets sold',
    reserved_quantity   INT NOT NULL DEFAULT 0 COMMENT 'Temporarily reserved',
    available_quantity  INT GENERATED ALWAYS AS (total_quantity - sold_quantity - reserved_quantity) STORED,
    
    -- Limits
    min_per_order   INT NOT NULL DEFAULT 1 COMMENT 'Min tickets per order',
    max_per_order   INT NOT NULL DEFAULT 10 COMMENT 'Max tickets per order',
    
    -- Seating
    has_numbered_seats BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Zone has specific seats',
    seat_map_data   JSON COMMENT 'Seat map SVG/config data',
    
    -- Display
    sort_order      INT NOT NULL DEFAULT 0 COMMENT 'Display order',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    is_visible      BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Show on frontend',
    
    -- Sale window
    sale_start_at   TIMESTAMP COMMENT 'When tickets go on sale',
    sale_end_at     TIMESTAMP COMMENT 'When ticket sales end',
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_event (event_id),
    INDEX idx_active (is_active, sort_order),
    INDEX idx_available (event_id, available_quantity),
    INDEX idx_price (event_id, price),
    
    -- Foreign Key
    CONSTRAINT fk_zone_event 
        FOREIGN KEY (event_id) REFERENCES events(id) 
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ticket zones within events';

-- ─────────────────────────────────────────────────────
-- Table: seats
-- Individual seats (for numbered seating events)
-- ─────────────────────────────────────────────────────
CREATE TABLE seats (
    id              VARCHAR(36) PRIMARY KEY COMMENT 'UUID v4',
    zone_id         VARCHAR(36) NOT NULL COMMENT 'FK to zones',
    event_id        VARCHAR(36) NOT NULL COMMENT 'FK to events (denormalized)',
    
    -- Seat identification
    row_name        VARCHAR(10) NOT NULL COMMENT 'Row: A, B, C, AA, BB...',
    seat_number     INT NOT NULL COMMENT 'Seat number in row',
    seat_label      VARCHAR(20) GENERATED ALWAYS AS (CONCAT(row_name, '-', seat_number)) STORED,
    
    -- Position for seat map rendering
    pos_x           DECIMAL(10, 2) COMMENT 'X coordinate on map',
    pos_y           DECIMAL(10, 2) COMMENT 'Y coordinate on map',
    rotation        DECIMAL(5, 2) DEFAULT 0 COMMENT 'Seat rotation angle',
    
    -- Seat type
    seat_type       ENUM('STANDARD', 'VIP', 'WHEELCHAIR', 'COMPANION', 'RESTRICTED_VIEW') 
                    NOT NULL DEFAULT 'STANDARD',
    
    -- Status
    status          ENUM('AVAILABLE', 'RESERVED', 'SOLD', 'BLOCKED', 'MAINTENANCE') 
                    NOT NULL DEFAULT 'AVAILABLE',
    
    -- Temporary lock (for checkout process)
    locked_by_order VARCHAR(36) COMMENT 'Order ID that locked this seat',
    locked_at       TIMESTAMP NULL COMMENT 'When seat was locked',
    lock_expires_at TIMESTAMP NULL COMMENT 'Lock expiration time',
    
    -- Price override (if different from zone)
    price_override  BIGINT COMMENT 'Custom price for this seat',
    
    -- Sold info (denormalized)
    sold_to_order   VARCHAR(36) COMMENT 'Order ID if sold',
    sold_at         TIMESTAMP NULL,
    
    -- Audit
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_zone (zone_id),
    INDEX idx_event (event_id),
    INDEX idx_status (status),
    INDEX idx_event_status (event_id, status),
    INDEX idx_event_zone_status (event_id, zone_id, status),
    INDEX idx_locked (locked_by_order, lock_expires_at),
    INDEX idx_row_seat (zone_id, row_name, seat_number),
    
    -- Unique constraint
    UNIQUE INDEX uk_seat_position (zone_id, row_name, seat_number),
    
    -- Foreign Keys
    CONSTRAINT fk_seat_zone 
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE,
    CONSTRAINT fk_seat_event 
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Individual seats for numbered seating';

-- ─────────────────────────────────────────────────────
-- Table: event_outbox_events
-- Outbox pattern for reliable event publishing
-- ─────────────────────────────────────────────────────
CREATE TABLE event_outbox_events (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    -- Aggregate info
    aggregate_id    VARCHAR(36) NOT NULL,
    aggregate_type  VARCHAR(50) NOT NULL COMMENT 'Event, Zone, Seat',
    
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
    
    -- Indexes
    INDEX idx_unpublished (published_at, created_at),
    INDEX idx_aggregate (aggregate_type, aggregate_id),
    INDEX idx_event_type (event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Outbox for Event Service domain events';

-- ─────────────────────────────────────────────────────
-- Insert sample categories
-- ─────────────────────────────────────────────────────
INSERT INTO categories (id, name, slug, description, sort_order) VALUES
('cat-001', 'Âm nhạc', 'am-nhac', 'Concerts, shows, music events', 1),
('cat-002', 'Thể thao', 'the-thao', 'Sports events, matches', 2),
('cat-003', 'Sân khấu', 'san-khau', 'Theater, drama, opera', 3),
('cat-004', 'Hội thảo', 'hoi-thao', 'Conferences, seminars, workshops', 4),
('cat-005', 'Giải trí', 'giai-tri', 'Entertainment, festivals', 5);
