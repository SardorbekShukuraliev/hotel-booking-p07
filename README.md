# P07 · Hotel booking: an HTTP API with PostgreSQL (Dart)

Extract the ZIP and open a terminal in the extracted folder. The project is the finished P07
app: the P06 modules behind an HTTP API on http://localhost:5080, with the reservations in
PostgreSQL. docs/openapi.yaml is the contract; docs/api-check.md has the seven requests and
their answers.

Start Docker Desktop first. Then, once (internet needed the first time):

```text
dart pub get
```

Start PostgreSQL, run the checks, the demo and the race, then start the API:

```text
docker compose up -d
dart test
dart run bin/main.dart --demo
dart run bin/main.dart --race
dart run bin/main.dart            # the API on http://localhost:5080
```

The checks print:

```text
dart test
+15: All tests passed!
```

With the API running, the seven requests of docs/api-check.md answer (status, then body):

```text
GET /rooms/availability?checkIn=2026-11-12&checkOut=2026-11-14
200 {"checkIn":"2026-11-12","checkOut":"2026-11-14","rooms":[{"number":"R7","type":"Standard"},{"number":"R8","type":"Deluxe"}],"next":null}

POST /reservations   {"guestName":"Maya","guestEmail":"maya@example.com","room":"R7","checkIn":"2026-11-12","checkOut":"2026-11-14"}
201 {"id":"R101","status":"Confirmed","notificationFailed":false}

POST /reservations   {"guestName":"Omar","guestEmail":"omar@example.com","room":"R7","checkIn":"2026-11-13","checkOut":"2026-11-15"}
409 {"title":"Unavailable","status":409,"detail":"The room is booked for at least one night of this stay."}

POST /reservations   {"guestName":"Omar","guestEmail":"omar@example.com","room":"R8","checkIn":"2026-11-15","checkOut":"2026-11-15"}
400 {"title":"InvalidDates","status":400,"detail":"checkOut must be after checkIn."}

GET /rooms/availability?checkIn=2026-11-12&checkOut=2026-11-14
200 {"checkIn":"2026-11-12","checkOut":"2026-11-14","rooms":[{"number":"R8","type":"Deluxe"}],"next":null}

DELETE /reservations/R101
204

DELETE /reservations/R101
404 {"title":"NotFound","status":404,"detail":"There is no confirmed reservation R101."}
```

If port 5432 is already taken on your laptop, change "5432:5432" in docker-compose.yml to
"15432:5432" and set HOTEL_DB_PORT=15432 before starting the app.
