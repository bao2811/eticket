# 🎫 eTicket Microservices Architecture Guide

## 📋 Mục Lục

1. [Tổng Quan Kiến Trúc](#1-tổng-quan-kiến-trúc)
2. [Cấu Trúc Thư Mục](#2-cấu-trúc-thư-mục)
3. [Chi Tiết Từng Service](#3-chi-tiết-từng-service)
4. [Flow Công Việc](#4-flow-công-việc)
5. [Docker Setup](#5-docker-setup)
6. [Hướng Dẫn Triển Khai](#6-hướng-dẫn-triển-khai)

---

## 1. Tổng Quan Kiến Trúc

```
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                        FRONTEND                              │
                                    │                    (Next.js + React)                         │
                                    └─────────────────────────────────────────────────────────────┘
                                                              │
                                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                              NGINX LOAD BALANCER                                                 │
│                                    (SSL Termination + Rate Limiting + Routing)                                  │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                              │
                                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                              API GATEWAY SERVICE                                                 │
│                              (Spring Cloud Gateway + JWT Auth + Rate Limit + Circuit Breaker)                   │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                              │
                    ┌─────────────────────────────────────────┼─────────────────────────────────────────┐
                    │                                         │                                         │
                    ▼                                         ▼                                         ▼
    ┌───────────────────────────┐         ┌───────────────────────────┐         ┌───────────────────────────┐
    │     EVENT SERVICE         │         │     ORDER SERVICE         │         │     USER SERVICE          │
    │   (Event Management)      │         │   (Order + Ticket)        │         │   (Auth + Profile)        │
    │                           │         │                           │         │                           │
    │   ┌─────────────────┐     │         │   ┌─────────────────┐     │         │   ┌─────────────────┐     │
    │   │  Command Side   │     │         │   │  Command Side   │     │         │   │  Command Side   │     │
    │   │   (Write DB)    │     │         │   │   (Write DB)    │     │         │   │   (Write DB)    │     │
    │   └────────┬────────┘     │         │   └────────┬────────┘     │         │   └────────┬────────┘     │
    │            │              │         │            │              │         │            │              │
    │            ▼              │         │            ▼              │         │            ▼              │
    │   ┌─────────────────┐     │         │   ┌─────────────────┐     │         │   ┌─────────────────┐     │
    │   │   Query Side    │     │         │   │   Query Side    │     │         │   │   Query Side    │     │
    │   │ (Elasticsearch) │     │         │   │ (Elasticsearch) │     │         │   │ (Elasticsearch) │     │
    │   └─────────────────┘     │         │   └─────────────────┘     │         │   └─────────────────┘     │
    └───────────────────────────┘         └───────────────────────────┘         └───────────────────────────┘
                    │                                         │                                         │
                    └─────────────────────────────────────────┼─────────────────────────────────────────┘
                                                              │
                                                              ▼
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                         PAYMENT SERVICE                                                  │
    │                                    (OnePay + VNPay Integration)                                         │
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                              │
                                                              ▼
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                        NOTIFICATION SERVICE                                              │
    │                                      (Email + SMS + Push)                                                │
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────┘

                                          INFRASTRUCTURE LAYER
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                                                                                          │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
    │  │   RabbitMQ   │  │    Redis     │  │    MySQL     │  │Elasticsearch │  │  Prometheus  │               │
    │  │  (Pub/Sub)   │  │   (Cache)    │  │  (Write DB)  │  │  (Read DB)   │  │  + Grafana   │               │
    │  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘               │
    │                                                                                                          │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                                 │
    │  │   Zipkin     │  │   Consul     │  │   Vault      │  │    ELK       │                                 │
    │  │  (Tracing)   │  │ (Discovery)  │  │  (Secrets)   │  │   (Logs)     │                                 │
    │  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘                                 │
    │                                                                                                          │
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Cấu Trúc Thư Mục

```
eticket-microservices/
│
├── docker-compose.yml                    # Main docker compose
├── docker-compose.override.yml           # Development overrides
├── docker-compose.prod.yml               # Production config
├── .env                                  # Environment variables
├── .env.example                          # Example env file
│
├── infrastructure/                       # Infrastructure configs
│   ├── nginx/
│   │   ├── nginx.conf                   # Main nginx config
│   │   ├── conf.d/
│   │   │   ├── default.conf             # Default server config
│   │   │   ├── rate-limit.conf          # Rate limiting rules
│   │   │   └── upstream.conf            # Upstream servers
│   │   └── ssl/                         # SSL certificates
│   │
│   ├── prometheus/
│   │   ├── prometheus.yml               # Prometheus config
│   │   └── alert.rules.yml              # Alert rules
│   │
│   ├── grafana/
│   │   ├── provisioning/
│   │   │   ├── dashboards/
│   │   │   └── datasources/
│   │   └── dashboards/                  # JSON dashboard files
│   │
│   ├── elasticsearch/
│   │   └── elasticsearch.yml            # ES config
│   │
│   ├── logstash/
│   │   ├── logstash.conf
│   │   └── pipelines.yml
│   │
│   ├── kibana/
│   │   └── kibana.yml
│   │
│   ├── rabbitmq/
│   │   ├── rabbitmq.conf
│   │   └── definitions.json             # Queues, exchanges setup
│   │
│   └── redis/
│       └── redis.conf
│
├── services/                             # Microservices
│   │
│   ├── api-gateway/                     # API Gateway Service
│   │   ├── Dockerfile
│   │   ├── pom.xml
│   │   └── src/
│   │       └── main/
│   │           ├── java/
│   │           │   └── com/eticket/gateway/
│   │           │       ├── GatewayApplication.java
│   │           │       ├── config/
│   │           │       │   ├── GatewayConfig.java
│   │           │       │   ├── RateLimitConfig.java
│   │           │       │   ├── SecurityConfig.java
│   │           │       │   └── CircuitBreakerConfig.java
│   │           │       ├── filter/
│   │           │       │   ├── JwtAuthFilter.java
│   │           │       │   ├── RateLimitFilter.java
│   │           │       │   └── LoggingFilter.java
│   │           │       └── exception/
│   │           └── resources/
│   │               ├── application.yml
│   │               └── application-docker.yml
│   │
│   ├── user-service/                    # User/Auth Service
│   │   ├── Dockerfile
│   │   ├── pom.xml
│   │   └── src/
│   │       └── main/
│   │           ├── java/
│   │           │   └── com/eticket/user/
│   │           │       ├── UserServiceApplication.java
│   │           │       ├── command/                    # CQRS Command
│   │           │       │   ├── controller/
│   │           │       │   ├── service/
│   │           │       │   ├── handler/
│   │           │       │   └── aggregate/
│   │           │       ├── query/                      # CQRS Query
│   │           │       │   ├── controller/
│   │           │       │   ├── service/
│   │           │       │   └── projection/
│   │           │       ├── domain/
│   │           │       │   ├── entity/
│   │           │       │   ├── event/
│   │           │       │   └── repository/
│   │           │       ├── infrastructure/
│   │           │       │   ├── config/
│   │           │       │   ├── messaging/
│   │           │       │   └── persistence/
│   │           │       └── api/
│   │           │           └── dto/
│   │           └── resources/
│   │               ├── application.yml
│   │               └── application-docker.yml
│   │
│   ├── event-service/                   # Event Management Service
│   │   ├── Dockerfile
│   │   ├── pom.xml
│   │   └── src/
│   │       └── main/
│   │           ├── java/
│   │           │   └── com/eticket/event/
│   │           │       ├── EventServiceApplication.java
│   │           │       ├── command/
│   │           │       │   ├── controller/
│   │           │       │   │   └── EventCommandController.java
│   │           │       │   ├── service/
│   │           │       │   │   └── EventCommandService.java
│   │           │       │   ├── handler/
│   │           │       │   │   └── EventCommandHandler.java
│   │           │       │   └── command/
│   │           │       │       ├── CreateEventCommand.java
│   │           │       │       └── UpdateEventCommand.java
│   │           │       ├── query/
│   │           │       │   ├── controller/
│   │           │       │   │   └── EventQueryController.java
│   │           │       │   ├── service/
│   │           │       │   │   └── EventQueryService.java
│   │           │       │   └── projection/
│   │           │       │       └── EventProjection.java
│   │           │       ├── domain/
│   │           │       │   ├── entity/
│   │           │       │   │   ├── EventEntity.java
│   │           │       │   │   ├── ZoneEntity.java
│   │           │       │   │   └── SeatEntity.java
│   │           │       │   ├── event/
│   │           │       │   │   ├── EventCreatedEvent.java
│   │           │       │   │   └── EventUpdatedEvent.java
│   │           │       │   └── repository/
│   │           │       │       └── EventRepository.java
│   │           │       └── infrastructure/
│   │           │           ├── config/
│   │           │           ├── elasticsearch/
│   │           │           │   ├── EventDocument.java
│   │           │           │   └── EventSearchRepository.java
│   │           │           └── messaging/
│   │           │               ├── EventPublisher.java
│   │           │               └── EventConsumer.java
│   │           └── resources/
│   │               ├── application.yml
│   │               └── application-docker.yml
│   │
│   ├── order-service/                   # Order + Ticket Service
│   │   ├── Dockerfile
│   │   ├── pom.xml
│   │   └── src/
│   │       └── main/
│   │           ├── java/
│   │           │   └── com/eticket/order/
│   │           │       ├── OrderServiceApplication.java
│   │           │       ├── command/
│   │           │       │   ├── controller/
│   │           │       │   │   └── OrderCommandController.java
│   │           │       │   ├── service/
│   │           │       │   │   └── OrderCommandService.java
│   │           │       │   ├── handler/
│   │           │       │   │   ├── CreateOrderHandler.java
│   │           │       │   │   └── CancelOrderHandler.java
│   │           │       │   └── saga/
│   │           │       │       └── OrderSaga.java
│   │           │       ├── query/
│   │           │       │   ├── controller/
│   │           │       │   │   └── OrderQueryController.java
│   │           │       │   └── service/
│   │           │       │       └── OrderQueryService.java
│   │           │       ├── domain/
│   │           │       │   ├── entity/
│   │           │       │   │   ├── OrderEntity.java
│   │           │       │   │   └── TicketEntity.java
│   │           │       │   ├── event/
│   │           │       │   │   ├── OrderCreatedEvent.java
│   │           │       │   │   ├── OrderPaidEvent.java
│   │           │       │   │   └── OrderCancelledEvent.java
│   │           │       │   └── repository/
│   │           │       └── infrastructure/
│   │           │           ├── config/
│   │           │           ├── cache/
│   │           │           │   └── OrderCacheService.java
│   │           │           ├── elasticsearch/
│   │           │           └── messaging/
│   │           └── resources/
│   │
│   ├── payment-service/                 # Payment Service
│   │   ├── Dockerfile
│   │   ├── pom.xml
│   │   └── src/
│   │       └── main/
│   │           ├── java/
│   │           │   └── com/eticket/payment/
│   │           │       ├── PaymentServiceApplication.java
│   │           │       ├── controller/
│   │           │       │   ├── PaymentController.java
│   │           │       │   └── WebhookController.java
│   │           │       ├── service/
│   │           │       │   ├── PaymentService.java
│   │           │       │   ├── OnepayService.java
│   │           │       │   └── VnpayService.java
│   │           │       ├── domain/
│   │           │       │   ├── entity/
│   │           │       │   │   └── PaymentEntity.java
│   │           │       │   └── event/
│   │           │       │       ├── PaymentInitiatedEvent.java
│   │           │       │       ├── PaymentSuccessEvent.java
│   │           │       │       └── PaymentFailedEvent.java
│   │           │       └── infrastructure/
│   │           │           └── messaging/
│   │           │               └── PaymentEventPublisher.java
│   │           └── resources/
│   │
│   ├── notification-service/            # Notification Service
│   │   ├── Dockerfile
│   │   ├── pom.xml
│   │   └── src/
│   │       └── main/
│   │           ├── java/
│   │           │   └── com/eticket/notification/
│   │           │       ├── NotificationServiceApplication.java
│   │           │       ├── service/
│   │           │       │   ├── EmailService.java
│   │           │       │   ├── SmsService.java
│   │           │       │   └── PushNotificationService.java
│   │           │       ├── consumer/
│   │           │       │   └── NotificationConsumer.java
│   │           │       └── template/
│   │           │           └── EmailTemplateService.java
│   │           └── resources/
│   │               └── templates/
│   │                   ├── order-confirmation.html
│   │                   └── ticket-email.html
│   │
│   └── common/                          # Shared Library
│       ├── pom.xml
│       └── src/
│           └── main/
│               └── java/
│                   └── com/eticket/common/
│                       ├── dto/
│                       │   ├── ApiResponse.java
│                       │   └── PageResponse.java
│                       ├── event/
│                       │   └── DomainEvent.java
│                       ├── exception/
│                       │   ├── BaseException.java
│                       │   └── GlobalExceptionHandler.java
│                       └── util/
│                           └── JwtUtil.java
│
├── frontend/                            # Next.js Frontend (existing)
│   ├── Dockerfile
│   └── ...
│
└── scripts/                             # Utility scripts
    ├── init-db.sh
    ├── init-es-indices.sh
    ├── init-rabbitmq.sh
    └── backup-db.sh
```

---

## 3. Chi Tiết Từng Service

### 3.1 API Gateway Service

**Chức năng:**

- Routing requests đến các microservices
- JWT Authentication & Authorization
- Rate Limiting (per user/IP)
- Circuit Breaker (Resilience4j)
- Request/Response logging
- CORS handling

**Tech Stack:**

- Spring Cloud Gateway
- Spring Security
- Resilience4j
- Redis (for rate limit storage)

### 3.2 User Service

**Chức năng:**

- Đăng ký, đăng nhập
- Quản lý profile
- JWT token generation
- Password reset

**CQRS Pattern:**

- **Command Side:** MySQL (write)
- **Query Side:** Elasticsearch (read)

### 3.3 Event Service

**Chức năng:**

- CRUD events (concerts, sports, etc.)
- Quản lý zones và seats
- Seat availability checking
- Event searching & filtering

**CQRS Pattern:**

- **Command Side:** MySQL (write)
- **Query Side:** Elasticsearch (full-text search)

### 3.4 Order Service

**Chức năng:**

- Tạo order và tickets
- Order status management
- Seat reservation (with distributed lock)
- Order history

**CQRS + Saga Pattern:**

- Command → Create Order → Reserve Seats → Process Payment → Confirm/Rollback

### 3.5 Payment Service

**Chức năng:**

- OnePay/VNPay integration
- Payment processing
- Webhook handling
- Refund processing

### 3.6 Notification Service

**Chức năng:**

- Email notifications
- SMS notifications
- Push notifications
- Template management

---

## 4. Flow Công Việc

### 📌 PHASE 1: Infrastructure Setup (Tuần 1-2)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 1.1: Setup Docker Infrastructure                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Tạo docker-compose.yml với các services:                                 │
│    - MySQL (primary database)                                                │
│    - Redis (distributed cache)                                               │
│    - RabbitMQ (message broker)                                              │
│    - Elasticsearch (search & read model)                                     │
│    - Kibana (ES visualization)                                              │
│    - Prometheus (metrics)                                                    │
│    - Grafana (dashboards)                                                   │
│    - Zipkin (distributed tracing)                                           │
│                                                                              │
│ 2. Cấu hình networks:                                                       │
│    - frontend-network (nginx, frontend)                                      │
│    - backend-network (services)                                              │
│    - monitoring-network (prometheus, grafana)                               │
│                                                                              │
│ 3. Cấu hình volumes cho persistent data                                     │
│                                                                              │
│ Commands:                                                                    │
│   $ docker-compose -f docker-compose.infra.yml up -d                        │
│   $ docker-compose ps                                                        │
│   $ docker-compose logs -f                                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 1.2: Setup Nginx Load Balancer                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Cấu hình upstream servers                                                │
│ 2. Cấu hình rate limiting:                                                  │
│    - limit_req_zone (request rate)                                          │
│    - limit_conn_zone (connections)                                          │
│ 3. Cấu hình SSL termination                                                 │
│ 4. Cấu hình routing rules                                                   │
│                                                                              │
│ File: infrastructure/nginx/nginx.conf                                        │
│                                                                              │
│ nginx.conf structure:                                                        │
│   upstream api_gateway {                                                     │
│       least_conn;                                                            │
│       server gateway-1:8080 weight=3;                                        │
│       server gateway-2:8080 weight=3;                                        │
│   }                                                                          │
│                                                                              │
│   limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 1.3: Setup Monitoring Stack                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Prometheus configuration:                                                 │
│    - Scrape configs cho mỗi service                                         │
│    - Alert rules                                                             │
│                                                                              │
│ 2. Grafana dashboards:                                                       │
│    - JVM metrics dashboard                                                   │
│    - API metrics dashboard                                                   │
│    - Infrastructure dashboard                                                │
│                                                                              │
│ 3. ELK Stack cho logging:                                                   │
│    - Logstash pipelines                                                      │
│    - Kibana index patterns                                                   │
│                                                                              │
│ Access URLs:                                                                 │
│   - Grafana: http://localhost:3000                                          │
│   - Prometheus: http://localhost:9090                                        │
│   - Kibana: http://localhost:5601                                           │
│   - RabbitMQ: http://localhost:15672                                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📌 PHASE 2: Common Library & API Gateway (Tuần 2-3)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 2.1: Create Common Library                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Tạo shared DTOs:                                                          │
│    - ApiResponse<T>                                                          │
│    - PageResponse<T>                                                         │
│    - ErrorResponse                                                           │
│                                                                              │
│ 2. Tạo base exceptions:                                                      │
│    - BaseException                                                           │
│    - NotFoundException                                                       │
│    - ValidationException                                                     │
│    - UnauthorizedException                                                   │
│                                                                              │
│ 3. Tạo domain events base:                                                  │
│    - DomainEvent interface                                                   │
│    - EventMetadata                                                           │
│                                                                              │
│ 4. Utilities:                                                                │
│    - JwtUtil                                                                 │
│    - DateTimeUtil                                                            │
│                                                                              │
│ Build & Install:                                                             │
│   $ cd services/common                                                       │
│   $ mvn clean install                                                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 2.2: Create API Gateway Service                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Setup Spring Cloud Gateway                                               │
│                                                                              │
│ 2. Configure routes:                                                         │
│    /api/v1/users/**     → user-service                                      │
│    /api/v1/events/**    → event-service                                     │
│    /api/v1/orders/**    → order-service                                     │
│    /api/v1/payments/**  → payment-service                                   │
│                                                                              │
│ 3. Implement filters:                                                        │
│    - JwtAuthenticationFilter (validate JWT)                                  │
│    - RateLimitFilter (Redis-based)                                          │
│    - RequestLoggingFilter                                                    │
│    - ResponseLoggingFilter                                                   │
│                                                                              │
│ 4. Configure Circuit Breaker:                                               │
│    - Resilience4j config                                                     │
│    - Fallback handlers                                                       │
│                                                                              │
│ 5. Rate Limit Config (Redis):                                               │
│    - Per user: 100 requests/minute                                          │
│    - Per IP: 1000 requests/minute                                           │
│    - Per endpoint: configurable                                              │
│                                                                              │
│ Key Dependencies:                                                            │
│   - spring-cloud-starter-gateway                                             │
│   - spring-boot-starter-data-redis-reactive                                  │
│   - spring-cloud-starter-circuitbreaker-resilience4j                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📌 PHASE 3: User Service with CQRS (Tuần 3-4)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 3.1: User Service - Command Side                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Domain Layer:                                                             │
│    - UserEntity (JPA entity for MySQL)                                      │
│    - UserAggregate (domain logic)                                            │
│    - Domain Events:                                                          │
│      · UserRegisteredEvent                                                   │
│      · UserUpdatedEvent                                                      │
│      · PasswordChangedEvent                                                  │
│                                                                              │
│ 2. Command Layer:                                                            │
│    - Commands:                                                               │
│      · RegisterUserCommand                                                   │
│      · UpdateProfileCommand                                                  │
│      · ChangePasswordCommand                                                 │
│    - CommandHandlers:                                                        │
│      · RegisterUserHandler                                                   │
│      · UpdateProfileHandler                                                  │
│                                                                              │
│ 3. Infrastructure:                                                           │
│    - MySQL repository                                                        │
│    - Event publisher (RabbitMQ)                                              │
│                                                                              │
│ Flow:                                                                        │
│   Controller → Command → Handler → Repository (MySQL)                        │
│                              ↓                                               │
│                        EventPublisher → RabbitMQ                             │
│                                              ↓                               │
│                                    Query Side Consumer                       │
│                                              ↓                               │
│                                      Elasticsearch                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 3.2: User Service - Query Side                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Elasticsearch Documents:                                                  │
│    - UserDocument (ES mapping)                                               │
│                                                                              │
│ 2. Query Layer:                                                              │
│    - Queries:                                                                │
│      · GetUserByIdQuery                                                      │
│      · SearchUsersQuery                                                      │
│    - QueryHandlers:                                                          │
│      · GetUserByIdHandler                                                    │
│      · SearchUsersHandler                                                    │
│                                                                              │
│ 3. Event Consumers:                                                          │
│    - UserEventConsumer                                                       │
│      · Handle UserRegisteredEvent → Index to ES                              │
│      · Handle UserUpdatedEvent → Update ES document                          │
│                                                                              │
│ 4. Projections:                                                              │
│    - UserProjection (sync MySQL → ES)                                        │
│                                                                              │
│ ES Index Mapping:                                                            │
│   {                                                                          │
│     "mappings": {                                                            │
│       "properties": {                                                        │
│         "id": { "type": "keyword" },                                         │
│         "email": { "type": "keyword" },                                      │
│         "fullName": { "type": "text", "analyzer": "standard" },             │
│         "createdAt": { "type": "date" }                                      │
│       }                                                                      │
│     }                                                                        │
│   }                                                                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📌 PHASE 4: Event Service with CQRS (Tuần 4-5)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 4.1: Event Service - Command Side                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Domain Entities (MySQL):                                                  │
│    - EventEntity                                                             │
│    - ZoneEntity                                                              │
│    - SeatEntity                                                              │
│                                                                              │
│ 2. Commands:                                                                 │
│    - CreateEventCommand                                                      │
│    - UpdateEventCommand                                                      │
│    - PublishEventCommand                                                     │
│    - CreateZoneCommand                                                       │
│    - UpdateSeatStatusCommand                                                 │
│                                                                              │
│ 3. Domain Events:                                                            │
│    - EventCreatedEvent                                                       │
│    - EventUpdatedEvent                                                       │
│    - EventPublishedEvent                                                     │
│    - SeatReservedEvent                                                       │
│    - SeatReleasedEvent                                                       │
│                                                                              │
│ 4. Distributed Lock (Redis) for seat reservation:                           │
│    - Redisson distributed lock                                               │
│    - Lock timeout: 30 seconds                                                │
│    - Retry mechanism                                                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 4.2: Event Service - Query Side (Elasticsearch)                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. ES Documents:                                                             │
│    - EventDocument                                                           │
│    - ZoneDocument (nested)                                                   │
│                                                                              │
│ 2. Search Features:                                                          │
│    - Full-text search (event name, description)                              │
│    - Filter by date range                                                    │
│    - Filter by category                                                      │
│    - Filter by price range                                                   │
│    - Filter by location                                                      │
│    - Sorting (date, price, popularity)                                       │
│    - Pagination                                                              │
│                                                                              │
│ 3. ES Index Mapping:                                                         │
│    {                                                                         │
│      "mappings": {                                                           │
│        "properties": {                                                       │
│          "id": { "type": "keyword" },                                        │
│          "name": {                                                           │
│            "type": "text",                                                   │
│            "analyzer": "vietnamese",                                         │
│            "fields": { "keyword": { "type": "keyword" } }                   │
│          },                                                                  │
│          "description": { "type": "text", "analyzer": "vietnamese" },       │
│          "category": { "type": "keyword" },                                  │
│          "eventDate": { "type": "date" },                                    │
│          "location": {                                                       │
│            "type": "geo_point"                                               │
│          },                                                                  │
│          "minPrice": { "type": "long" },                                     │
│          "maxPrice": { "type": "long" },                                     │
│          "availableSeats": { "type": "integer" },                            │
│          "zones": {                                                          │
│            "type": "nested",                                                 │
│            "properties": {                                                   │
│              "id": { "type": "keyword" },                                    │
│              "name": { "type": "keyword" },                                  │
│              "price": { "type": "long" },                                    │
│              "availableSeats": { "type": "integer" }                         │
│            }                                                                 │
│          }                                                                   │
│        }                                                                     │
│      }                                                                       │
│    }                                                                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📌 PHASE 5: Order Service with CQRS + Saga (Tuần 5-6)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 5.1: Order Service - Command Side + Saga Pattern                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Domain Entities:                                                          │
│    - OrderEntity                                                             │
│    - TicketEntity                                                            │
│    - OrderStatus enum (PENDING, PAID, CONFIRMED, CANCELLED)                  │
│                                                                              │
│ 2. Commands:                                                                 │
│    - CreateOrderCommand                                                      │
│    - ConfirmOrderCommand                                                     │
│    - CancelOrderCommand                                                      │
│                                                                              │
│ 3. Saga Pattern for Order Creation:                                          │
│                                                                              │
│    ┌──────────────────────────────────────────────────────────────────┐      │
│    │                    ORDER CREATION SAGA                           │      │
│    ├──────────────────────────────────────────────────────────────────┤      │
│    │                                                                  │      │
│    │  Step 1: Create Order (PENDING)                                  │      │
│    │       ↓                                                          │      │
│    │  Step 2: Reserve Seats (Event Service)                          │      │
│    │       ↓ success              ↓ fail                              │      │
│    │  Step 3: Process Payment    → Rollback: Release Seats           │      │
│    │       ↓ success              ↓ fail                              │      │
│    │  Step 4: Confirm Order      → Rollback: Cancel Order            │      │
│    │       ↓                          + Release Seats                 │      │
│    │  Step 5: Generate Tickets                                        │      │
│    │       ↓                                                          │      │
│    │  Step 6: Send Notification                                       │      │
│    │                                                                  │      │
│    └──────────────────────────────────────────────────────────────────┘      │
│                                                                              │
│ 4. Saga Orchestrator Implementation:                                         │
│    - OrderSagaOrchestrator                                                   │
│    - SagaStep interface                                                      │
│    - Compensation logic                                                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 5.2: Order Service - Distributed Cache                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Redis Cache Strategy:                                                     │
│                                                                              │
│    Cache Keys:                                                               │
│    - order:{orderId}           → Order details (TTL: 1 hour)                │
│    - user:orders:{userId}      → User's order list (TTL: 30 min)            │
│    - seat:lock:{eventId}:{seatId} → Seat lock (TTL: 10 min)                 │
│    - event:seats:{eventId}     → Available seats (TTL: 1 min)               │
│                                                                              │
│ 2. Cache Patterns:                                                           │
│    - Cache-Aside (Read)                                                      │
│    - Write-Through (Write)                                                   │
│    - Cache Invalidation on Update                                            │
│                                                                              │
│ 3. Implementation:                                                           │
│    @Cacheable(value = "orders", key = "#orderId")                           │
│    @CacheEvict(value = "orders", key = "#orderId")                          │
│    @CachePut(value = "orders", key = "#result.id")                          │
│                                                                              │
│ 4. Distributed Lock for Seat Reservation:                                   │
│    - Use Redisson RLock                                                      │
│    - Lock: seat:lock:{eventId}:{seatId}                                     │
│    - Wait time: 5 seconds                                                    │
│    - Lease time: 30 seconds                                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📌 PHASE 6: Payment & Notification Services (Tuần 6-7)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 6.1: Payment Service                                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Payment Providers:                                                        │
│    - OnePay integration (existing logic)                                     │
│    - VNPay integration                                                       │
│                                                                              │
│ 2. Payment Flow:                                                             │
│                                                                              │
│    Order Service                Payment Service              Payment Gateway │
│         │                             │                           │          │
│         │─── InitiatePayment ────────→│                           │          │
│         │                             │─── Create Payment URL ───→│          │
│         │←── Payment URL ─────────────│                           │          │
│         │                             │                           │          │
│    [User redirected to payment gateway]                           │          │
│         │                             │                           │          │
│         │                             │←─── IPN Callback ─────────│          │
│         │                             │                           │          │
│         │←── PaymentSuccessEvent ─────│                           │          │
│         │                             │                           │          │
│                                                                              │
│ 3. Domain Events:                                                            │
│    - PaymentInitiatedEvent                                                   │
│    - PaymentSuccessEvent                                                     │
│    - PaymentFailedEvent                                                      │
│    - RefundInitiatedEvent                                                    │
│    - RefundCompletedEvent                                                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 6.2: Notification Service                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Event Consumers:                                                          │
│    - OrderConfirmedEvent → Send confirmation email + SMS                     │
│    - PaymentSuccessEvent → Send payment receipt                              │
│    - TicketGeneratedEvent → Send e-ticket                                    │
│                                                                              │
│ 2. Email Templates (Thymeleaf):                                             │
│    - order-confirmation.html                                                 │
│    - payment-receipt.html                                                    │
│    - e-ticket.html                                                           │
│    - password-reset.html                                                     │
│                                                                              │
│ 3. Notification Channels:                                                    │
│    - Email (JavaMailSender + SMTP)                                          │
│    - SMS (Twilio/Vonage)                                                    │
│    - Push Notification (Firebase)                                            │
│                                                                              │
│ 4. Message Queue Consumers:                                                  │
│    @RabbitListener(queues = "notification.email")                           │
│    @RabbitListener(queues = "notification.sms")                             │
│    @RabbitListener(queues = "notification.push")                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📌 PHASE 7: Message Queue Setup (Pub/Sub) (Tuần 7)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 7.1: RabbitMQ Configuration                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Exchanges:                                                                │
│    - eticket.events (topic exchange)                                        │
│    - eticket.commands (direct exchange)                                      │
│    - eticket.dlx (dead letter exchange)                                     │
│                                                                              │
│ 2. Queues:                                                                   │
│    ┌────────────────────────────────────────────────────────────┐            │
│    │ Exchange: eticket.events                                   │            │
│    ├────────────────────────────────────────────────────────────┤            │
│    │                                                            │            │
│    │  Routing Key              Queue                            │            │
│    │  ─────────────────────────────────────────────────────     │            │
│    │  user.#                   user-service.events              │            │
│    │  event.#                  event-service.events             │            │
│    │  order.#                  order-service.events             │            │
│    │  payment.#                payment-service.events           │            │
│    │  order.confirmed          notification.email               │            │
│    │  payment.success          notification.email               │            │
│    │  *.created                search-indexer.events            │            │
│    │  *.updated                search-indexer.events            │            │
│    │                                                            │            │
│    └────────────────────────────────────────────────────────────┘            │
│                                                                              │
│ 3. Dead Letter Queue:                                                        │
│    - Failed messages retry 3 times                                           │
│    - Then move to DLQ for manual inspection                                  │
│                                                                              │
│ 4. Message Format:                                                           │
│    {                                                                         │
│      "eventId": "uuid",                                                      │
│      "eventType": "OrderCreatedEvent",                                       │
│      "timestamp": "2026-01-18T10:00:00Z",                                   │
│      "aggregateId": "order-123",                                             │
│      "payload": { ... }                                                      │
│    }                                                                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📌 PHASE 8: Testing & Deployment (Tuần 8)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 8.1: Testing Strategy                                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Unit Tests:                                                               │
│    - Domain logic tests                                                      │
│    - Command handlers tests                                                  │
│    - Query handlers tests                                                    │
│                                                                              │
│ 2. Integration Tests:                                                        │
│    - API endpoint tests                                                      │
│    - Database tests (Testcontainers)                                         │
│    - Message queue tests                                                     │
│                                                                              │
│ 3. Contract Tests:                                                           │
│    - Pact tests between services                                             │
│                                                                              │
│ 4. E2E Tests:                                                                │
│    - Full flow tests                                                         │
│    - Performance tests (Gatling)                                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TASK 8.2: Docker Build & Deployment                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ 1. Build all services:                                                       │
│    $ docker-compose build                                                    │
│                                                                              │
│ 2. Run full stack:                                                           │
│    $ docker-compose -f docker-compose.yml \                                  │
│                     -f docker-compose.infra.yml up -d                        │
│                                                                              │
│ 3. Scale services:                                                           │
│    $ docker-compose up -d --scale api-gateway=3                              │
│    $ docker-compose up -d --scale event-service=2                            │
│    $ docker-compose up -d --scale order-service=2                            │
│                                                                              │
│ 4. Health checks:                                                            │
│    $ curl http://localhost/actuator/health                                   │
│                                                                              │
│ 5. View logs:                                                                │
│    $ docker-compose logs -f api-gateway                                      │
│    $ docker-compose logs -f order-service                                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Docker Setup

### 5.1 docker-compose.yml (Services)

```yaml
# File: docker-compose.yml

version: "3.8"

services:
  # ==================== API Gateway ====================
  api-gateway:
    build:
      context: ./services/api-gateway
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - EUREKA_CLIENT_ENABLED=false
    depends_on:
      - redis
      - rabbitmq
    networks:
      - backend-network
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ==================== User Service ====================
  user-service:
    build:
      context: ./services/user-service
      dockerfile: Dockerfile
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/eticket_users
      - SPRING_ELASTICSEARCH_URIS=http://elasticsearch:9200
      - SPRING_RABBITMQ_HOST=rabbitmq
      - SPRING_REDIS_HOST=redis
    depends_on:
      - mysql
      - elasticsearch
      - rabbitmq
      - redis
    networks:
      - backend-network
    deploy:
      replicas: 2

  # ==================== Event Service ====================
  event-service:
    build:
      context: ./services/event-service
      dockerfile: Dockerfile
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/eticket_events
      - SPRING_ELASTICSEARCH_URIS=http://elasticsearch:9200
      - SPRING_RABBITMQ_HOST=rabbitmq
      - SPRING_REDIS_HOST=redis
    depends_on:
      - mysql
      - elasticsearch
      - rabbitmq
      - redis
    networks:
      - backend-network
    deploy:
      replicas: 2

  # ==================== Order Service ====================
  order-service:
    build:
      context: ./services/order-service
      dockerfile: Dockerfile
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/eticket_orders
      - SPRING_ELASTICSEARCH_URIS=http://elasticsearch:9200
      - SPRING_RABBITMQ_HOST=rabbitmq
      - SPRING_REDIS_HOST=redis
    depends_on:
      - mysql
      - elasticsearch
      - rabbitmq
      - redis
    networks:
      - backend-network
    deploy:
      replicas: 2

  # ==================== Payment Service ====================
  payment-service:
    build:
      context: ./services/payment-service
      dockerfile: Dockerfile
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/eticket_payments
      - SPRING_RABBITMQ_HOST=rabbitmq
    depends_on:
      - mysql
      - rabbitmq
    networks:
      - backend-network

  # ==================== Notification Service ====================
  notification-service:
    build:
      context: ./services/notification-service
      dockerfile: Dockerfile
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_RABBITMQ_HOST=rabbitmq
    depends_on:
      - rabbitmq
    networks:
      - backend-network

  # ==================== Frontend ====================
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://nginx/api
    depends_on:
      - api-gateway
    networks:
      - frontend-network

networks:
  frontend-network:
    driver: bridge
  backend-network:
    driver: bridge
```

### 5.2 docker-compose.infra.yml (Infrastructure)

```yaml
# File: docker-compose.infra.yml

version: "3.8"

services:
  # ==================== NGINX Load Balancer ====================
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./infrastructure/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./infrastructure/nginx/conf.d:/etc/nginx/conf.d:ro
      - ./infrastructure/nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - api-gateway
      - frontend
    networks:
      - frontend-network
      - backend-network

  # ==================== MySQL ====================
  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=eticket
    volumes:
      - mysql_data:/var/lib/mysql
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "3306:3306"
    networks:
      - backend-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ==================== Redis ====================
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - backend-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ==================== RabbitMQ ====================
  rabbitmq:
    image: rabbitmq:3-management-alpine
    environment:
      - RABBITMQ_DEFAULT_USER=${RABBITMQ_USER}
      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASS}
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
      - ./infrastructure/rabbitmq/definitions.json:/etc/rabbitmq/definitions.json
    ports:
      - "5672:5672"
      - "15672:15672"
    networks:
      - backend-network
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "check_running"]
      interval: 30s
      timeout: 10s
      retries: 5

  # ==================== Elasticsearch ====================
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - es_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - backend-network
    healthcheck:
      test:
        ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  # ==================== Kibana ====================
  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
    networks:
      - backend-network

  # ==================== Prometheus ====================
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./infrastructure/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - monitoring-network
      - backend-network
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"

  # ==================== Grafana ====================
  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASS}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./infrastructure/grafana/provisioning:/etc/grafana/provisioning
    ports:
      - "3001:3000"
    depends_on:
      - prometheus
    networks:
      - monitoring-network

  # ==================== Zipkin (Tracing) ====================
  zipkin:
    image: openzipkin/zipkin:latest
    ports:
      - "9411:9411"
    networks:
      - backend-network
      - monitoring-network

volumes:
  mysql_data:
  redis_data:
  rabbitmq_data:
  es_data:
  prometheus_data:
  grafana_data:

networks:
  frontend-network:
    driver: bridge
  backend-network:
    driver: bridge
  monitoring-network:
    driver: bridge
```

---

## 6. Hướng Dẫn Triển Khai

### 6.1 Bước 1: Clone và Setup

```bash
# 1. Tạo thư mục project mới
mkdir eticket-microservices
cd eticket-microservices

# 2. Copy file .env.example và chỉnh sửa
cp .env.example .env

# 3. Khởi tạo infrastructure
docker-compose -f docker-compose.infra.yml up -d

# 4. Đợi services healthy
docker-compose -f docker-compose.infra.yml ps

# 5. Initialize databases
./scripts/init-db.sh

# 6. Initialize Elasticsearch indices
./scripts/init-es-indices.sh

# 7. Initialize RabbitMQ exchanges/queues
./scripts/init-rabbitmq.sh
```

### 6.2 Bước 2: Build và Run Services

```bash
# 1. Build common library
cd services/common
mvn clean install
cd ../..

# 2. Build all services
docker-compose build

# 3. Run all services
docker-compose up -d

# 4. Check health
curl http://localhost/actuator/health

# 5. View logs
docker-compose logs -f
```

### 6.3 Bước 3: Verify Setup

```bash
# 1. Check all containers running
docker-compose ps

# 2. Test API Gateway
curl http://localhost/api/v1/events

# 3. Access monitoring tools
# Grafana: http://localhost:3001
# Prometheus: http://localhost:9090
# Kibana: http://localhost:5601
# RabbitMQ: http://localhost:15672
# Zipkin: http://localhost:9411
```

### 6.4 Useful Commands

```bash
# Scale services
docker-compose up -d --scale api-gateway=3 --scale order-service=2

# View specific service logs
docker-compose logs -f order-service

# Restart a service
docker-compose restart order-service

# Stop all
docker-compose down

# Stop and remove volumes (CAREFUL!)
docker-compose down -v

# Rebuild specific service
docker-compose build order-service
docker-compose up -d order-service
```

---

## 📊 Monitoring URLs

| Service       | URL                    | Credentials |
| ------------- | ---------------------- | ----------- |
| Grafana       | http://localhost:3001  | admin/admin |
| Prometheus    | http://localhost:9090  | -           |
| Kibana        | http://localhost:5601  | -           |
| RabbitMQ      | http://localhost:15672 | guest/guest |
| Zipkin        | http://localhost:9411  | -           |
| Elasticsearch | http://localhost:9200  | -           |

---

## 📝 Checklist

- [ ] Phase 1: Infrastructure Setup
  - [ ] Docker Compose files
  - [ ] Nginx configuration
  - [ ] Monitoring stack
- [ ] Phase 2: Common Library & Gateway
  - [ ] Common library
  - [ ] API Gateway
- [ ] Phase 3: User Service
  - [ ] Command side
  - [ ] Query side (ES)
- [ ] Phase 4: Event Service
  - [ ] Command side
  - [ ] Query side (ES)
- [ ] Phase 5: Order Service
  - [ ] Command side + Saga
  - [ ] Distributed cache
- [ ] Phase 6: Payment & Notification
  - [ ] Payment service
  - [ ] Notification service
- [ ] Phase 7: Message Queue
  - [ ] RabbitMQ setup
  - [ ] Event handlers
- [ ] Phase 8: Testing & Deployment
  - [ ] Tests
  - [ ] Production deployment

---

## 🔗 References

- [Spring Cloud Gateway](https://spring.io/projects/spring-cloud-gateway)
- [CQRS Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/cqrs)
- [Saga Pattern](https://microservices.io/patterns/data/saga.html)
- [Elasticsearch Java Client](https://www.elastic.co/guide/en/elasticsearch/client/java-api-client/current/index.html)
- [RabbitMQ Tutorials](https://www.rabbitmq.com/getstarted.html)
- [Resilience4j](https://resilience4j.readme.io/docs)

---

**Author:** eTicket Team  
**Version:** 1.0  
**Last Updated:** January 18, 2026
