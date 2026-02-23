import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/app_state.dart';
import '../../widgets/home/location_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/yandex_web_map_view.dart';
import '../../../domain/entities/location.dart';
import '../../../main.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _showMap = true;
  Uint8List? _pinBytes;
  YandexMapController? _mapController;
  YandexMapController? _fullscreenMapController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    _generatePinIcon();
  }

  Future<void> _generatePinIcon() async {
    const w = 64.0;
    const h = 88.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));
    const cx = w / 2;
    const r = w / 2;

    final path = Path()
      ..moveTo(cx, 0)
      ..cubicTo(cx - r * 0.55, 0, 0, r * 0.45, 0, r)
      ..cubicTo(0, r * 1.75, cx, h, cx, h)
      ..cubicTo(cx, h, w, r * 1.75, w, r)
      ..cubicTo(w, r * 0.45, cx + r * 0.55, 0, cx, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF0D9488));
    canvas.drawCircle(
        const Offset(cx, r), r * 0.44, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    _pinBytes = byteData!.buffer.asUint8List();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompactMobile = _isCompactMobile(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              AppColors.background,
              AppColors.background,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: isCompactMobile && _showMap
                ? _buildFullscreenMobileMapLayout()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Bar
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Филиалы',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            // Toggle buttons
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Row(
                                children: [
                                  _buildToggleButton(
                                    icon: Icons.map_rounded,
                                    isActive: _showMap,
                                    onTap: () =>
                                        setState(() => _showMap = true),
                                  ),
                                  _buildToggleButton(
                                    icon: Icons.list_rounded,
                                    isActive: !_showMap,
                                    onTap: () =>
                                        setState(() => _showMap = false),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: _showMap ? _buildMapView() : _buildListView(),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  bool _isCompactMobile(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < 900 || size.shortestSide < 600;
  }

  Future<void> _changeNativeZoom(
      YandexMapController? controller, double delta) async {
    if (controller == null) return;
    final position = await controller.getCameraPosition();
    final nextZoom = (position.zoom + delta).clamp(3.0, 19.0);
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(position.copyWith(zoom: nextZoom)),
      animation:
          const MapAnimation(type: MapAnimationType.smooth, duration: 0.2),
    );
  }

  Future<void> _moveToCurrentLocation(YandexMapController? controller) async {
    if (controller == null) return;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
          zoom: 15,
        ),
      ),
      animation:
          const MapAnimation(type: MapAnimationType.smooth, duration: 0.3),
    );
  }

  Widget _buildZoomControls({
    required VoidCallback onZoomIn,
    required VoidCallback onZoomOut,
    VoidCallback? onMyLocation,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onZoomIn,
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
            tooltip: 'Увеличить',
          ),
          const Divider(height: 1, color: AppColors.border),
          IconButton(
            onPressed: onZoomOut,
            icon:
                const Icon(Icons.remove_rounded, color: AppColors.textPrimary),
            tooltip: 'Уменьшить',
          ),
          if (onMyLocation != null) ...[
            const Divider(height: 1, color: AppColors.border),
            IconButton(
              onPressed: onMyLocation,
              icon: const Icon(
                Icons.my_location_rounded,
                color: AppColors.textPrimary,
              ),
              tooltip: 'Моя локация',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullscreenMobileMapLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, right: 16, left: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.92),
                borderRadius: BorderRadius.circular(25),
              ),
              child: _buildToggleButton(
                icon: Icons.list_rounded,
                isActive: false,
                onTap: () => setState(() => _showMap = false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildFullscreenMapOnlyView()),
      ],
    );
  }

  Widget _buildFullscreenMapOnlyView() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.locations.isEmpty || _pinBytes == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: LoadingIndicator(size: 36),
            ),
          );
        }

        final locationsWithCoords = state.locations
            .where((l) => l.latitude != null && l.longitude != null)
            .toList();

        if (locationsWithCoords.isEmpty) {
          return const Center(
            child: Text(
              'У филиалов нет координат',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final centerPoint = Point(
          latitude: locationsWithCoords.first.latitude!,
          longitude: locationsWithCoords.first.longitude!,
        );

        if (kIsWeb) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: YandexWebMapView(
              url: _buildYandexWidgetUrl(locationsWithCoords),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: YandexMap(
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                mapObjects: locationsWithCoords.map((location) {
                  return PlacemarkMapObject(
                    mapId: MapObjectId('location_fs_${location.id}'),
                    point: Point(
                      latitude: location.latitude!,
                      longitude: location.longitude!,
                    ),
                    icon: PlacemarkIcon.single(
                      PlacemarkIconStyle(
                        image: BitmapDescriptor.fromBytes(_pinBytes!),
                        scale: 0.8,
                      ),
                    ),
                    opacity: 0.95,
                    onTap: (_, __) => _showLocationDetails(location),
                  );
                }).toList(),
                onMapCreated: (controller) {
                  _fullscreenMapController = controller;
                  controller.moveCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: centerPoint, zoom: 12),
                    ),
                  );
                  if (locationsWithCoords.length > 1) {
                    final points = locationsWithCoords
                        .map((l) => Point(
                            latitude: l.latitude!, longitude: l.longitude!))
                        .toList();
                    _fitBounds(controller, points);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _buildZoomControls(
                onZoomIn: () => _changeNativeZoom(_fullscreenMapController, 1),
                onZoomOut: () =>
                    _changeNativeZoom(_fullscreenMapController, -1),
                onMyLocation: () =>
                    _moveToCurrentLocation(_fullscreenMapController),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().loadInitialData(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildLocationsList(),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.locations.isEmpty || _pinBytes == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: LoadingIndicator(size: 36),
            ),
          );
        }

        final locationsWithCoords = state.locations
            .where((l) => l.latitude != null && l.longitude != null)
            .toList();

        final centerPoint = locationsWithCoords.isNotEmpty
            ? Point(
                latitude: locationsWithCoords.first.latitude!,
                longitude: locationsWithCoords.first.longitude!,
              )
            : const Point(latitude: 55.7558, longitude: 37.6176);

        if (kIsWeb) {
          return _buildWebMapFallback(locationsWithCoords);
        }

        return Column(
          children: [
            Expanded(
              child: YandexMap(
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                mapObjects: locationsWithCoords.map((location) {
                  return PlacemarkMapObject(
                    mapId: MapObjectId('location_${location.id}'),
                    point: Point(
                      latitude: location.latitude!,
                      longitude: location.longitude!,
                    ),
                    icon: PlacemarkIcon.single(
                      PlacemarkIconStyle(
                        image: BitmapDescriptor.fromBytes(_pinBytes!),
                        scale: 0.7,
                      ),
                    ),
                    opacity: 0.95,
                    onTap: (_, __) => _showLocationDetails(location),
                  );
                }).toList(),
                onMapCreated: (controller) {
                  _mapController = controller;
                  controller.moveCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: centerPoint, zoom: 12),
                    ),
                  );

                  // Вписываем все точки
                  if (locationsWithCoords.length > 1) {
                    final points = locationsWithCoords
                        .map((l) => Point(
                            latitude: l.latitude!, longitude: l.longitude!))
                        .toList();
                    _fitBounds(controller, points);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _buildZoomControls(
                onZoomIn: () => _changeNativeZoom(_mapController, 1),
                onZoomOut: () => _changeNativeZoom(_mapController, -1),
                onMyLocation: () => _moveToCurrentLocation(_mapController),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebMapFallback(List<Location> locationsWithCoords) {
    if (locationsWithCoords.isEmpty) {
      return const Center(
        child: Text(
          'У филиалов нет координат',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 230,
            width: double.infinity,
            child: YandexWebMapView(
              url: _buildYandexWidgetUrl(locationsWithCoords),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: locationsWithCoords.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final location = locationsWithCoords[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  location.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  location.address,
                  style: const TextStyle(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _showLocationDetails(location),
                trailing: IconButton(
                  tooltip: 'Открыть в Яндекс Картах',
                  icon: const Icon(Icons.open_in_new_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => _openLocationInYandex(location),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _buildYandexWidgetUrl(List<Location> locations, {int? zoom}) {
    final avgLat =
        locations.fold<double>(0, (sum, item) => sum + (item.latitude ?? 0)) /
            locations.length;
    final avgLng =
        locations.fold<double>(0, (sum, item) => sum + (item.longitude ?? 0)) /
            locations.length;
    final markers = locations
        .take(30)
        .map((location) =>
            '${location.longitude!.toStringAsFixed(6)},${location.latitude!.toStringAsFixed(6)},pm2gnm')
        .join('~');

    final params = <String, String>{
      'lang': 'ru_RU',
      'l': 'map',
      'll': '${avgLng.toStringAsFixed(6)},${avgLat.toStringAsFixed(6)}',
      'z': '${zoom ?? (locations.length > 1 ? 10 : 14)}',
    };
    if (markers.isNotEmpty) {
      params['pt'] = markers;
    }

    return Uri.https('yandex.ru', '/map-widget/v1/', params).toString();
  }

  Future<void> _openLocationInYandex(Location location) async {
    if (location.latitude == null || location.longitude == null) return;
    final url = Uri.parse(
        'https://yandex.ru/maps/?ll=${location.longitude},${location.latitude}&pt=${location.longitude},${location.latitude}&z=16&l=map');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _fitBounds(YandexMapController controller, List<Point> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final padLat = (maxLat - minLat) * 0.15;
    final padLng = (maxLng - minLng) * 0.15;

    controller.moveCamera(
      CameraUpdate.newGeometry(
        Geometry.fromBoundingBox(BoundingBox(
          southWest:
              Point(latitude: minLat - padLat, longitude: minLng - padLng),
          northEast:
              Point(latitude: maxLat + padLat, longitude: maxLng + padLng),
        )),
      ),
      animation:
          const MapAnimation(type: MapAnimationType.smooth, duration: 0.5),
    );
  }

  void _showLocationDetails(Location location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.address,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (location.phone != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.phone_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    location.phone!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (location.workingHours != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    location.workingHours!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Переключаемся на таб «Записаться» (index 1)
                  MainScreen.switchTab(this.context, 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Записаться',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.locations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: LoadingIndicator(size: 36),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ...state.locations
                .map((location) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: LocationCard(location: location),
                    ))
                .toList(),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}
