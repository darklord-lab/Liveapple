import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../data/mock_data.dart';

class DocumentViewer extends StatefulWidget {
  final DocumentItem? initialDocument;
  final VoidCallback? onClose;

  const DocumentViewer({
    super.key,
    this.initialDocument,
    this.onClose,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  late DocumentItem _currentDoc;
  int _currentPage = 0;
  double _zoomLevel = 1.0;

  final List<DocumentItem> _allDocs = MockData.sampleDocuments;

  @override
  void initState() {
    super.initState();
    _currentDoc = widget.initialDocument ?? _allDocs.first;
  }

  void _prevSlide() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _nextSlide() {
    if (_currentPage < _currentDoc.slides.length - 1) {
      setState(() => _currentPage++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = _currentDoc.slides;
    final slide = slides.isNotEmpty
        ? (_currentPage < slides.length ? slides[_currentPage] : slides.first)
        : null;

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
                  child: Icon(
                    _currentDoc.type.contains('PPT') ? Icons.slideshow_rounded : Icons.picture_as_pdf_rounded,
                    color: AppColors.indigo400,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),

                // Document Picker Dropdown
                Expanded(
                  child: PopupMenuButton<DocumentItem>(
                    onSelected: (doc) {
                      setState(() {
                        _currentDoc = doc;
                        _currentPage = 0;
                      });
                    },
                    itemBuilder: (context) => _allDocs.map((doc) {
                      return PopupMenuItem<DocumentItem>(
                        value: doc,
                        child: Row(
                          children: [
                            Icon(
                              doc.type.contains('PPT') ? Icons.slideshow_rounded : Icons.picture_as_pdf_rounded,
                              size: 16,
                              color: doc.id == _currentDoc.id ? AppColors.indigo600 : AppColors.slate600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                doc.fileName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: doc.id == _currentDoc.id ? FontWeight.w800 : FontWeight.w500,
                                  color: doc.id == _currentDoc.id ? AppColors.indigo700 : AppColors.slate900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentDoc.fileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_currentDoc.author} • ${slides.length} Pages (Tap to switch)',
                                style: const TextStyle(
                                  color: AppColors.indigo300,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.slate300, size: 18),
                      ],
                    ),
                  ),
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
            child: slide == null
                ? const Center(child: Text('No slide content', style: TextStyle(color: Colors.white)))
                : SingleChildScrollView(
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
                                  Text(
                                    _currentDoc.type.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Title & Subtitle
                              Text(
                                slide.title,
                                style: const TextStyle(
                                  fontSize: 17,
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
                                        Icon(Icons.functions_rounded, color: AppColors.amber400, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'CORE PRINCIPLE / EQUATION',
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

                              const SizedBox(height: 16),

                              // Diagram image
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
            child: Row(
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
            ),
          ),
        ],
      ),
    );
  }
}
