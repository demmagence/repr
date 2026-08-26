import 'package:flutter/services.dart';

class AppMetadata {
  const AppMetadata({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  /// Full version string including build number, e.g. "1.0.0+1"
  String get fullVersion =>
      buildNumber.isEmpty ? version : '$version+$buildNumber';

  /// Display version string for user interfaces, e.g. "1.0.0"
  String get displayVersion => version;

  static AppMetadata fromPubspecYaml(String yamlContent) {
    for (final line in yamlContent.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('version:')) {
        final rawVersion = trimmed.substring('version:'.length).trim();
        final parts = rawVersion.split('+');
        final ver = parts.first.trim();
        final build = parts.length > 1 ? parts[1].trim() : '';
        return AppMetadata(version: ver, buildNumber: build);
      }
    }
    return const AppMetadata(version: '1.0.0', buildNumber: '1');
  }

  static const defaultMetadata = AppMetadata(
    version: '1.0.0',
    buildNumber: '1',
  );
}

abstract class AppMetadataService {
  AppMetadata get currentMetadata;
  Future<AppMetadata> getMetadata();
}

class DefaultAppMetadataService implements AppMetadataService {
  DefaultAppMetadataService({this.bundle, AppMetadata? initialMetadata})
    : _cached = initialMetadata;

  final AssetBundle? bundle;
  AppMetadata? _cached;

  @override
  AppMetadata get currentMetadata => _cached ?? AppMetadata.defaultMetadata;

  @override
  Future<AppMetadata> getMetadata() async {
    if (_cached != null) return _cached!;
    try {
      final assetBundle = bundle ?? rootBundle;
      final content = await assetBundle.loadString('pubspec.yaml');
      final parsed = AppMetadata.fromPubspecYaml(content);
      _cached = parsed;
      return parsed;
    } catch (_) {
      return AppMetadata.defaultMetadata;
    }
  }
}
