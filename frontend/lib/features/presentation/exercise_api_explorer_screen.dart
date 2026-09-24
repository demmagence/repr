import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../data/exercise_api_client.dart';
import '../../ui/material/app_ui.dart';
import 'exercise_demo_sheet.dart';

class ExerciseApiExplorerScreen extends ConsumerStatefulWidget {
  const ExerciseApiExplorerScreen({super.key});

  @override
  ConsumerState<ExerciseApiExplorerScreen> createState() =>
      _ExerciseApiExplorerScreenState();
}

class _ExerciseApiExplorerScreenState
    extends ConsumerState<ExerciseApiExplorerScreen> {
  late TextEditingController _urlController;
  late ExerciseApiClient _client;

  String _search = '';
  String? _selectedBodyPart;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isConnected = false;
  List<ExerciseApiModel> _exercises = [];
  List<String> _bodyParts = [];

  @override
  void initState() {
    super.initState();
    final defaultUrl = ExerciseApiClient.defaultBaseUrl;
    _urlController = TextEditingController(text: defaultUrl);
    _client = ExerciseApiClient(baseUrl: defaultUrl);
    _checkConnectionAndLoad();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectionAndLoad() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Memeriksa koneksi ke backend...';
    });

    try {
      final parts = await _client.fetchBodyParts();
      final list = await _client.fetchExercises(
        search: _search.isEmpty ? null : _search,
        bodyPart: _selectedBodyPart,
      );

      if (mounted) {
        setState(() {
          _isConnected = true;
          _bodyParts = parts;
          _exercises = list;
          _statusMessage =
              '✅ Terhubung ke Backend NestJS (${list.length} exercise dimuat)';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _exercises = [];
          _statusMessage =
              '❌ Gagal terhubung: Pastikan backend dan Docker aktif di port 3000.\n($e)';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateBaseUrl(String newUrl) async {
    setState(() {
      _client = ExerciseApiClient(baseUrl: newUrl);
    });
    await _checkConnectionAndLoad();
  }

  Future<void> _importToLocal(ExerciseApiModel item) async {
    final database = ref.read(databaseProvider);

    try {
      await database.createExercise(
        name: item.name,
        muscle: item.bodyPart,
        equipment: item.equipment,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exercise "${item.name}" berhasil disimpan ke SQLite lokal!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppPageShell(
      topBar: AppTopBar(
        title: 'ExerciseDB API Explorer',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: _checkConnectionAndLoad,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: _isConnected ? Colors.green : colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status Backend Proxy',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _isConnected
                        ? Colors.green.shade800
                        : colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: theme.textTheme.bodySmall,
                        decoration: const InputDecoration(
                          labelText: 'Base URL Backend',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Terapkan',
                      expand: false,
                      variant: AppActionVariant.secondary,
                      onPressed: () =>
                          _updateBaseUrl(_urlController.text.trim()),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search and Filters
          AppTextField(
            leading: Icons.search,
            hint: 'Cari exercise dari database API...',
            onChanged: (val) {
              _search = val;
              _checkConnectionAndLoad();
            },
          ),

          if (_bodyParts.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: _selectedBodyPart == null,
                    onSelected: (selected) {
                      setState(() => _selectedBodyPart = null);
                      _checkConnectionAndLoad();
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final part in _bodyParts) ...[
                    ChoiceChip(
                      label: Text(_capitalize(part)),
                      selected: _selectedBodyPart == part,
                      onSelected: (selected) {
                        setState(() {
                          _selectedBodyPart = selected ? part : null;
                        });
                        _checkConnectionAndLoad();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Exercise List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_exercises.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tidak ada data exercise',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isConnected
                          ? 'Coba ganti kata kunci pencarian atau filter bagian tubuh.'
                          : 'Pastikan backend server berjalan di laptop Anda:\ncd backend && npm run start:dev',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final ex in _exercises) ...[
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GIF preview thumbnail or icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: colorScheme.surfaceContainerHighest,
                        child: ex.gifUrl != null && ex.gifUrl!.isNotEmpty
                            ? Image.network(
                                ex.gifUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.fitness_center),
                                ),
                              )
                            : const Center(child: Icon(Icons.fitness_center)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capitalize(ex.name),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _capitalize(ex.bodyPart),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _capitalize(ex.target),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _capitalize(ex.equipment),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              AppButton(
                                label: 'Lihat Gerakan',
                                icon: Icons.play_circle_outline,
                                expand: false,
                                variant: AppActionVariant.quiet,
                                onPressed: () => showExerciseDemoSheet(
                                  context,
                                  exercise: ex,
                                  onSelect: () => _importToLocal(ex),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.download, size: 20),
                                tooltip: 'Simpan ke SQLite Lokal',
                                onPressed: () => _importToLocal(ex),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
