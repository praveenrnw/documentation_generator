import 'dart:typed_data';

class GuideStep {
  final String id;
  String title;
  String description;
  final Uint8List? screenshot;
  final Duration timestamp;
  int order;

  GuideStep({
    required this.id,
    required this.title,
    required this.description,
    this.screenshot,
    required this.timestamp,
    required this.order,
  });
}
