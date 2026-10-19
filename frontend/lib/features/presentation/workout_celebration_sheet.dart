import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/metrics.dart';
import '../../data/database.dart';

enum CelebrationThemeStyle {
  classicWhite,
  obsidianDark,
  cyberNeon,
}

enum ComparisonKind {
  kitten,
  panda,
  lion,
  horse,
  elephant,
  trex,
  jet,
}

class WeightComparisonData {
  const WeightComparisonData({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.minKg,
    required this.maxKg,
  });

  final ComparisonKind kind;
  final String title;
  final String subtitle;
  final String emoji;
  final double minKg;
  final double maxKg;
}

const List<WeightComparisonData> defaultWeightComparisons = [
  WeightComparisonData(
    kind: ComparisonKind.kitten,
    title: 'Anak Kucing',
    subtitle: 'Itu setara dengan mengangkat sekotak anak kucing yang lucu!',
    emoji: '🐱',
    minKg: 0,
    maxKg: 40,
  ),
  WeightComparisonData(
    kind: ComparisonKind.panda,
    title: 'Panda Raksasa',
    subtitle: 'Itu setara dengan mengangkat seekor panda raksasa!',
    emoji: '🐼',
    minKg: 40,
    maxKg: 150,
  ),
  WeightComparisonData(
    kind: ComparisonKind.lion,
    title: 'Singa Jantan Dewasa',
    subtitle: 'Itu setara dengan mengangkat seekor singa jantan dewasa!',
    emoji: '🦁',
    minKg: 150,
    maxKg: 450,
  ),
  WeightComparisonData(
    kind: ComparisonKind.horse,
    title: 'Kuda Perkasa',
    subtitle: 'Itu setara dengan mengangkat seekor kuda perkasa!',
    emoji: '🐎',
    minKg: 450,
    maxKg: 1200,
  ),
  WeightComparisonData(
    kind: ComparisonKind.elephant,
    title: 'Gajah Afrika',
    subtitle: 'Itu setara dengan mengangkat seekor gajah!',
    emoji: '🐘',
    minKg: 1200,
    maxKg: 7000,
  ),
  WeightComparisonData(
    kind: ComparisonKind.trex,
    title: 'Dinosaurus T-Rex',
    subtitle: 'Itu setara dengan mengangkat seekor dinosaurus T-Rex!',
    emoji: '🦖',
    minKg: 7000,
    maxKg: 15000,
  ),
  WeightComparisonData(
    kind: ComparisonKind.jet,
    title: 'Jet Tempur Supersonik',
    subtitle: 'Itu setara dengan mengangkat sebuah pesawat jet tempur!',
    emoji: '✈️',
    minKg: 15000,
    maxKg: double.infinity,
  ),
];

int resolveComparisonIndex(double volumeKg) {
  for (var i = 0; i < defaultWeightComparisons.length; i++) {
    final item = defaultWeightComparisons[i];
    if (volumeKg >= item.minKg && volumeKg < item.maxKg) {
      return i;
    }
  }
  // Default fallback to elephant if volume is large or unspecified
  return 4;
}

class CelebrationGreeting {
  const CelebrationGreeting({required this.title, required this.emoji});
  final String title;
  final String emoji;

  String get fullTitle => '$title $emoji';
}

