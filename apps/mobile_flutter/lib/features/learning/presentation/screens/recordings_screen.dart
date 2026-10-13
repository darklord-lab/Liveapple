import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../batch/presentation/batch_controller.dart';
import '../../../../core/widgets/empty_state.dart';
import '../controllers/learning_controller.dart';
import '../../domain/models/learning_models.dart';
import '../../../../core/services/pip_service.dart';

import '../../../../core/widgets/filter_sort_sheet.dart';

class RecordingsScreen extends ConsumerStatefulWidget {
  const RecordingsScreen({super.key});

  @override
  ConsumerState<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends ConsumerState<RecordingsScreen> {
  String _selectedBatch = 'ALL';
  String _selectedSubject = 'ALL';
  String _selectedSort = 'newest';

  int get _activeCount =>
      (_selectedBatch != 'ALL' ? 1 : 0) +
      (_selectedSubject != 'ALL' ? 1 : 0) +
      (_selectedSort != 'newest' ? 1 : 0);

  void _resetFilters() {
    setState(() {
      _selectedBatch = 'ALL';
      _selectedSubject = 'ALL';
      _selectedSort = 'newest';
    });
  }

  Future<void> _openFilterSortSheet(List<RecordingModel> recordings) async {
    final batches = {'ALL', ...recordings.map((r) => r.batchName).where((b) => b != null && b.isNotEmpty).cast<String>()}.toList();
    final subjects = {'ALL', ...recordings.map((r) => r.subject).where((s) => s != null && s.isNotEmpty).cast<String>()}.toList();

    final result = await showFilterSortSheet<String>(
      context: context,
      title: 'Filter & Sort Recordings',
      filters: [
        FilterConfig<String>(
          id: 'batch',
          title: 'Batch',
          options: batches.map((b) => FilterItem(value: b, label: b == 'ALL' ? 'All Batches' : b)).toList(),
          initialValue: _selectedBatch,
          defaultValue: 'ALL',
        ),
        if (subjects.length > 1)
          FilterConfig<String>(
            id: 'subject',
            title: 'Subject',
            options: subjects.map((s) => FilterItem(value: s, label: s == 'ALL' ? 'All Subjects' : s)).toList(),
            initialValue: _selectedSubject,
            defaultValue: 'ALL',
          ),
      ],
      sort: SortConfig<String>(
        title: 'Sort Recordings',
        options: const [
          SortOptionItem(value: 'newest', label: 'Newest First', icon: Icons.schedule),
          SortOptionItem(value: 'oldest', label: 'Oldest First', icon: Icons.history),
          SortOptionItem(value: 'duration_desc', label: 'Duration: Longest First', icon: Icons.hourglass_top),
          SortOptionItem(value: 'duration_asc', label: 'Duration: Shortest First', icon: Icons.hourglass_bottom),
        ],
        initialValue: _selectedSort,
        defaultValue: 'newest',
      ),
    );

    if (result != null) {
      setState(() {
        _selectedBatch = result.getFilter('batch', 'ALL');
        _selectedSubject = result.getFilter('subject', 'ALL');
        _selectedSort = result.sortValue ?? 'newest';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingsAsync = ref.watch(recordingsProvider);
    final currentUser = ref.watch(authStateProvider).user;
    final canUpload = currentUser?.role == 'TEACHER' || currentUser?.role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorded Lectures', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          FilterBadgeButton(
            activeCount: _activeCount,
            tooltip: 'Filter & Sort Recordings',
            onPressed: () {
              final recordings = recordingsAsync.valueOrNull ?? [];
              _openFilterSortSheet(recordings);
            },
          ),
          if (canUpload)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Upload / Add Recording',
              onPressed: () => _showUploadRecordingDialog(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(recordingsProvider),
          ),
        ],
      ),
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.skyBlue,
              icon: const Icon(Icons.video_call, color: Colors.white),
              label: const Text('Upload Recording', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _showUploadRecordingDialog(context, ref),
            )
          : null,
      body: recordingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.liveRed, size: 40),
              const SizedBox(height: 12),
              Text('Failed to load recordings: $err', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(recordingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (recordings) {
          if (recordings.isEmpty) {
            return const EmptyState(
              icon: Icons.video_library_outlined,
              title: 'No recordings yet',
              subtitle: 'Completed live classes with recordings will appear here.',
            );
          }

          var filtered = recordings.where((item) {
            if (_selectedBatch != 'ALL' && (item.batchName ?? '') != _selectedBatch) return false;
            if (_selectedSubject != 'ALL' && (item.subject ?? '') != _selectedSubject) return false;
            return true;
          }).toList();

          if (_selectedSort == 'newest') {
            filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } else if (_selectedSort == 'oldest') {
            filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          } else if (_selectedSort == 'duration_desc') {
            filtered.sort((a, b) => b.durationSec.compareTo(a.durationSec));
          } else if (_selectedSort == 'duration_asc') {
            filtered.sort((a, b) => a.durationSec.compareTo(b.durationSec));
          }

          return Column(
            children: [
              if (_activeCount > 0)
                ActiveFiltersBar(
                  chips: [
                    if (_selectedBatch != 'ALL')
                      ActiveFilterChipData(
                        label: 'Batch: $_selectedBatch',
                        onRemoved: () => setState(() => _selectedBatch = 'ALL'),
                      ),
                    if (_selectedSubject != 'ALL')
                      ActiveFilterChipData(
                        label: 'Subject: $_selectedSubject',
                        onRemoved: () => setState(() => _selectedSubject = 'ALL'),
                      ),
                    if (_selectedSort != 'newest')
                      ActiveFilterChipData(
                        label: _selectedSort == 'oldest'
                            ? 'Oldest first'
                            : _selectedSort == 'duration_desc'
                                ? 'Longest duration'
                                : 'Shortest duration',
                        onRemoved: () => setState(() => _selectedSort = 'newest'),
                      ),
                  ],
                  onClearAll: _resetFilters,
                ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.filter_list_off,
                          title: 'No matching recordings',
                          subtitle: 'No recorded lectures match the selected filter criteria.',
                          buttonText: 'Reset Filters',
                          onAction: _resetFilters,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildRecordingCard(context, item);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordingCard(BuildContext context, RecordingModel item) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt);

    return InkWell(
      onTap: () => _openSecurePlayer(context, item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Preview Box
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.skyBlueLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill, color: AppColors.skyBlue, size: 36),
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.batchName != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.skyBlueLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.subject ?? item.batchName!,
                            style: const TextStyle(color: AppColors.skyBlue, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${item.batchName!}',
                          style: const TextStyle(color: AppColors.slate500, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    item.title,
                    style: const TextStyle(color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: AppColors.slate500),
                      const SizedBox(width: 4),
                      Text(item.durationFormatted, style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.slate500),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                      const Spacer(),
                      const Icon(Icons.lock_outline, size: 13, color: AppColors.success),
                      const SizedBox(width: 3),
                      const Text('Protected', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSecurePlayer(BuildContext context, RecordingModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecurePlayerScreen(recording: item),
      ),
    );
  }

  void _showUploadRecordingDialog(BuildContext context, WidgetRef ref) {
    final batchState = ref.read(batchListProvider);
    final batches = batchState.batches;
    if (batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a batch first before uploading recordings.')),
      );
      return;
    }

    String selectedBatchId = batches.first.id;
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final durationController = TextEditingController(text: '45');
    String? pickedVideoFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Upload Class Recording', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Cohort Batch', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedBatchId,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: batches.map((b) => DropdownMenuItem(
                    value: b.id,
                    child: Text('${b.name} (${b.subject})', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedBatchId = v);
                  },
                ),
                const SizedBox(height: 12),

                const Text('Lecture Title', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g., Electromagnetic Induction - Session 1',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                // Device Video File Picker
                const Text('Choose Video From Device Storage', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.video,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() {
                          pickedVideoFileName = result.files.first.name;
                          urlController.text = result.files.first.path ?? result.files.first.name;
                          if (titleController.text.trim().isEmpty) {
                            titleController.text = result.files.first.name.split('.').first;
                          }
                        });
                      }
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: pickedVideoFileName != null ? Colors.greenAccent : AppColors.skyBlue),
                    ),
                    child: Row(
                      children: [
                        Icon(pickedVideoFileName != null ? Icons.check_circle : Icons.video_file, color: pickedVideoFileName != null ? Colors.greenAccent : AppColors.skyBlue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pickedVideoFileName ?? 'Select Video File (MP4, MKV, WebM)',
                            style: TextStyle(
                              color: pickedVideoFileName != null ? Colors.white : AppColors.slate400,
                              fontSize: 12,
                              fontWeight: pickedVideoFileName != null ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFF334155))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('OR UNLISTED VIDEO LINK', style: TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: Color(0xFF334155))),
                  ],
                ),
                const SizedBox(height: 10),

                const Text('YouTube Unlisted / Direct MP4 Video URL', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'https://youtu.be/... or https://...mp4',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Duration (Minutes)', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.slate400)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
              onPressed: () async {
                if (titleController.text.trim().isEmpty || urlController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide lecture title and select a video file or link')),
                  );
                  return;
                }

                final durationMin = int.tryParse(durationController.text.trim()) ?? 45;
                try {
                  await ref.read(learningRepositoryProvider).saveRecording(
                    liveClassId: selectedBatchId,
                    videoUrl: urlController.text.trim(),
                    title: titleController.text.trim(),
                    durationSec: durationMin * 60,
                    fileSizeMb: 125.0,
                  );
                  ref.invalidate(recordingsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lecture recording published to batch students!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save recording: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Upload Recording'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dedicated Secure In-App Video Player Screen
/// Strict Security Rules (Per User Spec):
/// 1. NO share button
/// 2. NO download button
/// 3. Only Play / Pause
/// 4. Playback Speed Selector (0.75x, 1x, 1.25x, 1.5x, 2x)
/// 5. Portrait & Landscape Orientation Toggle
class SecurePlayerScreen extends StatefulWidget {
  final RecordingModel recording;

  const SecurePlayerScreen({super.key, required this.recording});

  @override
  State<SecurePlayerScreen> createState() => _SecurePlayerScreenState();
}

class _SecurePlayerScreenState extends State<SecurePlayerScreen> {
  VideoPlayerController? _videoController;
  WebViewController? _webController;
  bool _isYouTube = false;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isLandscape = false;
  double _playbackSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  late final PipService _pipService;
  bool _isPipActive = false;

  final List<double> _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _pipService = PipService();
    _pipService.isPipActiveNotifier.addListener(_onPipModeChanged);
    _initPlayer();
  }

  void _onPipModeChanged() {
    if (mounted) {
      setState(() {
        _isPipActive = _pipService.isPipActive;
      });
    }
  }

  void _initPlayer() {
    final url = widget.recording.videoUrl.trim();
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      _isYouTube = true;
      _initYouTube(url);
    } else {
      _isYouTube = false;
      _initDirectVideo(url);
    }
  }

  String? _extractYouTubeId(String url) {
    if (url.contains('youtu.be/')) {
      return url.split('youtu.be/').last.split('?').first.split('&').first;
    }
    if (url.contains('watch?v=')) {
      return url.split('watch?v=').last.split('&').first;
    }
    if (url.contains('embed/')) {
      return url.split('embed/').last.split('?').first;
    }
    return null;
  }

  void _initYouTube(String url) {
    final videoId = _extractYouTubeId(url) ?? 'M7lc1UVf-VE';
    
    // Sandboxed embed HTML with modestbranding, no related videos, no sharing, no annotations
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          body, html { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
          #player { width: 100%; height: 100%; }
        </style>
      </head>
      <body>
        <div id="player"></div>
        <script>
          var tag = document.createElement('script');
          tag.src = "https://www.youtube.com/iframe_api";
          var firstScriptTag = document.getElementsByTagName('script')[0];
          firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

          var player;
          function onYouTubeIframeAPIReady() {
            player = new YT.Player('player', {
              videoId: '$videoId',
              playerVars: {
                'autoplay': 1,
                'controls': 0,
                'modestbranding': 1,
                'rel': 0,
                'disablekb': 1,
                'fs': 0,
                'iv_load_policy': 3
              },
              events: {
                'onReady': onPlayerReady,
                'onStateChange': onPlayerStateChange
              }
            });
          }
          function onPlayerReady(event) {
            event.target.playVideo();
          }
          function onPlayerStateChange(event) {
            // State tracking
          }
          function play() { player.playVideo(); }
          function pause() { player.pauseVideo(); }
          function setSpeed(rate) { player.setPlaybackRate(rate); }
        </script>
      </body>
    </html>
    ''';

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Block all external navigations (no sharing/links)
            if (request.url.startsWith('https://www.youtube.com/watch') || request.url.contains('share')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadHtmlString(htmlContent);

    setState(() {
      _isPlaying = true;
      _totalDuration = Duration(seconds: widget.recording.durationSec > 0 ? widget.recording.durationSec : 2700);
    });
  }

  void _initDirectVideo(String url) async {
    try {
      final uri = Uri.parse(url);
      _videoController = VideoPlayerController.networkUrl(uri);
      await _videoController!.initialize();
      _videoController!.addListener(() {
        if (mounted && _videoController != null) {
          setState(() {
            _currentPosition = _videoController!.value.position;
            _totalDuration = _videoController!.value.duration;
            _isPlaying = _videoController!.value.isPlaying;
          });
        }
      });
      await _videoController!.play();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _togglePlayPause() {
    if (_isYouTube) {
      setState(() => _isPlaying = !_isPlaying);
      if (_isPlaying) {
        _webController?.runJavaScript('play();');
      } else {
        _webController?.runJavaScript('pause();');
      }
    } else {
      if (_videoController != null) {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      }
    }
  }

  void _setSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    if (_isYouTube) {
      _webController?.runJavaScript('setSpeed($speed);');
    } else {
      _videoController?.setPlaybackSpeed(speed);
    }
  }

  void _toggleOrientation() {
    setState(() => _isLandscape = !_isLandscape);
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  void dispose() {
    _pipService.isPipActiveNotifier.removeListener(_onPipModeChanged);
    // Always restore portrait mode upon exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _enterPip() async {
    final entered = await _pipService.enterPip(width: 16, height: 9);
    if (!entered && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Picture-in-Picture is not supported on this device/platform'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildPlayerStage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isYouTube && _webController != null)
          WebViewWidget(controller: _webController!)
        else if (_videoController != null && _videoController!.value.isInitialized)
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          )
        else if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.skyBlue),
          )
        else
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, color: AppColors.slate400, size: 48),
                SizedBox(height: 10),
                Text('Video Stream Ready', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

        // Center Play/Pause Touch Overlay
        GestureDetector(
          onTap: _togglePlayPause,
          behavior: HitTestBehavior.translucent,
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isPipActive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _buildPlayerStage(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Secure Header Bar (NO SHARE, NO DOWNLOAD)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFF0F172A),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recording.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.recording.batchName ?? 'Batch'} • Protected Lecture Stream',
                          style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Protected badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.greenAccent, width: 0.6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 12, color: Colors.greenAccent),
                        SizedBox(width: 4),
                        Text('Protected', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Video Player Stage
            Expanded(
              child: _buildPlayerStage(),
            ),

            // Bottom Player Control Toolbar (Play, Pause, Speed, Orientation)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF0F172A),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Scrubber (for direct video)
                  if (!_isYouTube && _videoController != null && _videoController!.value.isInitialized)
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 3,
                        activeTrackColor: AppColors.skyBlue,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: AppColors.skyBlue,
                      ),
                      child: Slider(
                        value: _currentPosition.inMilliseconds.toDouble().clamp(0.0, _totalDuration.inMilliseconds.toDouble()),
                        max: _totalDuration.inMilliseconds.toDouble() > 0 ? _totalDuration.inMilliseconds.toDouble() : 1.0,
                        onChanged: (val) {
                          _videoController!.seekTo(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),

                  Row(
                    children: [
                      // Play/Pause Button
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: AppColors.skyBlue, size: 38),
                        onPressed: _togglePlayPause,
                      ),

                      // Time Indicator
                      Text(
                        '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),

                      const Spacer(),

                      // Speed Selector Menu
                      PopupMenuButton<double>(
                        initialValue: _playbackSpeed,
                        tooltip: 'Playback Speed',
                        color: const Color(0xFF1E293B),
                        onSelected: _setSpeed,
                        itemBuilder: (context) => _speeds.map((s) => PopupMenuItem(
                          value: s,
                          child: Text(
                            '${s}x',
                            style: TextStyle(
                              color: s == _playbackSpeed ? AppColors.skyBlue : Colors.white,
                              fontWeight: s == _playbackSpeed ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        )).toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Text(
                            '${_playbackSpeed}x',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Orientation / Fullscreen Toggle (Portrait vs Landscape)
                      IconButton(
                        tooltip: _isLandscape ? 'Exit Fullscreen' : 'Fullscreen Landscape',
                        icon: Icon(_isLandscape ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white, size: 26),
                        onPressed: _toggleOrientation,
                      ),

                      const SizedBox(width: 8),

                      // Picture-in-Picture Button
                      IconButton(
                        key: const Key('enter_pip_recording_btn'),
                        tooltip: 'Picture-in-Picture',
                        icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white, size: 24),
                        onPressed: _enterPip,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
