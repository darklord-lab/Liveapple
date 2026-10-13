import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/institute_link_model.dart';
import '../domain/testimonial_model.dart';
import 'institute_content_controller.dart';

class ManageInstituteContentScreen extends ConsumerStatefulWidget {
  const ManageInstituteContentScreen({super.key});

  @override
  ConsumerState<ManageInstituteContentScreen> createState() =>
      _ManageInstituteContentScreenState();
}

class _ManageInstituteContentScreenState
    extends ConsumerState<ManageInstituteContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(instituteLinksProvider.notifier).loadLinks(all: true);
      ref.read(testimonialsProvider.notifier).loadTestimonials(all: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /* -------------------------------------------------------------------------- */
  /* ADD / EDIT LINK DIALOG                                                     */
  /* -------------------------------------------------------------------------- */
  void _showLinkDialog({InstituteLinkModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final urlController = TextEditingController(text: existing?.url ?? '');
    String selectedPlatform = existing?.platform ?? 'YOUTUBE';
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existing == null ? 'Add Social / Connect Link' : 'Edit Connect Link',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate700)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedPlatform,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'YOUTUBE', child: Text('YouTube Channel')),
                      DropdownMenuItem(value: 'TELEGRAM', child: Text('Telegram Group')),
                      DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp Community')),
                      DropdownMenuItem(value: 'INSTAGRAM', child: Text('Instagram Profile')),
                      DropdownMenuItem(value: 'WEBSITE', child: Text('Institute Website')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other Resource Link')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedPlatform = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Display Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Official YouTube Lectures',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Title is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Destination URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: 'https://youtube.com/@classora',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'URL is required';
                      if (!val.trim().startsWith('http://') && !val.trim().startsWith('https://') && !val.trim().startsWith('t.me/') && !val.trim().startsWith('wa.me/')) {
                        return 'Enter a valid URL (https://...)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Show to students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight)),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        activeColor: AppColors.skyBlue,
                        onChanged: (val) => setDialogState(() => isActive = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.slate500)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.skyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(ctx);
                if (existing == null) {
                  await ref.read(instituteLinksProvider.notifier).createLink(
                        title: titleController.text,
                        platform: selectedPlatform,
                        url: urlController.text,
                        isActive: isActive,
                      );
                } else {
                  await ref.read(instituteLinksProvider.notifier).updateLink(
                        existing.id,
                        title: titleController.text,
                        platform: selectedPlatform,
                        url: urlController.text,
                        isActive: isActive,
                      );
                }
              },
              child: Text(existing == null ? 'Add Link' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /* ADD / EDIT TESTIMONIAL DIALOG                                              */
  /* -------------------------------------------------------------------------- */
  void _showTestimonialDialog({TestimonialModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.studentName ?? '');
    final batchController = TextEditingController(text: existing?.batchOrExam ?? '');
    final quoteController = TextEditingController(text: existing?.quote ?? '');
    int rating = existing?.rating ?? 5;
    bool isPublished = existing?.isPublished ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existing == null ? 'Add Student Testimonial' : 'Edit Testimonial',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Priya Verma',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 2) return 'Enter a valid student name (min 2 chars)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Batch / Exam / Rank (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: batchController,
                    decoration: InputDecoration(
                      hintText: 'e.g. JEE Advanced Rank 142 • Batch 2024',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate700)),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => setDialogState(() => rating = starValue),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  const Text('Student Quote / Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: quoteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'e.g. Classora helped me understand calculus with interactive live whiteboards...',
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 5) return 'Quote must be at least 5 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Publish on Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight)),
                      const Spacer(),
                      Switch(
                        value: isPublished,
                        activeColor: AppColors.skyBlue,
                        onChanged: (val) => setDialogState(() => isPublished = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.slate500)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.skyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(ctx);
                if (existing == null) {
                  await ref.read(testimonialsProvider.notifier).createTestimonial(
                        studentName: nameController.text,
                        batchOrExam: batchController.text,
                        quote: quoteController.text,
                        rating: rating,
                        isPublished: isPublished,
                      );
                } else {
                  await ref.read(testimonialsProvider.notifier).updateTestimonial(
                        existing.id,
                        studentName: nameController.text,
                        batchOrExam: batchController.text,
                        quote: quoteController.text,
                        rating: rating,
                        isPublished: isPublished,
                      );
                }
              },
              child: Text(existing == null ? 'Add Testimonial' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.skyBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Connect Links & Testimonials',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.share_outlined, size: 18), text: 'Connect Links'),
              Tab(icon: Icon(Icons.rate_review_outlined, size: 18), text: 'Testimonials'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLinksTab(),
            _buildTestimonialsTab(),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /* TAB 1: CONNECT LINKS                                                       */
  /* -------------------------------------------------------------------------- */
  Widget _buildLinksTab() {
    final linksState = ref.watch(instituteLinksProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(instituteLinksProvider.notifier).loadLinks(all: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner & Add Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Connect Links',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textLight),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Add YouTube, Telegram, or WhatsApp links for students to follow.',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => _showLinkDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (linksState.isLoading && linksState.links.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (linksState.links.isEmpty)
            const EmptyState(
              icon: Icons.link_off_rounded,
              title: 'No Connect Links Yet',
              subtitle: 'Add your institute’s official YouTube, Telegram, or WhatsApp links above.',
            )
          else
            ...linksState.links.map((link) => _buildLinkTile(link)),
        ],
      ),
    );
  }

  Widget _buildLinkTile(InstituteLinkModel link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: link.brandColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(link.iconData, color: link.brandColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: link.brandColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        link.platformDisplay.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: link.brandColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!link.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.slate200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HIDDEN',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate500),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  link.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  link.url,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.slate500),
            tooltip: 'Edit Link',
            onPressed: () => _showLinkDialog(existing: link),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.liveRed),
            tooltip: 'Delete Link',
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'Delete Link',
                message: 'Are you sure you want to delete "${link.title}"? Students will no longer see this link.',
                confirmText: 'Delete',
                isDestructive: true,
              );
              if (confirmed == true) {
                ref.read(instituteLinksProvider.notifier).deleteLink(link.id);
              }
            },
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /* TAB 2: TESTIMONIALS                                                        */
  /* -------------------------------------------------------------------------- */
  Widget _buildTestimonialsTab() {
    final testimonialsState = ref.watch(testimonialsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(testimonialsProvider.notifier).loadTestimonials(all: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner & Add Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Testimonials',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textLight),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Feature top rankers and student reviews on the Home screen.',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => _showTestimonialDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (testimonialsState.isLoading && testimonialsState.testimonials.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (testimonialsState.testimonials.isEmpty)
            const EmptyState(
              icon: Icons.reviews_outlined,
              title: 'No Testimonials Added',
              subtitle: 'Add student feedback, exam results, and quotes above to inspire your cohorts.',
            )
          else
            ...testimonialsState.testimonials.map((t) => _buildTestimonialTile(t)),
        ],
      ),
    );
  }

  Widget _buildTestimonialTile(TestimonialModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.skyBlueLight,
                child: Text(
                  t.initials,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.skyBlue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight),
                    ),
                    if (t.batchOrExam != null && t.batchOrExam!.isNotEmpty)
                      Text(
                        t.batchOrExam!,
                        style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  t.rating,
                  (_) => const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${t.quote}"',
            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.slate700, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: t.isPublished ? const Color(0xFFF0FDF4) : AppColors.slate100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t.isPublished ? 'PUBLISHED ON HOME' : 'DRAFT / HIDDEN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: t.isPublished ? const Color(0xFF16A34A) : AppColors.slate500,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.slate500),
                tooltip: 'Edit Review',
                onPressed: () => _showTestimonialDialog(existing: t),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.liveRed),
                tooltip: 'Delete Review',
                onPressed: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Delete Testimonial',
                    message: 'Are you sure you want to delete the testimonial from "${t.studentName}"?',
                    confirmText: 'Delete',
                    isDestructive: true,
                  );
                  if (confirmed == true) {
                    ref.read(testimonialsProvider.notifier).deleteTestimonial(t.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
