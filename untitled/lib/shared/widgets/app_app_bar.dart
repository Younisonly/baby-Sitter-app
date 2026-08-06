import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? titleColor;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final PreferredSizeWidget? bottom;

  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.titleColor,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? context.theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: centerTitle,
      leading: leading ??
          (showMenuButton
              ? IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
                )
              : showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: onBackPressed ?? () => Navigator.maybePop(context),
                    )
                  : null),
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTextStyles.titleLarge(
                    color: titleColor ?? context.textPrimaryColor,
                  ),
                )
              : null),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom != null ? bottom!.preferredSize.height : 0),
      );
}
