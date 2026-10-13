import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/study_material_controller.dart';
import '../../domain/models/study_material_model.dart';

class StudyMaterialTabView extends ConsumerStatefulWidget {
  final String batchId;
  final bool isTeacher;
  final String? batchName;

  const StudyMaterialTabView({
    super.key,
    required this.batchId,
    this.isTeacher = false,
    this.batchName,
  });

  @override
  ConsumerState<StudyMaterialTabView> createState() => _StudyMaterialTabViewState();
}

class _StudyMaterialTabViewState extends ConsumerState<StudyMaterialTabView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(studyMaterialProvider.notifier).loadBatch(widget.batchId, resetFolder: true);
    });
  }

  @override
  void didUpdateWidget(covariant StudyMaterialTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.batchId != widget.batchId) {
      ref.read(studyMaterialProvider.notifier).loadBatch(widget.batchId, resetFolder: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyMaterialProvider);
    final notifier = ref.read(studyMaterialProvider.notifier);

    return Column(
      children: [
        // 1. Search & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => notifier.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search in this folder...',
                      hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppColors.slate400, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                notifier.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort Popup
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: AppColors.skyBlue),
                tooltip: 'Sort materials',
                onSelected: (sort) => notifier.setSortOption(sort),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'newest', child: Text('Newest First')),
                  const PopupMenuItem(value: 'oldest', child: Text('Oldest First')),
                  const PopupMenuItem(value: 'title_asc', child: Text('Name (A-Z)')),
                  const PopupMenuItem(value: 'title_desc', child: Text('Name (Z-A)')),
                ],
              ),
              if (widget.isTeacher) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined, color: AppColors.skyBlue),
                  tooltip: 'Create Folder',
                  onPressed: () => _showCreateFolderDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file, color: AppColors.skyBlue),
                  tooltip: 'Upload Material',
                  onPressed: () => _showUploadModal(context),
                ),
              ],
            ],
          ),
        ),

        // 2. Breadcrumbs Navigation
        if (state.folderPath.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.white,
            child: Row(
              children: [
                InkWell(
                  onTap: () => notifier.navigateUp(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 16, color: AppColors.skyBlue),
                      SizedBox(width: 4),
                      Text('Back', style: TextStyle(color: AppColors.skyBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text('/', style: TextStyle(color: AppColors.slate400)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.currentFolder?.name ?? 'Root',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 1, color: AppColors.borderLight),

        // 3. Main Content
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                            const SizedBox(height: 8),
                            Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate500)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => notifier.loadBatch(widget.batchId),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
                              child: const Text('Retry', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => notifier.loadBatch(widget.batchId),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          // Non-enrolled Banner
                          if (!state.isEnrolled)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'You are viewing free preview materials. Enroll in this batch to unlock all lecture notes & study resources.',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Folders Section
                          if (state.folders.isNotEmpty) ...[
                            const Text(
                              'FOLDERS',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate500, letterSpacing: 1),
                            ),
                            const SizedBox(height: 8),
                            ...state.folders.map((folder) => _buildFolderTile(folder, notifier)),
                            const SizedBox(height: 16),
                          ],

                          // Materials Section
                          if (state.materials.isNotEmpty) ...[
                            Text(
                              'FILES & RESOURCES (${state.materials.length})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate500, letterSpacing: 1),
                            ),
                            const SizedBox(height: 8),
                            ...state.materials.map((mat) => _buildMaterialTile(mat, notifier)),
                          ],

                          // Empty State
                          if (state.folders.isEmpty && state.materials.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  Icon(Icons.folder_open_outlined, size: 54, color: AppColors.slate400.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Study Materials Yet',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textLight),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.isTeacher
                                        ? 'Tap the buttons above to create folders or upload PDF notes & lecture links.'
                                        : 'Your teacher has not uploaded any study notes for this section yet.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  // Folder Tile
  Widget _buildFolderTile(MaterialFolderModel folder, StudyMaterialNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        onTap: () => notifier.openFolder(folder),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder, color: Colors.amber, size: 24),
        ),
        title: Text(
          folder.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight),
        ),
        subtitle: Text(
          '${folder.materialsCount} items',
          style: const TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isTeacher)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Delete folder',
                onPressed: () => _confirmDeleteFolder(context, folder, notifier),
              ),
            const Icon(Icons.chevron_right, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }

  // Material Tile
  Widget _buildMaterialTile(StudyMaterialModel mat, StudyMaterialNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        onTap: () => _handleOpenMaterial(context, mat),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: mat.iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(mat.iconData, color: mat.iconColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                mat.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (mat.isFree)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('FREE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              mat.isLink
                  ? (mat.url ?? 'External Link')
                  : '${mat.fileName ?? 'File'} • ${mat.formattedSize}',
              style: const TextStyle(fontSize: 11, color: AppColors.slate500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                mat.isLink ? Icons.open_in_new : Icons.download,
                size: 20,
                color: AppColors.skyBlue,
              ),
              tooltip: mat.isLink ? 'Open Link' : 'Download File',
              onPressed: () => _handleOpenMaterial(context, mat),
            ),
            if (widget.isTeacher)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Delete material',
                onPressed: () => _confirmDeleteMaterial(context, mat, notifier),
              ),
          ],
        ),
      ),
    );
  }

  // Open / Download Handler
  Future<void> _handleOpenMaterial(BuildContext context, StudyMaterialModel mat) async {
    if (mat.isLink && mat.url != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(mat.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mat.description != null && mat.description!.isNotEmpty) ...[
                Text(mat.description!, style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
                const SizedBox(height: 12),
              ],
              SelectableText(
                mat.url!,
                style: const TextStyle(color: AppColors.skyBlue, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: mat.url!));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.copy, size: 16, color: Colors.white),
              label: const Text('Copy Link', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
            ),
          ],
        ),
      );
      return;
    }

    // Physical File Download
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        SnackBar(content: Text('Downloading "${mat.title}"...')),
      );

      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/${mat.fileName ?? 'download_${mat.id}.pdf'}';

      await ref.read(studyMaterialProvider.notifier).downloadFile(mat.id, savePath);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Downloaded to: $savePath'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Create Folder Dialog
  void _showCreateFolderDialog(BuildContext context) {
    final folderNameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Folder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: folderNameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'e.g. Chapter 1: Thermodynamics',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = folderNameCtrl.text.trim();
              if (name.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final success = await ref.read(studyMaterialProvider.notifier).createFolder(name);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Folder "$name" created!' : 'Failed to create folder'),
                  backgroundColor: success ? AppColors.success : Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Upload Material Modal (File or Link)
  void _showUploadModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _UploadMaterialModal(
        onUploadFile: (title, desc, isFree, bytes, name) async {
          return await ref.read(studyMaterialProvider.notifier).uploadFile(
                title: title,
                description: desc,
                isFree: isFree,
                fileBytes: bytes,
                fileName: name,
              );
        },
        onAddLink: (title, desc, isFree, url, kind) async {
          return await ref.read(studyMaterialProvider.notifier).addLink(
                title: title,
                description: desc,
                url: url,
                isFree: isFree,
                kind: kind,
              );
        },
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context, MaterialFolderModel folder, StudyMaterialNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Folder "${folder.name}"?'),
        content: const Text('All materials inside this folder will also be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await notifier.deleteFolder(folder.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMaterial(BuildContext context, StudyMaterialModel mat, StudyMaterialNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${mat.title}"?'),
        content: const Text('This study material will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await notifier.deleteMaterial(mat.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _UploadMaterialModal extends StatefulWidget {
  final Future<bool> Function(String title, String? desc, bool isFree, List<int> bytes, String name) onUploadFile;
  final Future<bool> Function(String title, String? desc, bool isFree, String url, String? kind) onAddLink;

  const _UploadMaterialModal({
    required this.onUploadFile,
    required this.onAddLink,
  });

  @override
  State<_UploadMaterialModal> createState() => _UploadMaterialModalState();
}

class _UploadMaterialModalState extends State<_UploadMaterialModal> {
  int _selectedTab = 0; // 0: File upload, 1: Link
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isFree = false;

  PlatformFile? _pickedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        if (_titleController.text.isEmpty) {
          _titleController.text = _pickedFile!.name.split('.').first;
        }
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool success = false;
    if (_selectedTab == 0) {
      if (_pickedFile == null || (_pickedFile!.bytes == null && _pickedFile!.path == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick a file to upload')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      List<int> bytes;
      if (_pickedFile!.bytes != null) {
        bytes = _pickedFile!.bytes!;
      } else {
        bytes = await File(_pickedFile!.path!).readAsBytes();
      }

      success = await widget.onUploadFile(
        title,
        _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        _isFree,
        bytes,
        _pickedFile!.name,
      );
    } else {
      final url = _urlController.text.trim();
      if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid URL (starting with http:// or https://)')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final kind = (url.contains('youtube.com') || url.contains('youtu.be') || url.contains('vimeo'))
          ? 'VIDEO_LINK'
          : 'LINK';

      success = await widget.onAddLink(
        title,
        _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        _isFree,
        url,
        kind,
      );
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study material uploaded successfully!'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload study material'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Upload Study Material', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),

            // Tab selector: File vs Link
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedTab = 0),
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: const Text('File Upload'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _selectedTab == 0 ? Colors.white : AppColors.slate700,
                      backgroundColor: _selectedTab == 0 ? AppColors.skyBlue : Colors.transparent,
                      side: BorderSide(color: _selectedTab == 0 ? AppColors.skyBlue : AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedTab = 1),
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('External Link'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _selectedTab == 1 ? Colors.white : AppColors.slate700,
                      backgroundColor: _selectedTab == 1 ? AppColors.skyBlue : Colors.transparent,
                      side: BorderSide(color: _selectedTab == 1 ? AppColors.skyBlue : AppColors.borderLight),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Material Title *',
                hintText: 'e.g. Wave Optics Formula Sheet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief summary of concepts covered...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // File or URL input
            if (_selectedTab == 0) ...[
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight, style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: AppColors.skyBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickedFile != null
                              ? '${_pickedFile!.name} (${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB)'
                              : 'Tap to pick PDF / Document / Image (max 25MB)',
                          style: TextStyle(
                            fontSize: 13,
                            color: _pickedFile != null ? AppColors.textLight : AppColors.slate500,
                            fontWeight: _pickedFile != null ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Resource URL *',
                  hintText: 'https://youtube.com/watch?v=... or https://...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Free Preview Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Free Preview (Available to Non-Enrolled Students)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Allow prospective students to view/download this material', style: TextStyle(fontSize: 11, color: AppColors.slate500)),
              value: _isFree,
              activeColor: AppColors.skyBlue,
              onChanged: (val) => setState(() => _isFree = val),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Publish Study Material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
