/// Supported environments for PhonePe.
enum PhonePeEnvironment { sandbox, production }

extension PhonePeEnvironmentX on PhonePeEnvironment {
  String get baseUrl => switch (this) {
    PhonePeEnvironment.sandbox   => 'https://api-preprod.phonepe.com/apis/pg-sandbox',
    PhonePeEnvironment.production => 'https://api.phonepe.com/apis/hermes',
  };

  String get label =>
      this == PhonePeEnvironment.sandbox ? 'SANDBOX' : 'PRODUCTION';
}
