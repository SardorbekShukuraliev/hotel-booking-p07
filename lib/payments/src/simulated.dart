import '../payments.dart';

// Simulated: no card and no network. A positive amount is Paid; anything else is Declined.
class SimulatedPaymentService implements PaymentService {
  @override
  PaymentStatus takeDeposit(String reservationId, int amountCents) =>
      amountCents > 0 ? PaymentStatus.paid : PaymentStatus.declined;
}