const List<CelebrationGreeting> defaultCelebrationGreetings = [
  CelebrationGreeting(title: 'Kerja bagus!', emoji: '🎉'),
  CelebrationGreeting(title: 'Latihan mantap!', emoji: '🔥'),
  CelebrationGreeting(title: 'Keren banget!', emoji: '💥'),
  CelebrationGreeting(title: 'Gokil, tuntas!', emoji: '🚀'),
  CelebrationGreeting(title: 'Luar biasa!', emoji: '🏆'),
  CelebrationGreeting(title: 'Disiplin juara!', emoji: '👑'),
  CelebrationGreeting(title: 'Level up hari ini!', emoji: '⚡'),
  CelebrationGreeting(title: 'Tak terhentikan!', emoji: '🦾'),
  CelebrationGreeting(title: 'Sesi yang solid!', emoji: '🏋️'),
  CelebrationGreeting(title: 'Terus konsisten!', emoji: '🎯'),
  CelebrationGreeting(title: 'Power maksimal!', emoji: '💪'),
  CelebrationGreeting(title: 'Habis-habisan!', emoji: '🔥'),
  CelebrationGreeting(title: 'Gaspol terus!', emoji: '🏎️'),
  CelebrationGreeting(title: 'Hasil tak bohong!', emoji: '✨'),
  CelebrationGreeting(title: 'Fokus & konsisten!', emoji: '💯'),
];

Future<void> showWorkoutCelebration(
  BuildContext context, {
  required WorkoutCompletionSummary summary,
  required String weightUnit,
  String? userName,
  CelebrationGreeting? initialGreeting,
}) async {
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => WorkoutCelebrationScreen(
        summary: summary,
        weightUnit: weightUnit,
        userName: userName,
        initialGreeting: initialGreeting,
      ),
    ),
  );
}

class WorkoutCelebrationScreen extends StatefulWidget {
  const WorkoutCelebrationScreen({
    required this.summary,
    required this.weightUnit,
    this.userName,
    this.initialGreeting,
    super.key,
  });

  final WorkoutCompletionSummary summary;
  final String weightUnit;
  final String? userName;
  final CelebrationGreeting? initialGreeting;

  @override
  State<WorkoutCelebrationScreen> createState() =>
      _WorkoutCelebrationScreenState();
}

class _WorkoutCelebrationScreenState extends State<WorkoutCelebrationScreen> {
  late final PageController _pageController;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  int _currentPage = 0;
  late int _selectedComparisonIndex;
  late final CelebrationGreeting _greeting;
  CelebrationThemeStyle _themeStyle = CelebrationThemeStyle.classicWhite;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedComparisonIndex = resolveComparisonIndex(widget.summary.volumeKg);
    _greeting = widget.initialGreeting ??
        defaultCelebrationGreetings[
            Random().nextInt(defaultCelebrationGreetings.length)];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _cycleTheme() {
    setState(() {
      switch (_themeStyle) {
        case CelebrationThemeStyle.classicWhite:
          _themeStyle = CelebrationThemeStyle.obsidianDark;
          break;
        case CelebrationThemeStyle.obsidianDark:
          _themeStyle = CelebrationThemeStyle.cyberNeon;
          break;
        case CelebrationThemeStyle.cyberNeon:
          _themeStyle = CelebrationThemeStyle.classicWhite;
          break;
      }
    });
  }

  void _cycleComparison() {
    setState(() {
      _selectedComparisonIndex =
          (_selectedComparisonIndex + 1) % defaultWeightComparisons.length;
    });
  }

  Future<Uint8List?> _captureCardBytes() async {
    try {
      final boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing card image: $e');
      return null;
    }
  }

