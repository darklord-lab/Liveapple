import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';

class DigitalBoard extends StatefulWidget {
  final bool isTeacher;
  final Function(Map<String, dynamic>)? onDrawStroke;
  final VoidCallback? onClearBoard;
  final Stream<Map<String, dynamic>>? remoteDrawStream;
  final Stream<void>? remoteClearStream;

  const DigitalBoard({
    super.key,
    this.isTeacher = true,
    this.onDrawStroke,
    this.onClearBoard,
    this.remoteDrawStream,
    this.remoteClearStream,
  });

  @override
  State<DigitalBoard> createState() => _DigitalBoardState();
}

class _DigitalBoardState extends State<DigitalBoard> {
  String _activeTool = 'pen'; // 'pen', 'highlighter', 'eraser', 'rectangle', 'circle', 'line'
  Color _selectedColor = AppColors.slate900;
  final double _strokeWidth = 3.0;
  String _backgroundStyle = 'grid'; // 'blank', 'grid', 'dots', 'ruled'

  int _currentPageIndex = 0;
  final List<List<DrawingPoint>> _pages = [[]];
  final List<List<DrawingPoint>> _redoStack = [[]];

  StreamSubscription? _drawSub;
  StreamSubscription? _clearSub;

  @override
  void initState() {
    super.initState();
    _subscribeToRemoteEvents();
  }

