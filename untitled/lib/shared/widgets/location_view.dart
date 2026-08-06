import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';

class LocationView extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final Map<String, String> strings;

  const LocationView({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.strings,
  });

  bool get _hasCoords => latitude != null && longitude != null;

  void _openFullMap(BuildContext context) {
    if (!_hasCoords) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenMapView(
          latitude: latitude!,
          longitude: longitude!,
          locationName: locationName,
          strings: strings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCoords) return const SizedBox.shrink();

    final s = strings;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => _openFullMap(context),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(latitude!, longitude!),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('preview'),
                    position: LatLng(latitude!, longitude!),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                  ),
                },
                zoomGesturesEnabled: false,
                scrollGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              Positioned(
                left: AppSpacing.xs,
                bottom: AppSpacing.xs,
                right: 48,
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
                          locationName ?? (s['sitter_location'] ?? 'Sitter Location'),
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
              Positioned(
                right: AppSpacing.xs,
                top: AppSpacing.xs,
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
                      Icon(Icons.touch_app_rounded, size: 12, color: AppColors.primary),
                      SizedBox(width: AppSpacing.xxs),
                      Text(
                        s['tap'] ?? 'Tap',
                        style: AppTextStyles.caption(
                          color: AppColors.primary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _FullScreenMapView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? locationName;
  final Map<String, String> strings;

  const _FullScreenMapView({
    required this.latitude,
    required this.longitude,
    this.locationName,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final s = strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(locationName ?? (s['sitter_location'] ?? 'Sitter Location')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('sitter'),
            position: LatLng(latitude, longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
        onMapCreated: (controller) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 15),
          );
        },
      ),
    );
  }
}
