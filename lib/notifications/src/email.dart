import '../notifications.dart';

// Simulated: counts the emails it would send and needs no network.
class EmailNotificationSender implements NotificationSender {
  int sent = 0;

  @override
  void sendConfirmation(Confirmation confirmation) => sent++;
}
