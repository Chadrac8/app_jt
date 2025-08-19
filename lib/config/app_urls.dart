class AppConfig {
  // URL Configuration
  static const String baseUrl = 'https://app.jubiletabernacle.org';
  static const String firebaseUrl = 'https://hjye25u8iwm0i0zls78urffsc0jcgj.web.app';
  
  // Form URLs
  static String generatePublicFormUrl(String formId) {
    return '$baseUrl/forms/$formId';
  }
  
  // Page URLs
  static String generatePageUrl(String pageSlug) {
    return '$baseUrl/pages/$pageSlug';
  }
  
  // Event URLs
  static String generateEventUrl(String eventId) {
    return '$baseUrl/events/$eventId';
  }
  
  // API Configuration
  static const String apiVersion = 'v1';
  static const String apiPrefix = '/api/$apiVersion';
  
  // Sharing URLs
  static String generateShareUrl(String type, String id) {
    switch (type) {
      case 'form':
        return generatePublicFormUrl(id);
      case 'page':
        return generatePageUrl(id);
      case 'event':
        return generateEventUrl(id);
      default:
        return baseUrl;
    }
  }
}
