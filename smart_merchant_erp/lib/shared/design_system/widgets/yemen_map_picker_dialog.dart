import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../tokens/colors.dart';

class YemenMapLocation {
  final double latitude;
  final double longitude;
  final String? cityName;

  const YemenMapLocation({
    required this.latitude,
    required this.longitude,
    this.cityName,
  });

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

class YemenCityPreset {
  final String name;
  final double latitude;
  final double longitude;
  final double defaultZoom;

  const YemenCityPreset(this.name, this.latitude, this.longitude, [this.defaultZoom = 14.0]);
}

const List<YemenCityPreset> kYemenCities = [
  YemenCityPreset('صنعاء (المركز والتحرير)', 15.3694, 44.1910),
  YemenCityPreset('صنعاء (حدة والسبعين)', 15.3280, 44.1950, 14.5),
  YemenCityPreset('صنعاء (الحصبة ومازدا)', 15.3900, 44.1980, 14.5),
  YemenCityPreset('عدن (المعلا وكريتر)', 12.7855, 45.0187),
  YemenCityPreset('عدن (المنصورة والشيخ عثمان)', 12.8620, 44.9920),
  YemenCityPreset('عدن (خور مكسر)', 12.8250, 45.0350),
  YemenCityPreset('تعز (شارع جمال)', 13.5789, 44.0177),
  YemenCityPreset('تعز (الحوبان)', 13.6200, 44.0750),
  YemenCityPreset('حضرموت (المكلا)', 14.5425, 49.1242),
  YemenCityPreset('حضرموت (سيئون)', 15.9320, 48.7900, 13.5),
  YemenCityPreset('الحديدة (الميناء وشارع صنعاء)', 14.7978, 42.9545),
  YemenCityPreset('إب (الظهار والدائري)', 13.9667, 44.1833),
  YemenCityPreset('ذمار (الجامعة والمركز)', 14.5427, 44.4051),
  YemenCityPreset('مأرب (المدينة والشارع العام)', 15.4542, 45.3242, 13.5),
  YemenCityPreset('شبوة (عتق)', 14.5360, 46.8320, 13.5),
  YemenCityPreset('صعدة (المدينة)', 16.9400, 43.7600, 13.5),
  YemenCityPreset('المهرة (الغيضة)', 16.2080, 52.1760, 13.5),
  YemenCityPreset('لحج (الحوطة)', 13.0580, 44.8820, 13.5),
  YemenCityPreset('أبين (زنجبار)', 13.1280, 45.3800, 13.5),
];

class YemenMapPickerDialog extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialCityName;

  const YemenMapPickerDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialCityName,
  });

  static Future<YemenMapLocation?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String? initialCityName,
  }) {
    return showDialog<YemenMapLocation>(
      context: context,
      builder: (ctx) => YemenMapPickerDialog(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        initialCityName: initialCityName,
      ),
    );
  }

  @override
  State<YemenMapPickerDialog> createState() => _YemenMapPickerDialogState();
}

class _YemenMapPickerDialogState extends State<YemenMapPickerDialog> {
  late double _currentLat;
  late double _currentLng;
  late int _zoom;

  // Slippy Map coordinates
  late double _centerTileX;
  late double _centerTileY;

  String? _nearestCityName;
  bool _isManualInputVisible = false;

  final TextEditingController _manualLatController = TextEditingController();
  final TextEditingController _manualLngController = TextEditingController();

