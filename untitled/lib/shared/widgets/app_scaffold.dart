import 'package:flutter/material.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/shared/widgets/app_app_bar.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool? resizeToAvoidBottomInset;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.centerTitle = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.resizeToAvoidBottomInset,
    this.padding,
    this.backgroundColor,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.bottom,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? context.theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: (title != null || titleWidget != null)
          ? AppAppBar(
              title: title,
              titleWidget: titleWidget,
              actions: actions,
              showBackButton: showBackButton,
              onBackPressed: onBackPressed,
              centerTitle: centerTitle,
              showMenuButton: showMenuButton,
              onMenuPressed: onMenuPressed,
              bottom: bottom,
              leading: leading,
            )
          : null,
      body: padding != null
          ? Padding(
              padding: padding!,
              child: body,
            )
          : body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
}
