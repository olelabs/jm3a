/// App-wide constant values. No magic numbers in feature code.
abstract final class AppConstants {
  static const int maxRoomPlayers    = 12;
  static const int minPackCards      = 50;
  static const int maxPackCards      = 100;
  static const int otpLength         = 6;
  static const int otpTtlSeconds     = 300;
  static const int packAccessMonths  = 3;
  static const int minWithdrawalMru  = 500;
  static const double platformCommission = 0.15;
  static const int chatMaxLength     = 500;
  static const int bioMaxLength      = 280;
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 30;
  static const int reconnectGraceSeconds = 30;
}
