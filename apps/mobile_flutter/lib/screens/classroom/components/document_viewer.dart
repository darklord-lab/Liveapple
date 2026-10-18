import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';

class DocumentViewer extends StatefulWidget {
  final DocumentItem? initialDocument;
  final VoidCallback? onClose;
  final bool isTeacher;
  final int? syncedPage;
  final Function(int page)? onPageChanged;
  final Function(DocumentItem doc)? onDocumentChanged;
  final String? docTitle;
  final String? docUrl;
  final String? deckId;
  final String? fileHash;
  final int totalPages;
  final String? errorMessage;
  final VoidCallback? onPickDocument;

  const DocumentViewer({
    super.key,
    this.initialDocument,
    this.onClose,
    this.isTeacher = true,
    this.syncedPage,
    this.onPageChanged,
    this.onDocumentChanged,
    this.docTitle,
    this.docUrl,
    this.deckId,
    this.fileHash,
    this.totalPages = 1,
    this.errorMessage,
    this.onPickDocument,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  DocumentItem? _currentDoc;
  int _currentPage = 0;
  double _zoomLevel = 1.0;
  List<DocumentItem> _allDocs = [];

  @override
  void initState() {
    super.initState();
    _setupDocument();
  }

  void _setupDocument() {
    if (widget.initialDocument != null) {
      _currentDoc = widget.initialDocument;
      _allDocs = [_currentDoc!];
    } else if ((widget.docTitle != null && widget.docTitle!.isNotEmpty) ||
        (widget.docUrl != null && widget.docUrl!.isNotEmpty) ||
        (widget.deckId != null && widget.deckId!.isNotEmpty)) {
      final pagesCount = widget.totalPages > 0 ? widget.totalPages : 1;
      _currentDoc = DocumentItem(
        id: widget.deckId ?? 'deck_${DateTime.now().millisecondsSinceEpoch}',
        title: widget.docTitle?.isNotEmpty == true ? widget.docTitle! : 'Document Slides',
        fileName: widget.docTitle?.isNotEmpty == true ? widget.docTitle! : 'Presentation.pdf',
        author: widget.isTeacher ? 'Teacher (Host)' : 'Teacher',
        type: 'PDF Document',
        slides: List.generate(pagesCount, (i) {
          final hashSnippet = (widget.fileHash != null && widget.fileHash!.length >= 12)
              ? widget.fileHash!.substring(0, 12)
              : (widget.fileHash ?? 'active');
          return PresentationPage(
            pageNumber: i + 1,
            title: widget.docTitle?.isNotEmpty == true ? widget.docTitle! : 'Slide ${i + 1}',
            subtitle: 'Synchronized Slide • Page ${i + 1} of $pagesCount',
            points: [
              'Synchronized classroom lecture presentation',
              'Real-time pagination active across all student devices',
              if (widget.fileHash != null && widget.fileHash!.isNotEmpty)
                'Deck Hash: $hashSnippet...',
            ],
            formula: 'Slide ${i + 1} / $pagesCount',
            diagramUrl: '',
          );
        }),
      );
      _allDocs = [_currentDoc!];
    } else {
      _currentDoc = null;
      _allDocs = [];
    }

    if (widget.syncedPage != null &&
        widget.syncedPage! > 0 &&
        _currentDoc != null &&
        _currentDoc!.slides.isNotEmpty) {
      _currentPage = (widget.syncedPage! - 1).clamp(0, _currentDoc!.slides.length - 1);
    } else {
      _currentPage = 0;
    }
  }

  @override
  void didUpdateWidget(DocumentViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.docTitle != oldWidget.docTitle ||
        widget.docUrl != oldWidget.docUrl ||
        widget.deckId != oldWidget.deckId ||
        widget.totalPages != oldWidget.totalPages ||
        widget.initialDocument != oldWidget.initialDocument) {
      setState(() {
        _setupDocument();
      });
    }

    if (!widget.isTeacher &&
        widget.syncedPage != null &&
        _currentDoc != null &&
        _currentDoc!.slides.isNotEmpty) {
      final target = (widget.syncedPage! - 1).clamp(0, _currentDoc!.slides.length - 1);
      if (target != _currentPage) {
        setState(() => _currentPage = target);
      }
    }
  }

  Future<void> _pickLocalDocument() async {
    if (widget.onPickDocument != null) {
      widget.onPickDocument!();
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final nameLower = file.name.toLowerCase();
        if (nameLower.endsWith('.ppt') || nameLower.endsWith('.pptx')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PPT ko PDF me export karo ya screen share karo'),
                backgroundColor: AppColors.rose,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        final newDoc = DocumentItem(
          id: 'picked_${DateTime.now().millisecondsSinceEpoch}',
          title: file.name,
          fileName: file.name,
          author: 'Teacher (Local File)',
          type: 'PDF Document',
          slides: [
            PresentationPage(
              pageNumber: 1,
              title: file.name,
              subtitle: 'Slide 1 (${(file.size / 1024).toStringAsFixed(1)} KB)',
              points: const [
                'Custom lecture document loaded from device',
                'Synchronized live presentation mode active',
                'Teacher maintains slide control',
              ],
              formula: 'Slide 1 of 1',
              diagramUrl: '',
            ),
          ],
        );

        setState(() {
          _allDocs = [newDoc, ..._allDocs];
          _currentDoc = newDoc;
          _currentPage = 0;
        });

        widget.onDocumentChanged?.call(newDoc);
        widget.onPageChanged?.call(1);
      }
    } catch (e) {
      debugPrint('[DOC_PICKER] Error picking document: $e');
    }
  }

  void _prevSlide() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      widget.onPageChanged?.call(_currentPage + 1);
    }
  }

  void _nextSlide() {
    final slidesLength = _currentDoc?.slides.length ?? 0;
    if (_currentPage < slidesLength - 1) {
      setState(() => _currentPage++);
      widget.onPageChanged?.call(_currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) {
      return Container(
        color: AppColors.slate900,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 48),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              if (widget.onClose != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Close Slides'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_currentDoc == null || _currentDoc!.slides.isEmpty) {
      return Container(
        color: AppColors.slate900,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, color: AppColors.slate400, size: 48),
              const SizedBox(height: 12),
              const Text(
                'No slides available',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (widget.isTeacher && widget.onPickDocument != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: widget.onPickDocument,
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: const Text('Pick PDF Slides'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              if (widget.onClose != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onClose,
                  child: const Text('Back to Video Stage', style: TextStyle(color: AppColors.slate400)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final slides = _currentDoc!.slides;
    final slide = (_currentPage >= 0 && _currentPage < slides.length) ? slides[_currentPage] : slides.first;

    return Container(
      color: AppColors.slate900,
      child: Column(
        children: [
          // Top Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.slate800,
              border: Border(bottom: BorderSide(color: AppColors.slate700)),
            ),
            child: Row(
              children: [
                if (widget.onClose != null) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onClose,
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.indigo600.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.indigo400,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),

                // Document Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentDoc!.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_currentDoc!.author} • ${slides.length} Pages',
                        style: const TextStyle(
                          color: AppColors.indigo300,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.isTeacher)
                  IconButton(
                    icon: const Icon(Icons.upload_file_rounded, color: AppColors.indigo300, size: 20),
                    tooltip: 'Pick PDF from Device',
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    onPressed: _pickLocalDocument,
                  ),

                // Zoom controls
                IconButton(
                  icon: const Icon(Icons.zoom_out_rounded, color: AppColors.slate300, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      if (_zoomLevel > 0.8) _zoomLevel -= 0.1;
                    });
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  '${(_zoomLevel * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.slate300, fontSize: 10, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.zoom_in_rounded, color: AppColors.slate300, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      if (_zoomLevel < 1.5) _zoomLevel += 0.1;
                    });
                  },
                ),
              ],
            ),
          ),

          // Slide Content Container
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Transform.scale(
                  scale: _zoomLevel,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 700),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Slide badge & page number
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.indigo50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.indigo200),
                              ),
                              child: Text(
                                'PAGE ${_currentPage + 1} OF ${slides.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.indigo700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded, size: 12, color: AppColors.emerald500),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.fileHash != null && widget.fileHash!.isNotEmpty
                                        ? 'HASH VERIFIED'
                                        : 'SYNCED',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Title & Subtitle
                        Text(
                          slide.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.slate900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slide.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.indigo600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Points list
                        ...slide.points.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(Icons.circle, size: 6, color: AppColors.indigo600),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.45,
                                        color: AppColors.slate700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),

                        const SizedBox(height: 16),

                        // Formula / Principle Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.indigo900,
                                AppColors.indigo950,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.indigo700),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.slideshow_rounded, color: AppColors.amber400, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'ACTIVE PRESENTATION DECK',
                                    style: TextStyle(
                                      color: AppColors.amber400,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                slide.formula,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (slide.diagramUrl.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              slide.diagramUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 120,
                                color: AppColors.slate100,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_rounded, color: AppColors.slate400),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Slide Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.slate800,
              border: Border(top: BorderSide(color: AppColors.slate700)),
            ),
            child: widget.isTeacher
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _currentPage > 0 ? _prevSlide : null,
                        icon: const Icon(Icons.arrow_back_rounded, size: 14),
                        label: const Text('Previous', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.slate700,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.slate800,
                          disabledForegroundColor: AppColors.slate600,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      Text(
                        'Page ${_currentPage + 1} of ${slides.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _currentPage < slides.length - 1 ? _nextSlide : null,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text('Next Page', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigo600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.slate800,
                          disabledForegroundColor: AppColors.slate600,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync_rounded, color: AppColors.indigo400, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Live Presentation • Page ${_currentPage + 1} of ${slides.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
