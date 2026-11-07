# Hotel Booking API - P08 (Redis Cache & Benchmarks)

This repository contains the completed P08 assignment for the Hotel Booking application. 
The app is built with **Dart** and runs on an HTTP server. In P08, we implemented a **Cache-aside** pattern using **Redis** to drastically improve search performance and reduce the load on the PostgreSQL database.

## 🏗️ Architecture & Decisions

*   **Cache-aside (Lazy Loading):** The search endpoint (`GET /rooms/availability`) checks Redis first. On a hit, it returns the cached data. On a miss, it queries PostgreSQL and saves the result in Redis.
*   **TTL (Time to Live):** 30 seconds. This ensures that even if an invalidation is missed, the stale data is corrected automatically.
*   **Invalidation:** After a successful booking (`POST`) or cancellation (`DELETE`), the app increments `availability:version`. This makes all old cache keys unreachable instantly.
*   **Source of Truth:** PostgreSQL is always the source of truth for the booking rule. The cache is *never* read during booking to prevent double-booking.
*   **Instrumentation:** Added `GET /stats` to track searches, DB queries, cache hits/misses, and average internal processing time.

## 📊 Performance Results (Benchmarks)

We compared the performance of 1,000 searches **with** and **without** the cache using custom Dart benchmark tools compiled to native executables.

| Metric | Without Cache (Pure PostgreSQL) | With Cache (Redis Cache-Aside) | Improvement |
| :--- | :--- | :--- | :--- |
| **Database Queries** | 2,000 | **2** | **1000x less load** |
| **Average HTTP Time** | 3.30 ms | **1.21 ms** | ~3x faster |
| **p95 HTTP Time** | 4.04 ms | **1.43 ms** | ~3x faster |
| **Internal Server Time** | N/A | **0.91 ms** | Meets `< 1ms` requirement |

> *Note on timings: The HTTP times on Windows via Docker/WSL2 have a physical network floor (~1.0 ms). The internal server time (excluding network overhead) is measured via the `/stats` endpoint and is strictly `< 1ms`.*

## 🚀 How to Run

### 1. Start the Infrastructure (Docker)
Ensure Docker Desktop is running.
```bash
docker compose up -d


2. Run the Application
To run in development mode:

bash
dart run bin/main.dart
To run the compiled, high-performance executable (recommended for benchmarks):

bash
dart compile exe bin/main.dart -o bin/server.exe
./bin/server.exe
3. Run Tests
To ensure the business logic and cache invalidation work correctly:

bash
dart test
Expected result: 17 tests passed.

4. Run Benchmarks
Keep the server running in one terminal. Open a second terminal and run:

Without Cache: ./tool/no_cache_test.exe

With Cache: ./tool/benchmark.exe

🔍 Endpoints
GET /rooms/availability?checkIn=YYYY-MM-DD&checkOut=YYYY-MM-DD - Search for rooms (Cached).

POST /reservations - Book a room (Invalidates cache).

DELETE /reservations/{id} - Cancel a booking (Invalidates cache).

GET /stats - Monitoring (DB queries, Cache hits/misses, Internal time).

GET /openapi.yaml - API Contract.