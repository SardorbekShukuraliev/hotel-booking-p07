/// Notifications: telling guests what happened. This file is the module's public contract.
library;

/// Notifications' own message: it no longer needs the Reservation class.
class Confirmation {
  const Confirmation(this.reservationId, this.guestEmail, this.roomNumber, this.checkIn, this.checkOut);

  final String reservationId;
  final String guestEmail;
  final String roomNumber;
  final DateTime checkIn;
  final DateTime checkOut;
}

// Notifications' public contract: "tell the guest". How the message travels is its own business.
abstract interface class NotificationSender {
  void sendConfirmation(Confirmation confirmation);
}
