class PublicSettings {
  const PublicSettings({
    required this.appDisplayName,
    required this.ethicalDisclaimer,
    required this.maintenanceMode,
  });

  final String appDisplayName;
  final String ethicalDisclaimer;
  final bool maintenanceMode;

  factory PublicSettings.fromJson(Map<String, dynamic> json) {
    return PublicSettings(
      appDisplayName: json['app_display_name'] as String? ?? 'AVOV',
      ethicalDisclaimer: json['ethical_disclaimer'] as String? ?? '',
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
    );
  }
}
