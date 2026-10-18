import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';

class DocumentViewer extends StatefulWidget {
  final DocumentItem? initialDocument;
  final VoidCallback? onClose;
  final bool isTeacher;
  final int? syncedPage;
  final String? docTitle;
  final String? docPath;
  final String? docUrl;
  final Function(int page)? onPageChanged;
  final Function(DocumentItem doc)? onDocumentChanged;
  final Function(String path, String name)? onLocalFileSelected;

  const DocumentViewer({
    super.key,
    this.initialDocument,
    this.onClose,
    this.isTeacher = true,
    this.syncedPage,
    this.docTitle,
    this.docPath,
    this.docUrl,
    this.onPageChanged,
    this.onDocumentChanged,
    this.onLocalFileSelected,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  String? _resolvedPdfPath;
  String? _currentTitle;
  bool _isDownloading = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isPdfReady = false;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.docTitle ?? widget.initialDocument?.fileName ?? 'PDF Presentation';
    if (widget.syncedPage != null && widget.syncedPage! > 0) {
      _currentPage = widget.syncedPage! - 1;
    }
    _resolveDocument();
  }

  @override
  void didUpdateWidget(DocumentViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.docTitle != null && widget.docTitle != _currentTitle) {
      setState(() => _currentTitle = widget.docTitle);
    }

    if (!widget.isTeacher && widget.syncedPage != null) {
      final target = widget.syncedPage! - 1;
      if (target >= 0 && target != _currentPage) {
        _currentPage = target;
        _pdfViewController?.setPage(target);
        if (mounted) setState(() {});
      }
    }

    if (widget.docPath != oldWidget.docPath || widget.docUrl != oldWidget.docUrl) {
      _resolveDocument();
    }
  }

  Future<void> _resolveDocument() async {
    // 1. Check local file path first
    if (widget.docPath != null && widget.docPath!.isNotEmpty) {
      final file = File(widget.docPath!);
      if (file.existsSync()) {
        setState(() {
          _resolvedPdfPath = widget.docPath;
          _isDownloading = false;
          _errorMessage = null;
        });
        return;
      }
    }

    // 2. Download from remote URL if provided
    if (widget.docUrl != null && widget.docUrl!.isNotEmpty) {
      setState(() {
        _isDownloading = true;
        _errorMessage = null;
      });

      try {
        final tempDir = await getTemporaryDirectory();
        final sanitized = widget.docUrl!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final targetFile = File('${tempDir.path}/slides_$sanitized.pdf');

        if (!targetFile.existsSync() || targetFile.lengthSync() == 0) {
          final dio = ApiClient().dio;
          var downloadUrl = widget.docUrl!;
          if (!downloadUrl.startsWith('http')) {
            final base = dio.options.baseUrl.endsWith('/')
                ? dio.options.baseUrl.substring(0, dio.options.baseUrl.length - 1)
                : dio.options.baseUrl;
            final path = downloadUrl.startsWith('/') ? downloadUrl : '/$downloadUrl';
            downloadUrl = '$base$path';
          }
          await dio.download(downloadUrl, targetFile.path);
        }

        if (mounted) {
          setState(() {
            _resolvedPdfPath = targetFile.path;
            _isDownloading = false;
            _errorMessage = null;
          });
        }
      } catch (e) {
        debugPrint('[DOC_VIEWER] PDF download error: $e');
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = 'PDF load nahi ho paya: $e';
          });
        }
      }
    }
  }

  Future<void> _pickLocalDocument() async {
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

        if (file.path != null) {
          setState(() {
            _resolvedPdfPath = file.path;
            _currentTitle = file.name;
            _isPdfReady = false;
            _currentPage = 0;
            _errorMessage = null;
          });
          widget.onLocalFileSelected?.call(file.path!, file.name);
          widget.onPageChanged?.call(1);
        }
      }
    } catch (e) {
      debugPrint('[DOC_PICKER] Error picking document: $e');
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      final target = _currentPage - 1;
      _pdfViewController?.setPage(target);
      setState(() => _currentPage = target);
      if (widget.isTeacher) {
        widget.onPageChanged?.call(target + 1);
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      final target = _currentPage + 1;
      _pdfViewController?.setPage(target);
      setState(() => _currentPage = target);
      if (widget.isTeacher) {
        widget.onPageChanged?.call(target + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

                // Document Title & Page Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentTitle ?? 'PDF Presentation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isPdfReady
                            ? 'Page ${_currentPage + 1} of $_totalPages'
                            : (_isDownloading ? 'Downloading...' : 'Real PDF Mode'),
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
                    tooltip: 'Change PDF File',
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    onPressed: _pickLocalDocument,
                  ),
              ],
            ),
          ),

          // Main Presentation Stage
          Expanded(
            child: _buildMainStage(),
          ),

          // Bottom Navigation Bar
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
                        onPressed: _currentPage > 0 ? _prevPage : null,
                        icon: const Icon(Icons.arrow_back_rounded, size: 14),
                        label: const Text('Previous', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.slate700,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.slate800,
                          disabledForegroundColor: AppColors.slate600,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text('Next Page', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigo600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.slate800,
                          disabledForegroundColor: AppColors.slate600,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          'Live Presentation • Page ${_currentPage + 1} of $_totalPages',
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

  Widget _buildMainStage() {
    if (_isDownloading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.indigo400),
            SizedBox(height: 16),
            Text(
              'PDF slides download ho rahi hain...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (widget.isTeacher)
                ElevatedButton.icon(
                  onPressed: _pickLocalDocument,
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: const Text('Device se dusri PDF chunein'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo600),
                )
              else
                ElevatedButton.icon(
                  onPressed: _resolveDocument,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Dobara koshish karein'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate700),
                ),
            ],
          ),
        ),
      );
    }

    if (_resolvedPdfPath != null) {
      return Stack(
        children: [
          PDFView(
            key: ValueKey(_resolvedPdfPath),
            filePath: _resolvedPdfPath!,
            enableSwipe: widget.isTeacher,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: _currentPage,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              if (mounted) {
                setState(() {
                  _totalPages = (pages != null && pages > 0) ? pages : 1;
                  _isPdfReady = true;
                });
              }
            },
            onViewCreated: (PDFViewController controller) {
              _pdfViewController = controller;
              if (_currentPage > 0) {
                controller.setPage(_currentPage);
              }
            },
            onPageChanged: (page, total) {
              if (page != null && page != _currentPage) {
                if (mounted) {
                  setState(() {
                    _currentPage = page;
                    if (total != null && total > 0) _totalPages = total;
                  });
                }
                if (widget.isTeacher) {
                  widget.onPageChanged?.call(page + 1);
                }
              }
            },
            onError: (error) {
              debugPrint('[PDFView] Error: $error');
              if (mounted) {
                setState(() => _errorMessage = 'PDF render error: $error');
              }
            },
            onPageError: (page, error) {
              debugPrint('[PDFView] Page $page error: $error');
            },
          ),
          if (!_isPdfReady)
            Container(
              color: AppColors.slate900,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.indigo400),
              ),
            ),
        ],
      );
    }

    // No PDF loaded yet
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate800,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.slate700),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.indigo400,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isTeacher ? 'Koi PDF select nahi hai' : 'Waiting for Teacher\'s Slides',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isTeacher
                  ? 'Apne device se PDF presentation chunein aur live class me padhayein'
                  : 'Teacher jab PDF present karenge, yahan real PDF pages display ho jayenge',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate400, fontSize: 12),
            ),
            const SizedBox(height: 20),
            if (widget.isTeacher)
              ElevatedButton.icon(
                onPressed: _pickLocalDocument,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Select PDF Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
