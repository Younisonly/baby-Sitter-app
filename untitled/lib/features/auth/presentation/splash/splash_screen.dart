import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_constants.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/role_manager.dart';
import 'package:babysitter/core/storage/local_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.longAnimationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _navigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    final token = await LocalStorage.getAccessToken();
    final isOnboarded = await LocalStorage.getIsOnboarded();
    final hasToken = token != null && token.isNotEmpty;

    if (!mounted) return;

    if (hasToken) {
      final savedRole = await LocalStorage.getCurrentRole();
      if (!mounted) return;
      ref.read(roleManagerProvider.notifier).switchTo(savedRole);

      switch (savedRole) {
        case AppRole.sitter:
          context.go(AppRoutes.sitterDashboard);
        case AppRole.parent:
          context.go(AppRoutes.parentHome);
        case AppRole.visitor:
          context.go(AppRoutes.visitorHome);
      }
    } else if (!isOnboarded) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.visitorHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.child_care,
                          size: 64.sp,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        AppConstants.appName,
                        style: AppTextStyles.displaySmall(
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Find Trusted Care',
                        style: AppTextStyles.bodyLarge(
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
