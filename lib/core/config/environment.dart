enum Environment {
  dev,
  staging,
  prod;

  static Environment fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'dev':
      case 'development':
        return Environment.dev;

      case 'staging':
      case 'stage':
        return Environment.staging;

      case 'prod':
      case 'production':
        return Environment.prod;

      default:
        return Environment.dev;
    }
  }
}
