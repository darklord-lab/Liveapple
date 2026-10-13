import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/test_share_model.dart';

/// Interactive, rich visual modal dialog displaying a verified student score card.
class TestScoreShareCard extends StatelessWidget {
  final TestShareModel share;

  const TestScoreShareCard({
    super.key,
    required this.share,
  });

  /// Displays the share card as a modern centered dialog.
  static Future<void> show(BuildContext context, TestShareModel share) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TestScoreShareCard(share: share),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instituteColor = share.primaryColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Banner with Institute Branding & Monogram
              _buildHeaderBanner(instituteColor),

              // Student & Test Details Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Verified Student Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, size: 16, color: AppColors.skyBlue),
                          const SizedBox(width: 6),
                          Text(
                            share.studentName,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Test Title
                    Text(
                      share.testTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (share.batchName != null && share.batchName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${share.batchName}${share.subject != null ? ' • ${share.subject}' : ''}',
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Central Score Radial / Card Graphic
                    _buildScoreVisual(),

                    const SizedBox(height: 16),

                    // Grade Pill & Evaluation Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: share.gradeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: share.gradeColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, size: 16, color: share.gradeColor),
                          const SizedBox(width: 6),
                          Text(
                            share.grade,
                            style: TextStyle(
                              color: share.gradeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Deep Link URL display container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.link, size: 14, color: AppColors.slate500),
                              SizedBox(width: 6),
                              Text(
                                'Verified Score Card Deep Link',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slate500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            share.webLink,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.skyBlue,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons (Copy Link, Share Card, Close)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('copy_link_btn'),
                            onPressed: () => _copyLink(context),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy Link'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.slate700,
                              side: const BorderSide(color: AppColors.slate300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            key: const Key('share_score_btn'),
                            onPressed: () => _shareScoreText(context),
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.skyBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('close_share_card_btn'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: AppColors.slate500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(Color instituteColor) {
    final monogram = share.instituteName.isNotEmpty
        ? share.instituteName.substring(0, 1).toUpperCase()
        : 'C';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: instituteColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(color: instituteColor.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          // Monogram Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: instituteColor,
            child: Text(
              monogram,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Institute Name & Code
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.instituteName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: instituteColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        share.instituteCode,
                        style: TextStyle(
                          color: instituteColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (share.tagline != null && share.tagline!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          share.tagline!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreVisual() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.skyBlue.withValues(alpha: 0.08),
            const Color(0xFF10B981).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${share.score}',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppColors.skyBlue,
                  letterSpacing: -1,
                ),
              ),
              Text(
                ' / ${share.totalMarks}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${share.percentage}% Overall Score',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: share.webLink));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Score card link copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareScoreText(BuildContext context) {
    Clipboard.setData(ClipboardData(text: share.formatShareText()));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Score card details copied ready to share!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