  static const double _defaultYemenLat = 15.3694; // Sana'a default
  static const double _defaultYemenLng = 44.1910;
  static const int _defaultZoom = 14;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLatitude ?? _defaultYemenLat;
    _currentLng = widget.initialLongitude ?? _defaultYemenLng;
    _zoom = _defaultZoom;
    _syncTileFromLatLng();
    _updateNearestCity();
    _manualLatController.text = _currentLat.toStringAsFixed(6);
    _manualLngController.text = _currentLng.toStringAsFixed(6);
  }

  @override
  void dispose() {
    _manualLatController.dispose();
    _manualLngController.dispose();
    super.dispose();
  }

  double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2.0;

  void _syncTileFromLatLng() {
    final num n = math.pow(2.0, _zoom);
    _centerTileX = ((_currentLng + 180.0) / 360.0 * n);
    final double latRad = _currentLat * math.pi / 180.0;
    final double safeCos = math.cos(latRad).abs() < 1e-9 ? 1e-9 : math.cos(latRad);
    _centerTileY = ((1.0 - math.log(math.tan(latRad) + 1.0 / safeCos) / math.pi) / 2.0 * n);
  }

  void _syncLatLngFromTile() {
    final num n = math.pow(2.0, _zoom);
    _currentLng = _centerTileX / n * 360.0 - 180.0;
    final double latRad = math.atan(_sinh(math.pi * (1.0 - 2.0 * _centerTileY / n)));
    _currentLat = latRad * 180.0 / math.pi;

    // Bounds safety for Yemen & Global
    _currentLat = _currentLat.clamp(-85.0, 85.0);
    _currentLng = ((_currentLng + 180.0) % 360.0) - 180.0;

    _updateNearestCity();
    _manualLatController.text = _currentLat.toStringAsFixed(6);
    _manualLngController.text = _currentLng.toStringAsFixed(6);
  }

  void _updateNearestCity() {
    YemenCityPreset? closest;
    double minDistance = double.infinity;
    for (final city in kYemenCities) {
      final double dLat = city.latitude - _currentLat;
      final double dLng = city.longitude - _currentLng;
      final double dist = math.sqrt(dLat * dLat + dLng * dLng);
      if (dist < minDistance) {
        minDistance = dist;
        closest = city;
      }
    }
    // If within ~35 km, show city name
    if (closest != null && minDistance < 0.35) {
      _nearestCityName = closest.name.split('(').first.trim();
    } else {
      _nearestCityName = 'اليمن';
    }
  }

  void _jumpToCity(YemenCityPreset city) {
    setState(() {
      _currentLat = city.latitude;
      _currentLng = city.longitude;
      _zoom = city.defaultZoom.toInt();
      _syncTileFromLatLng();
      _updateNearestCity();
      _manualLatController.text = _currentLat.toStringAsFixed(6);
      _manualLngController.text = _currentLng.toStringAsFixed(6);
    });
  }

  void _applyManualCoordinates() {
    final lat = double.tryParse(_manualLatController.text.trim());
    final lng = double.tryParse(_manualLngController.text.trim());
    if (lat != null && lng != null) {
      setState(() {
        _currentLat = lat;
        _currentLng = lng;
        _syncTileFromLatLng();
        _updateNearestCity();
      });
    }
  }

  void _zoomIn() {
    if (_zoom < 18) {
      setState(() {
        _zoom += 1;
        _syncTileFromLatLng();
      });
    }
  }

  void _zoomOut() {
    if (_zoom > 6) {
      setState(() {
        _zoom -= 1;
        _syncTileFromLatLng();
      });
    }
  }

  Future<void> _openInExternalMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$_currentLat,$_currentLng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final dialogWidth = math.min(size.width * 0.92, 850.0);
    final dialogHeight = math.min(size.height * 0.88, 700.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // 1. Header Bar
              _buildHeader(isDark),

              // 2. City Quick Selector Strip
              _buildCitySelectorStrip(isDark),

              // 3. Interactive Map Viewport with Central Pin
              Expanded(
                child: Stack(
                  children: [
                    // Slippy Map Tiles Layer
                    _buildMapTilesLayer(isDark),

                    // Central Accurate Crosshair & Animated Pin
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 38),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Coordinates Pill above Pin
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.place_rounded,
                                    size: 13,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_currentLat.toStringAsFixed(5)}, ${_currentLng.toStringAsFixed(5)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),

                            // 3D Pin Icon
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 46,
                                  color: Color(0xFFEF4444),
                                ),
                                Positioned(
                                  top: 10,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Shadow beneath pin tip
                            Container(
                              width: 10,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Floating Controls (Zoom & Map Tools)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildFloatingControls(isDark),
                    ),

                    // Manual Coordinates Input Drawer (Toggleable)
                    if (_isManualInputVisible)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _buildManualCoordsBox(isDark),
                      ),

                    // Hint Badge Overlay at Bottom of Map
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black87 : Colors.white)
                              .withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'اسحب الخريطة لتحريك وتحديد الموقع بدقة',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Bottom Information & Confirmation Bar
              _buildBottomBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.map_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تحديد موقع المتجر على الخريطة (اليمن)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'خريطة مجانية ومباشرة معتمدة على OpenStreetMap لجميع المحافظات',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _isManualInputVisible = !_isManualInputVisible),
            icon: Icon(
              _isManualInputVisible ? Icons.keyboard_arrow_up_rounded : Icons.edit_location_alt_rounded,
              size: 16,
            ),
            label: Text(_isManualInputVisible ? 'إخفاء الإدخال' : 'إدخال يدوي'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'إغلاق',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelectorStrip(bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: kYemenCities.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final city = kYemenCities[index];
          final isSelected = _nearestCityName != null &&
              city.name.startsWith(_nearestCityName!);

          return InkWell(
            onTap: () => _jumpToCity(city),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
              ),
              child: Center(
                child: Text(
                  city.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapTilesLayer(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        final int n = 1 << _zoom;
        final int startTileX = (_centerTileX - (width / 2.0) / 256.0).floor();
        final int endTileX = (_centerTileX + (width / 2.0) / 256.0).ceil();
        final int startTileY = (_centerTileY - (height / 2.0) / 256.0).floor();
        final int endTileY = (_centerTileY + (height / 2.0) / 256.0).ceil();

        final List<Widget> tileWidgets = [];

        for (int tx = startTileX; tx <= endTileX; tx++) {
          for (int ty = startTileY; ty <= endTileY; ty++) {
            if (ty < 0 || ty >= n) {
              continue;
            }
            final int wrappedTx = ((tx % n) + n) % n;

            final double left = (width / 2.0) + (tx - _centerTileX) * 256.0;
            final double top = (height / 2.0) + (ty - _centerTileY) * 256.0;

            final tileUrl = 'https://tile.openstreetmap.org/$_zoom/$wrappedTx/$ty.png';

            tileWidgets.add(
              Positioned(
                left: left,
                top: top,
                width: 256,
                height: 256,
                child: Image.network(
                  tileUrl,
                  headers: const {'User-Agent': 'SmartMerchantERP/1.0 (Yemen)'},
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      child: Center(
                        child: Text(
                          'خريطة دون اتصال\n($wrappedTx, $ty)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        }

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _centerTileX -= details.delta.dx / 256.0;
              _centerTileY -= details.delta.dy / 256.0;
              _syncLatLngFromTile();
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(children: tileWidgets),
        );
      },
    );
  }

  Widget _buildFloatingControls(bool isDark) {
    return Column(
      children: [
        _buildCircleButton(
          icon: Icons.add_rounded,
          tooltip: 'تكبير (+)',
          onTap: _zoomIn,
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        _buildCircleButton(
          icon: Icons.remove_rounded,
          tooltip: 'تصغير (-)',
          onTap: _zoomOut,
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        _buildCircleButton(
          icon: Icons.my_location_rounded,
          tooltip: 'إعادة التوسيط لليمن',
          onTap: () => _jumpToCity(kYemenCities.first),
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        _buildCircleButton(
          icon: Icons.open_in_new_rounded,
          tooltip: 'فتح الموقع في خرائط Google',
          onTap: _openInExternalMaps,
          isDark: isDark,
          color: const Color(0xFF0EA5E9),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color ?? (isDark ? Colors.white : const Color(0xFF1E293B))),
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildManualCoordsBox(bool isDark) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'الإحداثيات يدوياً:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manualLatController,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'خط العرض (Lat)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _manualLngController,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'خط الطول (Lng)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _applyManualCoordinates,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: AppColors.primary,
            ),
            child: const Text('تطبيق على الخريطة'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;

          final locationInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_city_rounded,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _nearestCityName ?? 'اليمن',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'مستوى التقريب: $_zoom',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'خط العرض: ${_currentLat.toStringAsFixed(6)} | خط الطول: ${_currentLng.toStringAsFixed(6)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final actionButtons = Row(
            mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isNarrow)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
              const SizedBox(width: 10),
              if (isNarrow)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text(
                      'تأكيد الموقع',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _confirmSelection,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text(
                    'تأكيد واختيار هذا الموقع',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          );

          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                locationInfo,
                const SizedBox(height: 12),
                actionButtons,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: locationInfo),
              const SizedBox(width: 16),
              actionButtons,
            ],
          );
        },
      ),
    );
  }

  void _confirmSelection() {
    Navigator.of(context).pop(
      YemenMapLocation(
        latitude: _currentLat,
        longitude: _currentLng,
        cityName: _nearestCityName,
      ),
    );
  }
}
