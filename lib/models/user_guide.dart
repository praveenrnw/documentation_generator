import 'guide_step.dart';

class UserGuide {
  final String id;
  String title;
  String description;
  final List<GuideStep> steps;
  final DateTime createdAt;
  DateTime updatedAt;

  UserGuide({
    required this.id,
    required this.title,
    this.description = '',
    required this.steps,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
}
