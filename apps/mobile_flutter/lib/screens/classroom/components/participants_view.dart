import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';

class ParticipantsView extends StatefulWidget {
  final List<ParticipantItem> initialParticipants;
  final bool isTeacher;
  final VoidCallback onClose;

  const ParticipantsView({
    super.key,
    required this.initialParticipants,
    this.isTeacher = true,
    required this.onClose,
  });

  @override
  State<ParticipantsView> createState() => _ParticipantsViewState();
}

class _ParticipantsViewState extends State<ParticipantsView> {
  late List<ParticipantItem> _participants;
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all', 'hands', 'mic', 'camera'

  @override
  void initState() {
    super.initState();
    _participants = List.from(widget.initialParticipants);
  }

  void _muteAll() {
    setState(() {
      _participants = _participants.map((p) {
        if (p.role == 'student') {
          return p.copyWith(isMicOn: false);
        }
        return p;
      }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All student microphones have been muted'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.slate800,
      ),
    );
  }

  void _toggleMic(String id) {
    setState(() {
      final idx = _participants.indexWhere((p) => p.id == id);
      if (idx != -1) {
        _participants[idx] = _participants[idx].copyWith(
          isMicOn: !_participants[idx].isMicOn,
        );
      }
    });
  }

  void _toggleHand(String id) {
    setState(() {
      final idx = _participants.indexWhere((p) => p.id == id);
      if (idx != -1) {
        _participants[idx] = _participants[idx].copyWith(
          isHandRaised: !_participants[idx].isHandRaised,
        );
      }
    });
  }

  List<ParticipantItem> get _filteredList {
    return _participants.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.rollNo.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_activeFilter == 'hands') return p.isHandRaised;
      if (_activeFilter == 'mic') return p.isMicOn;
      if (_activeFilter == 'camera') return p.isVideoOn;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;
    final handsCount = _participants.where((p) => p.isHandRaised).length;
    final micCount = _participants.where((p) => p.isMicOn).length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onClose();
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            // Swipe right to go back
            widget.onClose();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.slate900,
          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                // Top Header with Safe Area clearance
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.slate850,
                    border: Border(bottom: BorderSide(color: AppColors.slate700)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        onPressed: widget.onClose,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Class Participants',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.indigo600,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_participants.length} Active',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Full roster with real-time controls',
                              style: TextStyle(
                                color: AppColors.slate400,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isTeacher)
                        ElevatedButton.icon(
                          onPressed: _muteAll,
                          icon: const Icon(Icons.mic_off_rounded, size: 14),
                          label: const Text('Mute All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rose600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
                ),

                // Search & Filter Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by name or roll number...',
                          hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate400, size: 18),
                          filled: true,
                          fillColor: AppColors.slate800,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.slate700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.slate700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.indigo500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('all', 'All (${_participants.length})'),
                            const SizedBox(width: 8),
                            _filterChip('hands', 'Raised Hands ($handsCount)'),
                            const SizedBox(width: 8),
                            _filterChip('mic', 'Mic Unmuted ($micCount)'),
                            const SizedBox(width: 8),
                            _filterChip('camera', 'Video Enabled'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Participants List
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching participants found',
                            style: TextStyle(color: AppColors.slate400, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: list.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = list[index];
                            final isTeacher = p.role == 'teacher';

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isTeacher ? AppColors.indigo950.withOpacity(0.6) : AppColors.slate800,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isTeacher ? AppColors.indigo500.withOpacity(0.5) : AppColors.slate700,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundImage: NetworkImage(p.avatar),
                                        backgroundColor: AppColors.slate700,
                                      ),
                                      if (p.isHandRaised)
                                        Positioned(
                                          bottom: -2,
                                          right: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: AppColors.amber500,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.pan_tool_rounded, size: 10, color: Colors.white),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),

                                  // Name and Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                p.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            if (isTeacher)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.indigo600,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'HOST',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${p.rollNo} • ${p.role.toUpperCase()}',
                                          style: const TextStyle(
                                            color: AppColors.slate400,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status icons / Controls
                                  if (p.isHandRaised)
                                    IconButton(
                                      icon: const Icon(Icons.pan_tool_rounded, color: AppColors.amber400, size: 18),
                                      tooltip: 'Lower Hand',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _toggleHand(p.id),
                                    ),
                                  const SizedBox(width: 8),

                                  IconButton(
                                    icon: Icon(
                                      p.isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                                      color: p.isMicOn ? AppColors.emerald400 : AppColors.slate500,
                                      size: 18,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: widget.isTeacher ? () => _toggleMic(p.id) : null,
                                  ),
                                  const SizedBox(width: 8),

                                  Icon(
                                    p.isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                                    color: p.isVideoOn ? AppColors.indigo400 : AppColors.slate500,
                                    size: 18,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String filterId, String label) {
    final isSel = _activeFilter == filterId;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filterId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.indigo600 : AppColors.slate800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? AppColors.indigo500 : AppColors.slate700),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : AppColors.slate300,
            fontSize: 11,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
