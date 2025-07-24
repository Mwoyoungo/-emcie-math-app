import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'package:rive_animation/constants.dart';
import 'package:rive_animation/screens/home/home_screen.dart';
import 'package:rive_animation/screens/progress/progress_screen.dart';
import 'package:rive_animation/screens/auth/profile_screen.dart' as auth_profile;
import 'package:rive_animation/screens/teacher/teacher_classes_screen.dart';
import 'package:rive_animation/services/user_service.dart';
import 'package:rive_animation/utils/rive_utils.dart';
import 'package:rive_animation/utils/responsive_utils.dart';

import '../../model/menu.dart';
import 'components/btm_nav_item.dart';
import 'components/menu_btn.dart';
import 'components/side_bar.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint>
    with SingleTickerProviderStateMixin {
  bool isSideBarOpen = false;

  Menu? selectedBottonNav;
  Menu? selectedSideMenu;

  late SMIBool isMenuOpenInput;

  List<Menu> get currentNavItems {
    final userService = Provider.of<UserService>(context, listen: false);
    final isTeacher = userService.currentUser?.role == 'teacher';
    return isTeacher ? teacherNavItems : bottomNavItems;
  }

  List<Menu> get currentSidebarMenus {
    final userService = Provider.of<UserService>(context, listen: false);
    final isTeacher = userService.currentUser?.role == 'teacher';
    return isTeacher ? teacherSidebarMenus : sidebarMenus;
  }

  @override
  void initState() {
    super.initState();
    // Initialize after the widget is built to access Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNavigation();
    });
    _setupAnimations();
  }

  void _initializeNavigation() {
    final navItems = currentNavItems;
    if (navItems.isNotEmpty && selectedBottonNav == null) {
      setState(() {
        selectedBottonNav = navItems.first;
        selectedSideMenu = currentSidebarMenus.first;
      });
    }
  }

  void updateSelectedBtmNav(Menu menu) {
    if (selectedBottonNav != menu) {
      setState(() {
        selectedBottonNav = menu;
      });
    }
  }

  Widget _getCurrentScreen() {
    if (selectedBottonNav == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final userService = Provider.of<UserService>(context, listen: false);
    final isTeacher = userService.currentUser?.role == 'teacher';
    
    if (isTeacher) {
      switch (selectedBottonNav!.title) {
        case "Classes":
          return TeacherClassesScreen();
        case "Analytics":
          return const ProgressScreen(); // Show analytics as progress
        case "Profile":
          return const auth_profile.ProfileScreen();
        default:
          return const HomePage();
      }
    } else {
      switch (selectedBottonNav!.title) {
        case "Topics":
          return const HomePage();
        case "Performance":
          return const ProgressScreen();
        case "Profile":
          return const auth_profile.ProfileScreen();
        default:
          return const HomePage();
      }
    }
  }

  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

  void _setupAnimations() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(
        () {
          setState(() {});
        },
      );
    scalAnimation = Tween<double>(begin: 1, end: 0.8).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.fastOutSlowIn));
    animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.fastOutSlowIn));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isWeb = ResponsiveUtils.isWeb(context);
    final shouldShowPersistentSidebar = ResponsiveUtils.shouldShowPersistentSidebar(context);

    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else if (isWeb) {
      return _buildTabletLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor2,
      body: Row(
        children: [
          // Persistent sidebar for desktop
          Container(
            width: 280,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF17203A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(2, 0),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const SideBar(),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top navigation bar for desktop
                _buildDesktopTopBar(),
                // Main content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(0, 4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _getCurrentScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor2,
      body: Row(
        children: [
          // Collapsible sidebar for tablet
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSideBarOpen ? 280 : 0,
            child: isSideBarOpen
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF17203A),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(2, 0),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const SideBar(),
                  )
                : null,
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildTabletTopBar(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(0, 4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _getCurrentScreen(),
                    ),
                  ),
                ),
                // Bottom navigation for tablet
                _buildResponsiveBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor2,
      body: Stack(
        children: [
          AnimatedPositioned(
            width: 288,
            height: MediaQuery.of(context).size.height,
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            left: isSideBarOpen ? 0 : -288,
            top: 0,
            child: const SideBar(),
          ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(
                  1 * animation.value - 30 * (animation.value) * pi / 180),
            child: Transform.translate(
              offset: Offset(animation.value * 265, 0),
              child: Transform.scale(
                scale: scalAnimation.value,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(24),
                  ),
                  child: _getCurrentScreen(),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            left: isSideBarOpen ? 220 : 0,
            top: 16,
            child: MenuBtn(
              press: () {
                isMenuOpenInput.value = !isMenuOpenInput.value;

                if (_animationController.value == 0) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }

                setState(
                  () {
                    isSideBarOpen = !isSideBarOpen;
                  },
                );
              },
              riveOnInit: (artboard) {
                final controller = StateMachineController.fromArtboard(
                    artboard, "State Machine");

                artboard.addController(controller!);

                isMenuOpenInput =
                    controller.findInput<bool>("isOpen") as SMIBool;
                isMenuOpenInput.value = true;
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildResponsiveBottomNav(),
    );
  }

  Widget _buildDesktopTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // App title
          const Text(
            "Emcie - E=mc² Energy for Math",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7553F6),
              fontFamily: "Poppins",
            ),
          ),
          const Spacer(),
          // Desktop navigation tabs
          Consumer<UserService>(
            builder: (context, userService, child) {
              final navItems = currentNavItems;
              return Row(
                children: navItems.map((item) {
                  final isSelected = selectedBottonNav == item;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: InkWell(
                      onTap: () => updateSelectedBtmNav(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? const Color(0xFF7553F6).withValues(alpha: 0.1)
                            : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected 
                            ? Border.all(color: const Color(0xFF7553F6).withValues(alpha: 0.3))
                            : null,
                        ),
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF7553F6) : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabletTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu button for tablet
          IconButton(
            onPressed: () {
              setState(() {
                isSideBarOpen = !isSideBarOpen;
              });
            },
            icon: Icon(
              isSideBarOpen ? Icons.close : Icons.menu,
              color: const Color(0xFF7553F6),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Emcie",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7553F6),
              fontFamily: "Poppins",
            ),
          ),
          const Spacer(),
          // Current page indicator
          Text(
            selectedBottonNav?.title ?? '',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveBottomNav() {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    if (isDesktop) return const SizedBox.shrink(); // No bottom nav on desktop
    
    return Transform.translate(
      offset: Offset(0, ResponsiveUtils.isMobile(context) ? 100 * animation.value : 0),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 12),
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 24,
              tablet: 40,
              desktop: 60,
            ),
          ),
          decoration: BoxDecoration(
            color: backgroundColor2.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: backgroundColor2.withValues(alpha: 0.3),
                offset: const Offset(0, 20),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...List.generate(
                currentNavItems.length,
                (index) {
                  Menu navBar = currentNavItems[index];
                  return BtmNavItem(
                    navBar: navBar,
                    press: () {
                      RiveUtils.chnageSMIBoolState(navBar.rive.status!);
                      updateSelectedBtmNav(navBar);
                    },
                    riveOnInit: (artboard) {
                      navBar.rive.status = RiveUtils.getRiveInput(artboard,
                          stateMachineName: navBar.rive.stateMachineName);
                    },
                    selectedNav: selectedBottonNav ?? navBar,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