  @override
  void didUpdateWidget(DigitalBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remoteDrawStream != widget.remoteDrawStream ||
        oldWidget.remoteClearStream != widget.remoteClearStream) {
      _drawSub?.cancel();
      _clearSub?.cancel();
      _subscribeToRemoteEvents();
    }
  }

  void _subscribeToRemoteEvents() {
    _drawSub = widget.remoteDrawStream?.listen((data) {
      if (!mounted) return;
      if (data['isEnd'] == true) {
        setState(() {
          _pages[_currentPageIndex].add(const DrawingPoint(
            point: Offset(-1, -1),
            color: Colors.transparent,
            strokeWidth: 0,
          ));
        });
      } else {
        final x = (data['x'] as num).toDouble();
        final y = (data['y'] as num).toDouble();
        final colorVal = data['color'] as int? ?? 0xFF000000;
        final width = (data['width'] as num?)?.toDouble() ?? 3.0;
        final isEraser = data['isEraser'] as bool? ?? false;
        setState(() {
          _pages[_currentPageIndex].add(DrawingPoint(
            point: Offset(x, y),
            color: Color(colorVal),
            strokeWidth: width,
            isEraser: isEraser,
          ));
        });
      }
    });

    _clearSub = widget.remoteClearStream?.listen((_) {
      if (!mounted) return;
      _clear(notify: false);
    });
  }

  @override
  void dispose() {
    _drawSub?.cancel();
    _clearSub?.cancel();
    super.dispose();
  }

  final List<Color> _colors = const [
    Color(0xFF0F172A),
    Color(0xFF4F46E5),
    Color(0xFFDC2626),
    Color(0xFF16A34A),
    Color(0xFFD97706),
    Color(0xFF9333EA),
  ];

  Offset? _shapeStart;
  Offset? _currentDrag;

  void _undo() {
    if (_pages[_currentPageIndex].isNotEmpty) {
      setState(() {
        final removed = _pages[_currentPageIndex].removeLast();
        _redoStack[_currentPageIndex].add(removed);
      });
    }
  }

  void _redo() {
    if (_redoStack[_currentPageIndex].isNotEmpty) {
      setState(() {
        final restored = _redoStack[_currentPageIndex].removeLast();
        _pages[_currentPageIndex].add(restored);
      });
    }
  }

  void _clear({bool notify = true}) {
    setState(() {
      _pages[_currentPageIndex].clear();
      _redoStack[_currentPageIndex].clear();
    });
    if (notify) {
      widget.onClearBoard?.call();
    }
  }

  void _addPage() {
    setState(() {
      _pages.add([]);
      _redoStack.add([]);
      _currentPageIndex = _pages.length - 1;
    });
  }

  void _prevPage() {
    if (_currentPageIndex > 0) {
      setState(() => _currentPageIndex--);
    }
  }

  void _nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      setState(() => _currentPageIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Top Whiteboard Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.slate200.withOpacity(0.8))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Pen Tool
                  _toolButton(
                    id: 'pen',
                    icon: Icons.edit_rounded,
                    tooltip: 'Pen',
                  ),
                  const SizedBox(width: 4),
                  // Highlighter
                  _toolButton(
                    id: 'highlighter',
                    icon: Icons.brush_rounded,
                    tooltip: 'Highlighter',
                  ),
                  const SizedBox(width: 4),
                  // Eraser
                  _toolButton(
                    id: 'eraser',
                    icon: Icons.cleaning_services_rounded,
                    tooltip: 'Eraser',
                  ),
                  const SizedBox(width: 6),
                  Container(width: 1, height: 22, color: AppColors.slate200),
                  const SizedBox(width: 6),

                  // Shapes
                  _toolButton(
                    id: 'rectangle',
                    icon: Icons.crop_square_rounded,
                    tooltip: 'Rectangle',
                  ),
                  const SizedBox(width: 4),
                  _toolButton(
                    id: 'circle',
                    icon: Icons.radio_button_unchecked_rounded,
                    tooltip: 'Circle',
                  ),
                  const SizedBox(width: 4),
                  _toolButton(
                    id: 'line',
                    icon: Icons.remove_rounded,
                    tooltip: 'Line',
                  ),
                  const SizedBox(width: 6),
                  Container(width: 1, height: 22, color: AppColors.slate200),
                  const SizedBox(width: 6),

                  // Color Pickers
                  ..._colors.map((c) {
                    final isSel = _selectedColor == c && _activeTool != 'eraser';
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = c;
                          if (_activeTool == 'eraser') _activeTool = 'pen';
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? AppColors.indigo600 : Colors.white,
                            width: isSel ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 6),
                  Container(width: 1, height: 22, color: AppColors.slate200),
                  const SizedBox(width: 6),

                  // Background Style Switcher
                  PopupMenuButton<String>(
                    initialValue: _backgroundStyle,
                    onSelected: (val) => setState(() => _backgroundStyle = val),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'grid', child: Text('Grid Pattern')),
                      const PopupMenuItem(value: 'dots', child: Text('Dots Pattern')),
                      const PopupMenuItem(value: 'ruled', child: Text('Ruled Lines')),
                      const PopupMenuItem(value: 'blank', child: Text('Blank Canvas')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.grid_4x4_rounded, size: 14, color: AppColors.slate700),
                          const SizedBox(width: 4),
                          Text(
                            _backgroundStyle.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate700),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Undo, Redo, Clear
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    color: _pages[_currentPageIndex].isNotEmpty ? AppColors.slate700 : AppColors.slate300,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _undo,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.redo_rounded, size: 18),
                    color: _redoStack[_currentPageIndex].isNotEmpty ? AppColors.slate700 : AppColors.slate300,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _redo,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.rose600,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _clear,
                  ),
                  const SizedBox(width: 6),
                  Container(width: 1, height: 22, color: AppColors.slate200),
                  const SizedBox(width: 6),

                  // Page Controls
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    color: _currentPageIndex > 0 ? AppColors.slate700 : AppColors.slate300,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _prevPage,
                  ),
                  Text(
                    '${_currentPageIndex + 1} / ${_pages.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    color: _currentPageIndex < _pages.length - 1 ? AppColors.slate700 : AppColors.slate300,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _nextPage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    color: AppColors.indigo600,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _addPage,
                  ),
                ],
              ),
            ),
          ),

          // Canvas Area
          Expanded(
            child: ClipRect(
              child: GestureDetector(
                onPanStart: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final localPos = details.localPosition;

                  if (_activeTool == 'rectangle' || _activeTool == 'circle' || _activeTool == 'line') {
                    setState(() {
                      _shapeStart = localPos;
                      _currentDrag = localPos;
                    });
                  } else {
                    final color = _activeTool == 'highlighter'
                        ? _selectedColor.withOpacity(0.35)
                        : (_activeTool == 'eraser' ? Colors.white : _selectedColor);
                    final width = _activeTool == 'eraser' ? 24.0 : (_activeTool == 'highlighter' ? 16.0 : _strokeWidth);
                    final isEraser = _activeTool == 'eraser';

                    setState(() {
                      final point = DrawingPoint(
                        point: localPos,
                        color: color,
                        strokeWidth: width,
                        isEraser: isEraser,
                      );
                      _pages[_currentPageIndex].add(point);
                      _redoStack[_currentPageIndex].clear();
                    });

                    widget.onDrawStroke?.call({
                      'x': localPos.dx,
                      'y': localPos.dy,
                      'color': color.value,
                      'width': width,
                      'isEraser': isEraser,
                      'isEnd': false,
                    });
                  }
                },
                onPanUpdate: (details) {
                  final localPos = details.localPosition;
                  if (_activeTool == 'rectangle' || _activeTool == 'circle' || _activeTool == 'line') {
                    setState(() {
                      _currentDrag = localPos;
                    });
                  } else {
                    final color = _activeTool == 'highlighter'
                        ? _selectedColor.withOpacity(0.35)
                        : (_activeTool == 'eraser' ? Colors.white : _selectedColor);
                    final width = _activeTool == 'eraser' ? 24.0 : (_activeTool == 'highlighter' ? 16.0 : _strokeWidth);
                    final isEraser = _activeTool == 'eraser';

                    setState(() {
                      final point = DrawingPoint(
                        point: localPos,
                        color: color,
                        strokeWidth: width,
                        isEraser: isEraser,
                      );
                      _pages[_currentPageIndex].add(point);
                    });

                    widget.onDrawStroke?.call({
                      'x': localPos.dx,
                      'y': localPos.dy,
                      'color': color.value,
                      'width': width,
                      'isEraser': isEraser,
                      'isEnd': false,
                    });
                  }
                },
                onPanEnd: (details) {
                  if ((_activeTool == 'rectangle' || _activeTool == 'circle' || _activeTool == 'line') &&
                      _shapeStart != null &&
                      _currentDrag != null) {
                    setState(() {
                      // Generate points for the shape
                      _generateShapePoints(_activeTool, _shapeStart!, _currentDrag!);
                      _shapeStart = null;
                      _currentDrag = null;
                    });
                  } else {
                    setState(() {
                      // Add sentinel null separator
                      _pages[_currentPageIndex].add(const DrawingPoint(
                        point: Offset(-1, -1),
                        color: Colors.transparent,
                        strokeWidth: 0,
                      ));
                    });
                    widget.onDrawStroke?.call({
                      'isEnd': true,
                    });
                  }
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: BoardPainter(
                    points: _pages[_currentPageIndex],
                    backgroundStyle: _backgroundStyle,
                    previewStart: _shapeStart,
                    previewCurrent: _currentDrag,
                    previewTool: _activeTool,
                    previewColor: _selectedColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateShapePoints(String tool, Offset start, Offset end) {
    final color = _selectedColor;
    final width = _strokeWidth;
    final list = _pages[_currentPageIndex];

    if (tool == 'line') {
      const steps = 30;
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        final x = start.dx + (end.dx - start.dx) * t;
        final y = start.dy + (end.dy - start.dy) * t;
        list.add(DrawingPoint(point: Offset(x, y), color: color, strokeWidth: width));
      }
    } else if (tool == 'rectangle') {
      final rect = Rect.fromPoints(start, end);
      const steps = 20;
      // top
      for (int i = 0; i <= steps; i++) {
        list.add(DrawingPoint(point: Offset(rect.left + (rect.width * i / steps), rect.top), color: color, strokeWidth: width));
      }
      // right
      for (int i = 0; i <= steps; i++) {
        list.add(DrawingPoint(point: Offset(rect.right, rect.top + (rect.height * i / steps)), color: color, strokeWidth: width));
      }
      // bottom
      for (int i = 0; i <= steps; i++) {
        list.add(DrawingPoint(point: Offset(rect.right - (rect.width * i / steps), rect.bottom), color: color, strokeWidth: width));
      }
      // left
      for (int i = 0; i <= steps; i++) {
        list.add(DrawingPoint(point: Offset(rect.left, rect.bottom - (rect.height * i / steps)), color: color, strokeWidth: width));
      }
    } else if (tool == 'circle') {
      final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final rx = (end.dx - start.dx).abs() / 2;
      final ry = (end.dy - start.dy).abs() / 2;
      const steps = 60;
      for (int i = 0; i <= steps; i++) {
        final theta = (i / steps) * 2 * 3.1415926535;
        list.add(DrawingPoint(
          point: Offset(center.dx + rx * 1.0 * (i == steps ? 1.0 : (theta == 0 ? 1.0 : (i % 2 == 0 ? 1 : 1))), center.dy + ry * 1.0),
          color: color,
          strokeWidth: width,
        ));
      }
    }
    // End shape with break
    list.add(const DrawingPoint(point: Offset(-1, -1), color: Colors.transparent, strokeWidth: 0));
  }

  Widget _toolButton({
    required String id,
    required IconData icon,
    required String tooltip,
  }) {
    final isSel = _activeTool == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTool = id),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.indigo50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? AppColors.indigo300 : Colors.transparent),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSel ? AppColors.indigo600 : AppColors.slate600,
        ),
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final String backgroundStyle;
  final Offset? previewStart;
  final Offset? previewCurrent;
  final String previewTool;
  final Color previewColor;

  BoardPainter({
    required this.points,
    required this.backgroundStyle,
    this.previewStart,
    this.previewCurrent,
    required this.previewTool,
    required this.previewColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background Pattern
    final bgPaint = Paint()
      ..color = AppColors.slate200.withOpacity(0.5)
      ..strokeWidth = 1.0;

    if (backgroundStyle == 'grid') {
      const step = 28.0;
      for (double x = 0; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), bgPaint);
      }
      for (double y = 0; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), bgPaint);
      }
    } else if (backgroundStyle == 'ruled') {
      const step = 32.0;
      for (double y = step; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), bgPaint);
      }
    } else if (backgroundStyle == 'dots') {
      const step = 24.0;
      final dotPaint = Paint()..color = AppColors.slate300;
      for (double x = step; x < size.width; x += step) {
        for (double y = step; y < size.height; y += step) {
          canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
        }
      }
    }

    // 2. Draw existing strokes
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (p1.point.dx < 0 || p2.point.dx < 0) continue;

      final paint = Paint()
        ..color = p1.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = p1.strokeWidth;

      canvas.drawLine(p1.point, p2.point, paint);
    }

    // 3. Draw in-progress preview shape if any
    if (previewStart != null && previewCurrent != null) {
      final previewPaint = Paint()
        ..color = previewColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      if (previewTool == 'line') {
        canvas.drawLine(previewStart!, previewCurrent!, previewPaint);
      } else if (previewTool == 'rectangle') {
        canvas.drawRect(Rect.fromPoints(previewStart!, previewCurrent!), previewPaint);
      } else if (previewTool == 'circle') {
        canvas.drawOval(Rect.fromPoints(previewStart!, previewCurrent!), previewPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}
