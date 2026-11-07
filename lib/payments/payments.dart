/// Payments: deposits and whether they were paid. This file is the module's public contract.
library;

enum PaymentStatus { paid, declined }

// Booking does not call it yet: the booking saga uses it in P17. The amount is in cents.
abstract interface class PaymentService {
  PaymentStatus takeDeposit(String reservationId, int amountCents);
}
