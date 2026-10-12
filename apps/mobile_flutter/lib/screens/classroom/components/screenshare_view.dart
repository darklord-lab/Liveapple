import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ScreenShareView extends StatefulWidget {
  final bool isTeacher;
  final VoidCallback? onStopSharing;

  const ScreenShareView({
    super.key,
    this.isTeacher = true,
    this.onStopSharing,
  });

  @override
  State<ScreenShareView> createState() => _ScreenShareViewState();
}

class _ScreenShareViewState extends State<ScreenShareView> {
  // Active App on Device Screen: 'home' | 'youtube' | 'browser' | 'calculator' | 'gallery' | 'files' | 'geogebra'
  String _activeDeviceApp = 'home';

  // Calculator State
  String _calcDisplay = '0';
  String _calcSub = '';

  // Browser URL
  final TextEditingController _urlController = TextEditingController(text: 'https://en.wikipedia.org/wiki/Rotational_dynamics');

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _onCalcPress(String val) {
    setState(() {
      if (val == 'C') {
        _calcDisplay = '0';
        _calcSub = '';
      } else if (val == '=') {
        try {
          _calcSub = '$_calcDisplay =';
          if (_calcDisplay.contains('+')) {
            final p = _calcDisplay.split('+');
            _calcDisplay = (double.parse(p[0]) + double.parse(p[1])).toString();
          } else if (_calcDisplay.contains('×') || _calcDisplay.contains('*')) {
            final p = _calcDisplay.split(RegExp(r'[×*]'));
            _calcDisplay = (double.parse(p[0]) * double.parse(p[1])).toString();
          } else if (_calcDisplay.contains('÷') || _calcDisplay.contains('/')) {
            final p = _calcDisplay.split(RegExp(r'[÷/]'));
            _calcDisplay = (double.parse(p[0]) / double.parse(p[1])).toStringAsFixed(2);
          } else if (_calcDisplay.contains('-')) {
            final p = _calcDisplay.split('-');
            _calcDisplay = (double.parse(p[0]) - double.parse(p[1])).toString();
          }
        } catch (_) {
          _calcDisplay = 'Error';
        }
      } else {
        if (_calcDisplay == '0') {
          _calcDisplay = val;
        } else {
          _calcDisplay += val;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Zoom / Meet Style Floating Cast Controller Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.slate900, AppColors.slate950],
              ),
              border: Border(bottom: BorderSide(color: AppColors.rose500.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                // Pulsing Screen Cast Icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.rose600.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.rose500),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.rose500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'DEVICE SCREEN LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    widget.isTeacher
                        ? 'You are sharing your phone screen (Zoom/Meet Style)'
                        : 'Prof. Rajesh Sharma is sharing their device screen',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Stop Sharing Button
                if (widget.onStopSharing != null)
                  ElevatedButton.icon(
                    onPressed: widget.onStopSharing,
                    icon: const Icon(Icons.stop_rounded, size: 14),
                    label: const Text('Stop Share', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rose600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),

          // External App Quick Switcher Dock (Allows teacher to go anywhere & open anything!)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: AppColors.slate900,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _appSwitchButton('home', 'Device Home', Icons.home_rounded, AppColors.slate700),
                  const SizedBox(width: 6),
                  _appSwitchButton('youtube', 'YouTube Video', Icons.play_arrow_rounded, AppColors.rose600),
                  const SizedBox(width: 6),
                  _appSwitchButton('browser', 'Chrome Browser', Icons.language_rounded, AppColors.indigo600),
                  const SizedBox(width: 6),
                  _appSwitchButton('calculator', 'Scientific Calc', Icons.calculate_rounded, AppColors.amber600),
                  const SizedBox(width: 6),
                  _appSwitchButton('gallery', 'Photos & Diagrams', Icons.photo_library_rounded, AppColors.purple600),
                  const SizedBox(width: 6),
                  _appSwitchButton('files', 'Files & Storage', Icons.folder_rounded, AppColors.emerald600),
                  const SizedBox(width: 6),
                  _appSwitchButton('geogebra', 'GeoGebra 3D Math', Icons.architecture_rounded, AppColors.indigo700),
                ],
              ),
            ),
          ),

          // Mirrored Phone Screen Frame
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate800, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Simulated Android Status Bar (Camera notch, Clock, Battery, WiFi)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    color: AppColors.slate900,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('18:42', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Icon(Icons.cast_connected_rounded, size: 12, color: AppColors.rose400),
                            SizedBox(width: 6),
                            Icon(Icons.wifi, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Icon(Icons.signal_cellular_4_bar_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Icon(Icons.battery_full_rounded, size: 13, color: AppColors.emerald400),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Active App Screen Display
                  Expanded(
                    child: _buildCurrentAppScreen(),
                  ),

                  // Android Bottom Navigation Gesture Bar
                  Container(
                    height: 24,
                    color: AppColors.slate900,
                    alignment: Alignment.center,
                    child: Container(
                      width: 90,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
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

  Widget _appSwitchButton(String appId, String label, IconData icon, Color color) {
    final isSel = _activeDeviceApp == appId;
    return GestureDetector(
      onTap: () => setState(() => _activeDeviceApp = appId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? color : AppColors.slate800,
          borderRadius: BorderRadius.circular(10),
          border: isSel ? Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5) : Border.all(color: AppColors.slate700),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Active App Screen Router
  Widget _buildCurrentAppScreen() {
    switch (_activeDeviceApp) {
      case 'home':
        return _buildPhoneHomeScreen();
      case 'youtube':
        return _buildYouTubeScreen();
      case 'browser':
        return _buildChromeBrowserScreen();
      case 'calculator':
        return _buildCalculatorScreen();
      case 'gallery':
        return _buildGalleryScreen();
      case 'files':
        return _buildFilesScreen();
      case 'geogebra':
        return _buildGeoGebraScreen();
      default:
        return _buildPhoneHomeScreen();
    }
  }

  // 1. Phone Home Screen (Android Desktop with app launcher grid)
  Widget _buildPhoneHomeScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.indigo950, AppColors.slate900],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clock & Date Widget
          const Center(
            child: Column(
              children: [
                SizedBox(height: 10),
                Text(
                  '18:42',
                  style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w200),
                ),
                Text(
                  'Wednesday, September 23 • Live Class Active',
                  style: TextStyle(color: AppColors.indigo200, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Google Search bar widget on phone desktop
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text('Search apps or web on phone...', style: TextStyle(color: Colors.white60, fontSize: 11)),
                Spacer(),
                Icon(Icons.mic_none_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Device Apps (Tap any app to open and present to students):',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),

          // App Icon Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
              children: [
                _phoneAppIcon('YouTube', Icons.play_arrow_rounded, AppColors.rose600, () => setState(() => _activeDeviceApp = 'youtube')),
                _phoneAppIcon('Chrome', Icons.language_rounded, AppColors.indigo500, () => setState(() => _activeDeviceApp = 'browser')),
                _phoneAppIcon('Calculator', Icons.calculate_rounded, AppColors.amber600, () => setState(() => _activeDeviceApp = 'calculator')),
                _phoneAppIcon('Gallery', Icons.photo_library_rounded, AppColors.purple600, () => setState(() => _activeDeviceApp = 'gallery')),
                _phoneAppIcon('Files / PDF', Icons.folder_rounded, AppColors.emerald600, () => setState(() => _activeDeviceApp = 'files')),
                _phoneAppIcon('GeoGebra 3D', Icons.architecture_rounded, AppColors.indigo700, () => setState(() => _activeDeviceApp = 'geogebra')),
                _phoneAppIcon('Notes App', Icons.edit_note_rounded, AppColors.amber700, () => setState(() => _activeDeviceApp = 'browser')),
                _phoneAppIcon('Settings', Icons.settings_rounded, AppColors.slate600, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneAppIcon(String name, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 2. YouTube App Screen (Simulated External YouTube Video Presentation)
  Widget _buildYouTubeScreen() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // YouTube App Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: const Row(
              children: [
                Icon(Icons.play_circle_fill_rounded, color: AppColors.rose600, size: 24),
                SizedBox(width: 6),
                Text('YouTube', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                Spacer(),
                Icon(Icons.search, size: 20, color: AppColors.slate700),
              ],
            ),
          ),

          // Live Playing Video Frame
          Container(
            width: double.infinity,
            height: 180,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1518152006812-edab29b069ac?w=600&h=350&fit=crop',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(color: Colors.black.withValues(alpha: 0.3)),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
                Positioned(
                  bottom: 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      const Text('14:22 / 28:10', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(width: 80, height: 3, color: AppColors.rose600),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Video Description
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rotational Mechanics: Gyroscopic Precession & Torque Demonstration',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slate900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'MIT Physics OpenCourseWare • 1.2M views • 2 years ago',
                  style: TextStyle(fontSize: 10, color: AppColors.slate500),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ytAction(Icons.thumb_up_outlined, '48K'),
                    _ytAction(Icons.share_outlined, 'Share'),
                    _ytAction(Icons.download_outlined, 'Download'),
                    _ytAction(Icons.playlist_add, 'Save'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ytAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.slate700),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.slate700)),
      ],
    );
  }

  // 3. Chrome Browser Screen
  Widget _buildChromeBrowserScreen() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.slate100,
            child: Row(
              children: [
                const Icon(Icons.home_outlined, size: 18, color: AppColors.slate700),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.slate300),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(fontSize: 11, color: AppColors.slate800),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.refresh_rounded, size: 18, color: AppColors.slate700),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wikipedia: Rotational Dynamics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                  const SizedBox(height: 8),
                  const Text(
                    'Rotational dynamics is the study of forces and torques and their effect on rotational motion, as opposed to translational kinematics. The fundamental relation is Net Torque = Moment of Inertia × Angular Acceleration.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.slate700),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.indigo50, borderRadius: BorderRadius.circular(8)),
                    child: const Text('τ = I · α   and   L = I · ω', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.indigo900)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Scientific Calculator Screen
  Widget _buildCalculatorScreen() {
    return Container(
      color: AppColors.slate950,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Display
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_calcSub, style: const TextStyle(color: AppColors.slate400, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_calcDisplay, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w300)),
                ],
              ),
            ),
          ),

          // Keypad
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _calcRow(['sin', 'cos', 'tan', 'π']),
                _calcRow(['C', '(', ')', '÷']),
                _calcRow(['7', '8', '9', '×']),
                _calcRow(['4', '5', '6', '-']),
                _calcRow(['1', '2', '3', '+']),
                _calcRow(['0', '.', '^', '=']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcRow(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((k) {
          final isOp = ['÷', '×', '-', '+', '='].contains(k);
          final isClear = k == 'C';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ElevatedButton(
                onPressed: () => _onCalcPress(k),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOp ? AppColors.amber600 : (isClear ? AppColors.rose600 : AppColors.slate800),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(k, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 5. Gallery Screen (Photos & Physics Diagrams)
  Widget _buildGalleryScreen() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Device Gallery & Experiment Captures', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate900)),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _galleryThumb('https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400&h=300&fit=crop', 'Rotational Disc.jpg'),
                _galleryThumb('https://images.unsplash.com/photo-1509228468518-180dd4864904?w=400&h=300&fit=crop', 'Moment of Inertia.png'),
                _galleryThumb('https://images.unsplash.com/photo-1518152006812-edab29b069ac?w=400&h=300&fit=crop', 'Torque Experiment.jpg'),
                _galleryThumb('https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400&h=300&fit=crop', 'Angular Momentum.png'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _galleryThumb(String url, String name) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Image.network(url, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            color: Colors.black.withValues(alpha: 0.6),
            child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600), maxLines: 1),
          ),
        ],
      ),
    );
  }

  // 6. Files Screen
  Widget _buildFilesScreen() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Internal Storage / Documents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate900)),
          const SizedBox(height: 8),
          _fileRow('WebApple_Academic_Catalog_2026.pdf', '5.2 MB', Icons.picture_as_pdf, AppColors.rose600),
          _fileRow('Physics_Rotational_Motion_Lecture_Slides.pptx', '12.4 MB', Icons.slideshow, AppColors.amber600),
          _fileRow('JEE_Advanced_Previous_Years_Solutions.pdf', '8.9 MB', Icons.picture_as_pdf, AppColors.rose600),
          _fileRow('Lab_Oscillation_Experiment_Data.xlsx', '1.1 MB', Icons.table_chart, AppColors.emerald600),
        ],
      ),
    );
  }

  Widget _fileRow(String name, String size, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate900)),
                Text(size, style: const TextStyle(fontSize: 9, color: AppColors.slate500)),
              ],
            ),
          ),
          const Icon(Icons.more_vert, size: 16, color: AppColors.slate400),
        ],
      ),
    );
  }

  // 7. GeoGebra 3D Math Screen
  Widget _buildGeoGebraScreen() {
    return Container(
      color: AppColors.slate900,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.architecture_rounded, color: AppColors.indigo400, size: 18),
              SizedBox(width: 8),
              Text('GeoGebra 3D Graphing Calculator', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.indigo400, width: 2),
                      gradient: const RadialGradient(colors: [AppColors.indigo700, AppColors.indigo950]),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.threed_rotation_rounded, color: Colors.white, size: 64),
                  ),
                  const SizedBox(height: 14),
                  const Text('Vector Surface: z = sin(x) · cos(y)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Text('Normal Vector = (-cos(x)cos(y), sin(x)sin(y), 1)', style: TextStyle(color: AppColors.emerald400, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
