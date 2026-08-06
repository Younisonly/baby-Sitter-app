import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';

class LocationPickerData {
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const LocationPickerData({
    this.latitude,
    this.longitude,
    this.locationName,
  });

  bool get isSet => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'location': locationName ?? '',
      };
}

class LocationPicker extends StatefulWidget {
  final LocationPickerData? initial;
  final ValueChanged<LocationPickerData> onChanged;
  final Map<String, String> strings;

  const LocationPicker({
    super.key,
    this.initial,
    required this.onChanged,
    required this.strings,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LocationPickerData? _data;

  @override
  void initState() {
    super.initState();
    _data = widget.initial;
  }

  Future<void> _openPicker() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _FullScreenMapPicker(
          initialLatitude: _data?.latitude,
          initialLongitude: _data?.longitude,
          strings: widget.strings,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      final newData = LocationPickerData(
        latitude: result['latitude'] as double?,
        longitude: result['longitude'] as double?,
        locationName: result['location'] as String?,
      );
      setState(() => _data = newData);
      widget.onChanged(newData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final isDark = context.isDark;
    final isSet = _data?.isSet == true;

    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSet ? context.cardColor : context.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSet
                ? AppColors.success.withValues(alpha: 0.4)
                : (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.4),
            width: isSet ? 1.5 : 1,
          ),
          boxShadow: isSet ? AppShadows.card : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (isSet)
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_data!.latitude!, _data!.longitude!),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('preview'),
                    position: LatLng(_data!.latitude!, _data!.longitude!),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                  ),
                },
                zoomGesturesEnabled: false,
                scrollGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.map_outlined,
                        size: 28,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      s['set_location'] ?? 'Set Location',
                      style: AppTextStyles.bodySmall(
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              right: AppSpacing.xs,
              top: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: isSet ? AppColors.success.withValues(alpha: 0.9) : AppColors.error.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: AppShadows.subtle,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSet ? Icons.check_circle_rounded : Icons.location_off_rounded,
                      size: 14,
                      color: AppColors.white,
                    ),
                    SizedBox(width: AppSpacing.xxs),
                    Text(
                      isSet
                          ? (s['location_selected'] ?? 'Selected')
                          : (s['location_not_set'] ?? 'Not Set'),
                      style: AppTextStyles.caption(
                        color: AppColors.white,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSet && _data!.locationName != null && _data!.locationName!.isNotEmpty)
              Positioned(
                left: AppSpacing.xs,
                bottom: AppSpacing.xs,
                right: 50,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardColor.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: AppShadows.subtle,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(
                          _data!.locationName!,
                          style: AppTextStyles.caption(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            weight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              right: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: context.cardColor.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.subtle,
                ),
                child: Icon(
                  Icons.open_in_full_rounded,
                  size: 16,
                  color: (isDark ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Map<String, String> strings;

  const _FullScreenMapPicker({
    this.initialLatitude,
    this.initialLongitude,
    required this.strings,
  });

  @override
  State<_FullScreenMapPicker> createState() => _FullScreenMapPickerState();
}

class _FullScreenMapPickerState extends State<_FullScreenMapPicker> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  late AnimationController _pinAnimController;
  late Animation<double> _pinScale;
  LatLng _center = const LatLng(24.7136, 46.6753);
  bool _isLoadingLocation = false;
  bool _permissionDenied = false;
  bool _isPinDropped = false;

  @override
  void initState() {
    super.initState();
    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pinScale = CurvedAnimation(parent: _pinAnimController, curve: Curves.elasticOut);
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _isPinDropped = true;
    } else {
      _goToMyLocation();
    }
  }

  @override
  void dispose() {
    _pinAnimController.dispose();
    super.dispose();
  }

  void _dropPin() {
    _pinAnimController.forward(from: 0);
    _isPinDropped = true;
  }

  Future<void> _goToMyLocation() async {
    final s = widget.strings;
    setState(() => _isLoadingLocation = true);

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final granted = await Geolocator.requestPermission();
      if (granted == LocationPermission.denied || granted == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _permissionDenied = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s['location_permission_denied'] ?? 'Location permission is needed to show your position.')),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (mounted) {
        final pos = LatLng(position.latitude, position.longitude);
        setState(() => _center = pos);
        final controller = await _mapController.future;
        await controller.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
        _dropPin();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s['location_error'] ?? 'Could not get location. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onCameraIdle() {
    _dropPin();
  }

  void _onTap(LatLng pos) {
    setState(() => _center = pos);
    final controller = _mapController.future;
    controller.then((c) => c.animateCamera(CameraUpdate.newLatLng(pos)));
  }

  void _confirm() {
    Navigator.of(context).pop({
      'latitude': _center.latitude,
      'longitude': _center.longitude,
    });
  }

  Future<void> _retryPermission() async {
    final granted = await Geolocator.requestPermission();
    if (granted == LocationPermission.whileInUse || granted == LocationPermission.always) {
      setState(() => _permissionDenied = false);
      _goToMyLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(s['select_location'] ?? 'Select Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            onCameraIdle: _onCameraIdle,
            onTap: _onTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: 0,
                        child: CustomPaint(
                          size: const Size(4, 72),
                          painter: _PinLinePainter(color: AppColors.primary),
                        ),
                      ),
                      ScaleTransition(
                        scale: _pinScale,
                        child: Transform.translate(
                          offset: const Offset(0, -36),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                if (!_isPinDropped)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.cardDark : AppColors.cardLight).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      s['move_map_to_set'] ?? 'Move the map to set location',
                      style: AppTextStyles.caption(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: _goToMyLocation,
              backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              child: _isLoadingLocation
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(Icons.my_location_rounded, color: AppColors.primary),
            ),
          ),
          if (_permissionDenied)
            Positioned.fill(
              child: Container(
                color: (isDark ? AppColors.cardDark : AppColors.cardLight).withValues(alpha: 0.95),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off_rounded, size: 64,
                          color: AppColors.error.withValues(alpha: 0.7)),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          s['location_required_title'] ?? 'Location Access Required',
                          style: AppTextStyles.titleMedium(weight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          s['location_required_desc'] ?? 'Please enable location access to select your position on the map.',
                          style: AppTextStyles.bodyMedium(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppSpacing.xl),
                        FilledButton.icon(
                          onPressed: _retryPermission,
                          icon: const Icon(Icons.location_on_rounded),
                          label: Text(s['location_permission_btn'] ?? 'Enable Location'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(s['confirm_location'] ?? 'Confirm Location'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinLinePainter extends CustomPainter {
  final Color color;
  _PinLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PinLinePainter old) => old.color != color;
}
