import '../domain/study_module.dart';
import 'module_storage_keys.dart';

abstract final class StudyModuleJson {
  static StudyModule fromMap(
    Map<String, dynamic> json, {
    required String description,
    String? coverImageUrl,
  }) {
    final resources = (json['resources'] as List<dynamic>).cast<String>().map(
      ModuleStorageKeys.resourceFrom,
    );

    return StudyModule(
      id: json['slug'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      area: ModuleStorageKeys.areaFrom(json['area'] as String),
      topicCount: json['topic_count'] as int,
      durationInMinutes: json['duration_in_minutes'] as int,
      resources: Set.unmodifiable(resources),
      description: description,
      coverImageUrl: coverImageUrl,
    );
  }
}
