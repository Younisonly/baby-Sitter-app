import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/routing/app_router_guard.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/storage/local_storage.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await LocalStorage.setIsOnboarded(true);
    AppRouterGuard.markOnboarded();
    if (mounted) {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _GradientHeader(
              currentPage: _currentPage,
              isDark: isDark,
              floatAnim: _floatAnim,
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                  ),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.85),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      textStyle: AppTextStyles.labelLarge(
                        weight: FontWeight.w600,
                      ),
                    ),
                    child: Text(strings[AppLocalization.skip] ?? 'Skip'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: 3,
                itemBuilder: (_, i) => _OnboardingPageContent(index: i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      dotWidth: 8.w,
                      dotHeight: 8.h,
                      spacing: 8,
                      activeDotColor: AppColors.primary,
                      dotColor: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.12),
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    width: double.infinity,
                    text: _currentPage == 2
                        ? (strings[AppLocalization.get_started] ??
                            'Get Started')
                        : (strings[AppLocalization.next] ?? 'Next'),
                    onPressed: () {
                      if (_currentPage == 2) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  final int currentPage;
  final bool isDark;
  final Animation<double> floatAnim;
  final Widget child;

  const _GradientHeader({
    required this.currentPage,
    required this.isDark,
    required this.floatAnim,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      [AppColors.gradientStart, AppColors.gradientMid],
      [AppColors.primary, const Color(0xFF1F7A78)],
      [AppColors.gradientMid, AppColors.gradientEnd],
    ][currentPage];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _DecorativeCircle(
              size: 180,
              color: Colors.white.withValues(alpha: 0.07),
              floatAnim: floatAnim,
              delay: 0,
            ),
          ),
          Positioned(
            bottom: -30,
            left: -50,
            child: _DecorativeCircle(
              size: 140,
              color: Colors.white.withValues(alpha: 0.05),
              floatAnim: floatAnim,
              delay: 0.5,
            ),
          ),
          Positioned(
            top: 80,
            left: -20,
            child: _DecorativeCircle(
              size: 80,
              color: Colors.white.withValues(alpha: 0.06),
              floatAnim: floatAnim,
              delay: 1,
            ),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: _DecorativeCircle(
              size: 60,
              color: Colors.white.withValues(alpha: 0.08),
              floatAnim: floatAnim,
              delay: 1.5,
            ),
          ),
          Align(
            child: AnimatedBuilder(
              animation: floatAnim,
              builder: (context, _) => Transform.translate(
                offset: Offset(0, floatAnim.value),
                child: _PageIcon(currentPage: currentPage),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;
  final Animation<double> floatAnim;
  final double delay;

  const _DecorativeCircle({
    required this.size,
    required this.color,
    required this.floatAnim,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatAnim,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, floatAnim.value * (1 + delay * 0.3)),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class _PageIcon extends StatelessWidget {
  final int currentPage;

  const _PageIcon({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.search_rounded,
      Icons.calendar_month_rounded,
      Icons.verified_user_rounded,
    ];

    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        icons[currentPage],
        size: 56.sp,
        color: Colors.white,
      ),
    );
  }
}

class _OnboardingPageContent extends ConsumerWidget {
  final int index;
  const _OnboardingPageContent({required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    final content = [
      {
        'title': strings[AppLocalization.onboarding_1_title] ??
            'Find Trusted Babysitters',
        'desc': strings[AppLocalization.onboarding_1_desc] ??
            'Browse verified babysitters in your area with confidence',
      },
      {
        'title': strings[AppLocalization.onboarding_2_title] ?? 'Easy Booking',
        'desc': strings[AppLocalization.onboarding_2_desc] ??
            'Book your favorite sitter instantly with flexible scheduling',
      },
      {
        'title': strings[AppLocalization.onboarding_3_title] ??
            'Peace of Mind',
        'desc': strings[AppLocalization.onboarding_3_desc] ??
            'Track sessions, communicate safely, and pay securely',
      },
    ][index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            content['title'] as String,
            style: AppTextStyles.displaySmall(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content['desc'] as String,
            style: AppTextStyles.bodyLarge(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(
            begin: 0.1,
            end: 0,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
