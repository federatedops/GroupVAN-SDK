import 'part_application_display.dart';

class PartApplication {
  final int id;
  final bool assets;
  final List<PartApplicationDisplay> displays;

  const PartApplication({
    required this.id,
    required this.assets,
    required this.displays,
  });

  factory PartApplication.fromJson(Map<String, dynamic> json) =>
      PartApplication(
        id: json['id'],
        assets: json['assets'],
        displays: (json['displays'] as List<dynamic>)
            .map(
              (d) => PartApplicationDisplay.fromJson(d as Map<String, dynamic>),
            )
            .toList(),
      );
}
