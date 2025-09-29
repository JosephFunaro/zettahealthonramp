import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
//import 'package:npt_flutter/features/authorisation/widgets/authorisation_app_bar_button.dart';
import 'package:npt_flutter/features/onboarding/util/pre_offboard.dart';
import 'package:npt_flutter/pages/loading_page.dart';
//import 'package:npt_flutter/features/settings/repository/contact_repository.dart';
import 'package:npt_flutter/home_wrapper_widget.dart';
import 'package:npt_flutter/pages/pages.dart';
import 'package:npt_flutter/pages/sub_nav_cubit.dart';
import 'package:npt_flutter/routes.dart';
import 'package:npt_flutter/styles/app_color.dart';
import 'package:package_info_plus/package_info_plus.dart';

class NptAppBar extends StatefulWidget implements PreferredSizeWidget {
  const NptAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<NptAppBar> createState() => _NptAppBarState();
}

class _NptAppBarState extends State<NptAppBar> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = 'v${packageInfo.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    //final atsign = ContactsService.getInstance().atClientManager.atClient.getCurrentAtSign();
    return BlocBuilder<SubNavCubit, String>(
      builder: (context, state) {
        final isDashboard = state == HomeRoutes.dashboard;
        return SizedBox(
          width: Sizes.p853,
          child: AppBar(
            titleSpacing: 0,
            leading: gap0,
            toolbarHeight: Sizes.p150,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                gapH40,
                Row(
                  children: [
                    gapW27,
                    SvgPicture.asset(
                      'assets/noports_logo.svg',
                      height: Sizes.p54,
                      width: Sizes.p175,
                    ),
                    gapW27,
                    Container(
                      color: AppColor.dividerColor,
                      height: Sizes.p38,
                      width: Sizes.p2,
                    ),
                    gapW27,
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) {
                        final offsetAnimation = child.key == ValueKey(state)
                            ? Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              ).animate(animation)
                            : Tween<Offset>(
                                begin: const Offset(0, -1),
                                end: Offset.zero,
                              ).animate(animation);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      // The layoutBuilder ensures the children are left aligned.
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: AlignmentDirectional.centerStart,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: Text(
                        routeName(state),
                        key: ValueKey(state),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                gapH16,
                if (isDashboard) gapH40,
                if (!isDashboard && wrapperNav.currentState!.canPop())
                  SizedBox(
                    height: Sizes.p40,
                    child: TextButton.icon(
                      onPressed: () {
                        wrapperNav.currentState!.pop(context);
                      },
                      label: Text(strings.back),
                      icon: const Icon(Icons.arrow_back_ios),
                      style: StyleConstants.backButtonStyle,
                    ),
                  ),
              ],
            ),
            actions: [
              /*IgnorePointer(
                ignoring: !isDashboard,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  opacity: isDashboard ? 1 : 0,
                  child: const AuthorisationAppBarButton(),
                ),
              ),*/
              IgnorePointer(
                ignoring: !isDashboard,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  opacity: isDashboard ? 1 : 0,
                  child: IconButton(
                    tooltip: 'Sign Out',
                    icon: const Icon(Icons.logout_outlined),
                    onPressed: () {
                      wrapperNav.currentState!.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoadingPage(),
                        ),
                        (route) => false,
                      );
                      preSignout();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamedAndRemoveUntil(
                          Routes.onboarding,
                          (route) => false,
                        );
                      }
                      ;
                    },
                  ),
                ),
              ),

              // User section on right
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColor.primaryColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset('assets/At.svg', width: 16, height: 16),
                      const SizedBox(width: 4),
                      Text(
                        atsign.isNotEmpty
                            ? atsign.replaceFirst('@', '')
                            : 'user',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavTab extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _underlineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _underlineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!widget.isActive) {
          setState(() => _isHovered = true);
          _animationController.forward();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive
                    ? AppColor.primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Stack(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive
                      ? Colors.black87
                      : _isHovered
                      ? Colors.black87
                      : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              if (!widget.isActive)
                Positioned(
                  bottom: -12,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _underlineAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 2,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColor.primaryColor.withValues(
                            alpha: _underlineAnimation.value,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
