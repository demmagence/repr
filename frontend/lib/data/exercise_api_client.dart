import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'database.dart';

class ExerciseApiModel {
  const ExerciseApiModel({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    this.gifUrl,
    required this.target,
    this.secondaryMuscles = const [],
    this.instructions = const [],
  });

  final String id;
  final String name;
  final String bodyPart;
  final String equipment;
  final String? gifUrl;
  final String target;
  final List<String> secondaryMuscles;
  final List<String> instructions;

  factory ExerciseApiModel.fromJson(Map<String, dynamic> json) {
    return ExerciseApiModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      bodyPart: json['bodyPart'] as String? ?? '',
      equipment: json['equipment'] as String? ?? '',
      gifUrl: json['gifUrl'] as String?,
      target: json['target'] as String? ?? '',
      secondaryMuscles:
          (json['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      instructions:
          (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bodyPart': bodyPart,
    'equipment': equipment,
    'gifUrl': gifUrl,
    'target': target,
    'secondaryMuscles': secondaryMuscles,
    'instructions': instructions,
  };

  static ExerciseApiModel fromLocal(Exercise item) {
    List<String> sec = const [];
    if (item.secondaryMuscles != null && item.secondaryMuscles!.isNotEmpty) {
      try {
        final decoded = jsonDecode(item.secondaryMuscles!);
        if (decoded is List) {
          sec = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    List<String> inst = const [];
    if (item.instructions != null && item.instructions!.isNotEmpty) {
      try {
        final decoded = jsonDecode(item.instructions!);
        if (decoded is List) {
          inst = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return ExerciseApiModel(
      id: item.id,
      name: item.name,
      bodyPart: item.bodyPart ?? item.muscle,
      equipment: item.equipment,
      gifUrl: item.gifUrl,
      target: item.target ?? item.muscle,
      secondaryMuscles: sec,
      instructions: inst,
    );
  }
}

class ExerciseApiClient {
  ExerciseApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Default URL: 10.0.2.2 for Android emulator, localhost for others
  static String get defaultBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  /// Media base URL (without /api prefix)
  static String get defaultMediaBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Resolves an image URL. If it's a relative path (e.g. /media/exercises/0025.jpg),
  /// prefixes it with the backend media host.
  static String resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final prefix = defaultMediaBaseUrl;
    if (trimmed.startsWith('/')) {
      return '$prefix$trimmed';
    }
    return '$prefix/$trimmed';
  }

  Future<List<ExerciseApiModel>> fetchExercises({
    String? search,
    String? bodyPart,
    String? target,
    String? equipment,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (bodyPart != null && bodyPart.isNotEmpty) {
      queryParams['bodyPart'] = bodyPart;
    }
    if (target != null && target.isNotEmpty) queryParams['target'] = target;
    if (equipment != null && equipment.isNotEmpty) {
      queryParams['equipment'] = equipment;
    }

    final uri = Uri.parse(
      '$_baseUrl/exercises',
    ).replace(queryParameters: queryParams);

    final response = await _client.get(uri).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded is Map && decoded.containsKey('data')
          ? decoded['data'] as List<dynamic>
          : (decoded is List ? decoded : []);
      return data
          .map(
            (item) => ExerciseApiModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else {
      throw Exception('Failed to load exercises: ${response.statusCode}');
    }
  }

  Future<ExerciseApiModel> fetchExercise(String id) async {
    final uri = Uri.parse('$_baseUrl/exercises/$id');
    final response = await _client.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return ExerciseApiModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Exercise not found: ${response.statusCode}');
    }
  }

  Future<List<String>> fetchBodyParts() async {
    final uri = Uri.parse('$_baseUrl/exercises/bodyParts');
    final response = await _client.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Sinkronkan seluruh katalog exercise dari backend ke database SQLite lokal.
  Future<int> syncAllExercisesToDatabase(
    AppDatabase database, {
    int maxTotal = 200,
  }) async {
    int totalSynced = 0;
    int offset = 0;
    const pageSize = 50;

    while (offset < maxTotal) {
      final batch = await fetchExercises(limit: pageSize, offset: offset);
      if (batch.isEmpty) break;
      final inserted = await database.upsertExercisesFromApi(batch);
      totalSynced += inserted;
      if (batch.length < pageSize) break;
      offset += pageSize;
    }
    return totalSynced;
  }
}
