import '../domain/study_module.dart';
import 'module_storage_keys.dart';

typedef PublicUrlBuilder = String Function(String storagePath);

abstract final class StudyModuleJson {
  static StudyModule fromMap(
    Map<String, dynamic> json, {
    required String description,
    String? coverImageUrl,
    PublicUrlBuilder? publicUrl,
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
      coverImageUrl: publicUrl == null
          ? coverImageUrl
          : _publicUrlOrNull(json['cover_image_path'], publicUrl),
    );
  }
}

String? _publicUrlOrNull(Object? path, PublicUrlBuilder publicUrl) {
  return switch (path) {
    final String value when value.trim().isNotEmpty => publicUrl(value),
    _ => null,
  };
}