  Future<void> _shareCard({bool isInstagramStory = false}) async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true);

    try {
      final bytes = await _captureCardBytes();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuat gambar kartu.')),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/repr_card_$timestamp.png');
      await file.writeAsBytes(bytes);

      if (isInstagramStory) {
        await _shareToInstagramStory(file);
      } else {
        final shareText =
            'Selesai latihan di Repr! 💪🏋️ ${widget.summary.workoutName} • '
            '${widget.summary.completedSets} Set • '
            '${(widget.weightUnit == 'lbs' ? widget.summary.volumeKg * kgToLbsMultiplier : widget.summary.volumeKg).toStringAsFixed(0)} ${widget.weightUnit}\n'
            '#Repr #Workout #Fitness';

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            text: shareText,
            subject: 'Workout Repr',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan kartu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _shareToInstagramStory(File imageFile) async {
    bool launchedDirectly = false;
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.demmagence.repr/instagram_story');
        final result = await platform.invokeMethod<bool>(
          'shareToInstagramStory',
          {'filePath': imageFile.path},
        );
        launchedDirectly = result == true;
      } catch (e) {
        debugPrint('Instagram story direct intent error: $e');
      }
    }

    if (!launchedDirectly) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imageFile.path, mimeType: 'image/png')],
          text: 'Selesai latihan di Repr! 💪🏋️\n#Repr #Workout',
          subject: 'Workout Repr Story',
        ),
      );
    }
  }

  Future<void> _downloadCard() async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true);

    try {
      final bytes = await _captureCardBytes();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuat gambar.')),
          );
        }
        return;
      }

      Directory? targetDir;
      try {
        if (Platform.isAndroid) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final picturesDir = Directory('${externalDir.path}/Pictures');
            if (!await picturesDir.exists()) {
              await picturesDir.create(recursive: true);
            }
            targetDir = picturesDir;
          }
        }
      } catch (_) {}

      targetDir ??=
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'repr_workout_$timestamp.png';
      final savedFile = File('${targetDir.path}/$fileName');
      await savedFile.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Foto kartu berhasil disimpan! Siap untuk dikoleksi. 📸',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF161618),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Fallback: share file so user can save it anywhere
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/repr_workout_$timestamp.png');
      final bytes = await _captureCardBytes();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            text: 'Simpan Foto Latihan Repr',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  void _copySummaryText() {
    final isLbs = widget.weightUnit == 'lbs';
    final displayVolume =
        isLbs
            ? widget.summary.volumeKg * kgToLbsMultiplier
            : widget.summary.volumeKg;
    final comparison = defaultWeightComparisons[_selectedComparisonIndex];

    final prLines =
        widget.summary.personalRecords.isEmpty
            ? ''
            : '\n🏆 PR Baru:\n${widget.summary.personalRecords.map((r) => '• ${r.exerciseName}: ${(isLbs ? r.valueKg * kgToLbsMultiplier : r.valueKg).toStringAsFixed(1)} ${widget.weightUnit} (${r.kind == PersonalRecordKind.maxWeight ? 'Max Weight' : 'Est. 1RM'})').join('\n')}';

    final text =
        '${_greeting.emoji} ${_greeting.title} di Repr!\n'
        '📅 ${widget.summary.workoutName}\n'
        '⏱️ Durasi: ${widget.summary.duration.inMinutes} mnt\n'
        '📊 Total Set: ${widget.summary.completedSets}\n'
        '🔥 Total Volume: ${displayVolume.toStringAsFixed(0)} ${widget.weightUnit} (${comparison.subtitle})$prLines\n\n'
        '#Repr #Workout #Fitness';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ringkasan latihan disalin ke clipboard! 📋'),
        backgroundColor: Color(0xFF161618),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<Widget> _buildCards() {
    final cards = <Widget>[
      // Card 1: Weight Comparison (Iconic Elephant or current selection)
      _WeightComparisonCard(
        summary: widget.summary,
        weightUnit: widget.weightUnit,
        userName: widget.userName,
        themeStyle: _themeStyle,
        comparison: defaultWeightComparisons[_selectedComparisonIndex],
        onTapIllustration: _cycleComparison,
      ),
      // Card 2: Workout Overview
      _WorkoutOverviewCard(
        summary: widget.summary,
        weightUnit: widget.weightUnit,
        userName: widget.userName,
        themeStyle: _themeStyle,
      ),
    ];

    // Card 3: Personal Records (if any)
    if (widget.summary.personalRecords.isNotEmpty) {
      cards.add(
        _PersonalRecordsCard(
          summary: widget.summary,
          weightUnit: widget.weightUnit,
          userName: widget.userName,
          themeStyle: _themeStyle,
        ),
      );
    }

    // Card 4: Streak Card
    cards.add(
      _StreakCard(
        summary: widget.summary,
        userName: widget.userName,
        themeStyle: _themeStyle,
      ),
    );

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final cards = _buildCards();
    final cardCount = cards.length;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Column(
          children: [
            // Header Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _greeting.fullTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ini adalah latihan ke-${widget.summary.workoutNumber} kamu',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Carousel Area
            Expanded(
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: cardCount,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      // Only wrap active page in RepaintBoundary for high-res capture
                      final cardWidget = cards[index];
                      if (index == _currentPage) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 8.0,
                          ),
                          child: RepaintBoundary(
                            key: _repaintBoundaryKey,
                            child: cardWidget,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 8.0,
                        ),
                        child: cardWidget,
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                cardCount,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? const Color(0xFF007AFF)
                        : const Color(0xFF3F3F46),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Bagikan workout • Tag @repr',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8E8E93),
              ),
            ),

            const SizedBox(height: 14),

            // Circular Action Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CelebrationActionButton(
                    label: 'Background',
                    icon: Icons.texture_rounded,
                    onTap: _cycleTheme,
                  ),
                  _CelebrationActionButton(
                    label: 'Stories',
                    isInstagram: true,
                    customIcon: const InstagramLogoIcon(size: 24, color: Colors.white),
                    onTap: () => _shareCard(isInstagramStory: true),
                  ),
                  _CelebrationActionButton(
                    label: 'Lainnya',
                    icon: Icons.ios_share_rounded,
                    onTap: () => _shareCard(isInstagramStory: false),
                  ),
                  _CelebrationActionButton(
                    label: 'Salin Teks',
                    icon: Icons.copy_rounded,
                    onTap: _copySummaryText,
                  ),
                  _CelebrationActionButton(
                    label: 'Download',
                    icon: Icons.download_rounded,
                    onTap: _downloadCard,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Big Primary "Selesai" Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Card 1: Weight Comparison Card (Iconic Elephant Illustration)
// -------------------------------------------------------------
class _WeightComparisonCard extends StatelessWidget {
  const _WeightComparisonCard({
    required this.summary,
    required this.weightUnit,
    required this.themeStyle,
    required this.comparison,
    required this.onTapIllustration,
    this.userName,
  });

  final WorkoutCompletionSummary summary;
  final String weightUnit;
  final String? userName;
  final CelebrationThemeStyle themeStyle;
  final WeightComparisonData comparison;
  final VoidCallback onTapIllustration;

  @override
  Widget build(BuildContext context) {
    final isLbs = weightUnit == 'lbs';
    final displayVolume =
        isLbs ? summary.volumeKg * kgToLbsMultiplier : summary.volumeKg;

    final themeData = _resolveCardTheme(themeStyle);

    return Container(
      decoration: BoxDecoration(
        color: themeData.backgroundColor,
        gradient: themeData.gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [themeData.boxShadow],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Label
          Text(
            'Kamu mengangkat total',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: themeData.subtitleColor,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 6),

          // Big Volume Number
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_formatNumber(displayVolume)} $weightUnit',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: themeData.primaryTextColor,
                letterSpacing: -0.5,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Subtitle comparison
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              comparison.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: themeData.subtitleColor,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Center Vector Illustration
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: onTapIllustration,
                child: Tooltip(
                  message: 'Ketuk untuk mengganti perbandingan',
                  child: _ComparisonIllustration(
                    kind: comparison.kind,
                    isDark: themeStyle != CelebrationThemeStyle.classicWhite,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Footer Watermark (REPR @athlete)
          _CardFooterWatermark(
            userName: userName,
            textColor: themeData.primaryTextColor,
            logoColor: themeData.primaryTextColor,
          ),
        ],
      ),
    );
  }

  String _formatNumber(double val) {
    if (val >= 1000) {
      final whole = val.round();
      final thousands = whole ~/ 1000;
      final remainder = (whole % 1000).toString().padLeft(3, '0');
      return '$thousands.$remainder';
    }
    return val.toStringAsFixed(0);
  }
}

// -------------------------------------------------------------
// Card 2: Workout Overview Card
// -------------------------------------------------------------
class _WorkoutOverviewCard extends StatelessWidget {
  const _WorkoutOverviewCard({
    required this.summary,
    required this.weightUnit,
    required this.themeStyle,
    this.userName,
  });

  final WorkoutCompletionSummary summary;
  final String weightUnit;
  final String? userName;
  final CelebrationThemeStyle themeStyle;

  @override
  Widget build(BuildContext context) {
    final isLbs = weightUnit == 'lbs';
    final displayVolume =
        isLbs ? summary.volumeKg * kgToLbsMultiplier : summary.volumeKg;
    final themeData = _resolveCardTheme(themeStyle);

    return Container(
      decoration: BoxDecoration(
        color: themeData.backgroundColor,
        gradient: themeData.gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [themeData.boxShadow],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Title with muscle emoji
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.workoutName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: themeData.primaryTextColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('💪', style: TextStyle(fontSize: 24)),
            ],
          ),

          const SizedBox(height: 16),

          // 2x2 Stats Grid
          Row(
            children: [
              Expanded(
                child: _OverviewStatItem(
                  label: 'Durasi',
                  value: '${summary.duration.inMinutes} mnt',
                  themeData: themeData,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OverviewStatItem(
                  label: 'Volume',
                  value: '${displayVolume.toStringAsFixed(0)} $weightUnit',
                  themeData: themeData,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _OverviewStatItem(
                  label: 'Latihan',
                  value: '${summary.exerciseSummaries.length}',
                  themeData: themeData,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OverviewStatItem(
                  label: 'Set',
                  value: '${summary.completedSets}',
                  themeData: themeData,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Exercise rows preview
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  summary.exerciseSummaries.length > 3
                      ? 3
                      : summary.exerciseSummaries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ex = summary.exerciseSummaries[index];
                return Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF007AFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ex,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeData.primaryTextColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Footer Watermark
          _CardFooterWatermark(
            userName: userName,
            textColor: themeData.primaryTextColor,
            logoColor: themeData.primaryTextColor,
          ),
        ],
      ),
    );
  }
}

class _OverviewStatItem extends StatelessWidget {
  const _OverviewStatItem({
    required this.label,
    required this.value,
    required this.themeData,
  });

  final String label;
  final String value;
  final _CardThemeData themeData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: themeData.primaryTextColor,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: themeData.subtitleColor,
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// Card 3: Personal Records Card
// -------------------------------------------------------------
class _PersonalRecordsCard extends StatelessWidget {
  const _PersonalRecordsCard({
    required this.summary,
    required this.weightUnit,
    required this.themeStyle,
    this.userName,
  });

  final WorkoutCompletionSummary summary;
  final String weightUnit;
  final String? userName;
  final CelebrationThemeStyle themeStyle;

  @override
  Widget build(BuildContext context) {
    final isLbs = weightUnit == 'lbs';
    final themeData = _resolveCardTheme(themeStyle);
    final pr = summary.personalRecords.first;
    final displayVal =
        isLbs ? pr.valueKg * kgToLbsMultiplier : pr.valueKg;

    return Container(
      decoration: BoxDecoration(
        color: themeData.backgroundColor,
        gradient: themeData.gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [themeData.boxShadow],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
      child: Stack(
        children: [
          // Background Celebration Ribbons
          Positioned.fill(
            child: CustomPaint(
              painter: _CelebrationRibbonsPainter(
                color: themeStyle == CelebrationThemeStyle.classicWhite
                    ? const Color(0xFFFEF3C7).withValues(alpha: 0.6)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.12),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top PR Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'PR BARU',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Big PR Value
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${displayVal.toStringAsFixed(1)} $weightUnit',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: themeData.primaryTextColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pr.exerciseName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: themeData.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pr.kind == PersonalRecordKind.maxWeight
                        ? 'Rekor Beban Maksimal'
                        : 'Estimasi 1RM Baru',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: themeData.subtitleColor,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Footer Watermark
              _CardFooterWatermark(
                userName: userName,
                textColor: themeData.primaryTextColor,
                logoColor: themeData.primaryTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Card 4: Consistency Streak Card
// -------------------------------------------------------------
class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.summary,
    required this.themeStyle,
    this.userName,
  });

  final WorkoutCompletionSummary summary;
  final String? userName;
  final CelebrationThemeStyle themeStyle;

  @override
  Widget build(BuildContext context) {
    final themeData = _resolveCardTheme(themeStyle);

    return Container(
      decoration: BoxDecoration(
        color: themeData.backgroundColor,
        gradient: themeData.gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [themeData.boxShadow],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Flame Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 26)),
            ),
          ),

          const SizedBox(height: 12),

          // Big Streak Number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${summary.streakWeeks}',
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: themeData.primaryTextColor,
                  letterSpacing: -1.0,
                ),
              ),
              Text(
                'Minggu Beruntun',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: themeData.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kamu telah konsisten berolahraga selama ${summary.streakWeeks} minggu berturut-turut! Pertahankan momentum ini.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: themeData.subtitleColor,
                  height: 1.4,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Footer Watermark
          _CardFooterWatermark(
            userName: userName,
            textColor: themeData.primaryTextColor,
            logoColor: themeData.primaryTextColor,
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Watermark & Brand Widget
// -------------------------------------------------------------
class _CardFooterWatermark extends StatelessWidget {
  const _CardFooterWatermark({
    required this.textColor,
    required this.logoColor,
    this.userName,
  });

  final String? userName;
  final Color textColor;
  final Color logoColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.asset(
            'assets/icon/repr_icon.png',
            width: 20,
            height: 20,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.fitness_center_rounded, color: logoColor, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'REPR',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// Instagram Logo Icon Widget
// -------------------------------------------------------------
class InstagramLogoIcon extends StatelessWidget {
  const InstagramLogoIcon({
    super.key,
    this.size = 22,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _InstagramLogoPainter(color: color),
      ),
    );
  }
}

class _InstagramLogoPainter extends CustomPainter {
  const _InstagramLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.1;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer rounded square
    final padding = strokeWidth / 2 + size.width * 0.04;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        padding,
        padding,
        size.width - 2 * padding,
        size.height - 2 * padding,
      ),
      Radius.circular(size.width * 0.28),
    );
    canvas.drawRRect(rrect, strokePaint);

    // Center circle lens
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.23, strokePaint);

    // Top-right flash dot
    final dotCenter = Offset(size.width * 0.72, size.height * 0.28);
    canvas.drawCircle(dotCenter, size.width * 0.055, fillPaint);
  }

  @override
  bool shouldRepaint(_InstagramLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

// -------------------------------------------------------------
// Action Button (Background, Stories, More, Copy, Download)
// -------------------------------------------------------------
class _CelebrationActionButton extends StatelessWidget {
  const _CelebrationActionButton({
    required this.label,
    this.icon,
    this.customIcon,
    required this.onTap,
    this.isInstagram = false,
  });

  final String label;
  final IconData? icon;
  final Widget? customIcon;
  final VoidCallback onTap;
  final bool isInstagram;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isInstagram
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF833AB4),
                        Color(0xFFFD1D1D),
                        Color(0xFFF77737),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isInstagram ? null : const Color(0xFF1C1C1E),
              border: Border.all(
                color: isInstagram ? Colors.transparent : const Color(0xFF2C2C2E),
                width: 1.2,
              ),
            ),
            child: Center(
              child: customIcon ??
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Card Theme Data & Helper
// -------------------------------------------------------------
class _CardThemeData {
  const _CardThemeData({
    required this.backgroundColor,
    required this.primaryTextColor,
    required this.subtitleColor,
    required this.boxShadow,
    this.gradient,
  });

  final Color backgroundColor;
  final Color primaryTextColor;
  final Color subtitleColor;
  final BoxShadow boxShadow;
  final Gradient? gradient;
}

_CardThemeData _resolveCardTheme(CelebrationThemeStyle style) {
  switch (style) {
    case CelebrationThemeStyle.classicWhite:
      return _CardThemeData(
        backgroundColor: Colors.white,
        primaryTextColor: const Color(0xFF0F172A),
        subtitleColor: const Color(0xFF475569),
        boxShadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      );
    case CelebrationThemeStyle.obsidianDark:
      return _CardThemeData(
        backgroundColor: const Color(0xFF161618),
        primaryTextColor: Colors.white,
        subtitleColor: const Color(0xFFA1A1AA),
        boxShadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      );
    case CelebrationThemeStyle.cyberNeon:
      return _CardThemeData(
        backgroundColor: const Color(0xFF0F172A),
        primaryTextColor: Colors.white,
        subtitleColor: const Color(0xFFC7D2FE),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const BoxShadow(
          color: Color(0x336366F1),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      );
  }
}

// -------------------------------------------------------------
// Comparison Illustration Dispatcher
// -------------------------------------------------------------
class _ComparisonIllustration extends StatelessWidget {
  const _ComparisonIllustration({
    required this.kind,
    required this.isDark,
  });

  final ComparisonKind kind;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case ComparisonKind.elephant:
        return const SizedBox(
          width: 170,
          height: 120,
          child: CustomPaint(
            painter: ElephantIllustrationPainter(
              bodyColor: Color(0xFF4C87C0),
              darkColor: Color(0xFF356294),
              tuskColor: Colors.white,
            ),
          ),
        );
      case ComparisonKind.panda:
        return _SimpleEmojiIllustration(emoji: '🐼', isDark: isDark);
      case ComparisonKind.lion:
        return _SimpleEmojiIllustration(emoji: '🦁', isDark: isDark);
      case ComparisonKind.horse:
        return _SimpleEmojiIllustration(emoji: '🐎', isDark: isDark);
      case ComparisonKind.trex:
        return _SimpleEmojiIllustration(emoji: '🦖', isDark: isDark);
      case ComparisonKind.jet:
        return _SimpleEmojiIllustration(emoji: '✈️', isDark: isDark);
      case ComparisonKind.kitten:
        return _SimpleEmojiIllustration(emoji: '🐱', isDark: isDark);
    }
  }
}

class _SimpleEmojiIllustration extends StatelessWidget {
  const _SimpleEmojiIllustration({
    required this.emoji,
    required this.isDark,
  });

  final String emoji;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 64)),
      ),
    );
  }
}

// -------------------------------------------------------------
// Iconic Blue Elephant Vector Painter (Side Profile Matching Hevy)
// -------------------------------------------------------------
class ElephantIllustrationPainter extends CustomPainter {
  const ElephantIllustrationPainter({
    this.bodyColor = const Color(0xFF4C87C0),
    this.darkColor = const Color(0xFF356294),
    this.tuskColor = const Color(0xFFFFFFFF),
  });

  final Color bodyColor;
  final Color darkColor;
  final Color tuskColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Background legs (darker shade for depth)
    final farLegPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    // Far back leg
    final farBackLeg = Path()
      ..moveTo(120, 70)
      ..lineTo(122, 120)
      ..quadraticBezierTo(122, 126, 132, 126)
      ..lineTo(136, 126)
      ..quadraticBezierTo(142, 126, 142, 120)
      ..lineTo(140, 70)
      ..close();
    canvas.drawPath(farBackLeg, farLegPaint);

    // Far front leg
    final farFrontLeg = Path()
      ..moveTo(68, 70)
      ..lineTo(68, 120)
      ..quadraticBezierTo(68, 126, 78, 126)
      ..lineTo(82, 126)
      ..quadraticBezierTo(88, 126, 88, 120)
      ..lineTo(88, 70)
      ..close();
    canvas.drawPath(farFrontLeg, farLegPaint);

    // 2. Tusk (drawn behind front trunk)
    final tuskPaint = Paint()
      ..color = tuskColor
      ..style = PaintingStyle.fill;
    final tuskPath = Path()
      ..moveTo(40, 68)
      ..quadraticBezierTo(24, 74, 14, 62)
      ..quadraticBezierTo(22, 78, 38, 76)
      ..close();
    canvas.drawPath(tuskPath, tuskPaint);

    // 3. Main body (head, back, near back leg, belly, near front leg, trunk)
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    final bodyPath = Path();

    // Start at forehead
    bodyPath.moveTo(46, 26);
    // Head dome
    bodyPath.cubicTo(32, 26, 24, 40, 24, 55);
    // Outer trunk curving down and slightly forward
    bodyPath.cubicTo(24, 68, 18, 88, 22, 102);
    // Trunk tip curve
    bodyPath.quadraticBezierTo(26, 108, 30, 106);
    bodyPath.quadraticBezierTo(32, 102, 30, 96);
    // Inner trunk curving back up
    bodyPath.cubicTo(27, 85, 34, 72, 40, 68);
    // Chin to front near leg
    bodyPath.quadraticBezierTo(46, 75, 48, 85);
    // Near front leg down
    bodyPath.lineTo(48, 120);
    bodyPath.quadraticBezierTo(48, 126, 56, 126);
    bodyPath.lineTo(62, 126);
    bodyPath.quadraticBezierTo(68, 126, 68, 120);
    bodyPath.lineTo(68, 80);
    // Belly curve
    bodyPath.quadraticBezierTo(100, 84, 134, 80);
    // Near back leg down
    bodyPath.lineTo(134, 120);
    bodyPath.quadraticBezierTo(134, 126, 142, 126);
    bodyPath.lineTo(148, 126);
    bodyPath.quadraticBezierTo(154, 126, 154, 120);
    bodyPath.lineTo(154, 85);
    // Back leg rear curve up to rump
    bodyPath.quadraticBezierTo(160, 68, 160, 52);
    // Rump and back dome
    bodyPath.cubicTo(158, 38, 138, 28, 106, 28);
    // Neck dip to forehead
    bodyPath.quadraticBezierTo(72, 28, 46, 26);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // 4. Tail
    final tailPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final tailPath = Path()
      ..moveTo(158, 52)
      ..quadraticBezierTo(168, 65, 164, 85);
    canvas.drawPath(tailPath, tailPaint);

    // Tail tuft
    final tuftPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(164, 86), width: 5, height: 8),
      tuftPaint,
    );

    // 5. Ear flap
    final earPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final earPath = Path()
      ..moveTo(48, 28)
      ..cubicTo(64, 28, 76, 40, 74, 58)
      ..cubicTo(72, 74, 58, 80, 48, 76)
      ..quadraticBezierTo(42, 60, 48, 28)
      ..close();
    canvas.drawPath(earPath, earPaint);

    final earLinePaint = Paint()
      ..color = darkColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(earPath, earLinePaint);

    // 6. Eye
    final eyePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(38, 44), 3.0, eyePaint);
    final eyeGlintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(37, 43), 1.0, eyeGlintPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ElephantIllustrationPainter oldDelegate) =>
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.darkColor != darkColor ||
      oldDelegate.tuskColor != tuskColor;
}

// -------------------------------------------------------------
// Festive Celebration Ribbons Painter (For PR card)
// -------------------------------------------------------------
class _CelebrationRibbonsPainter extends CustomPainter {
  const _CelebrationRibbonsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width * 0.9, size.height * 0.5);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.6, 0)
      ..lineTo(size.width, size.height * 0.4);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant _CelebrationRibbonsPainter oldDelegate) =>
      oldDelegate.color != color;
}
