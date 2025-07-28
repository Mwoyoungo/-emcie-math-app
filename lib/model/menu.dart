import 'rive_model.dart';

class Menu {
  final String title;
  final RiveModel rive;

  Menu({required this.title, required this.rive});
}

List<Menu> sidebarMenus = [
  Menu(
    title: "Home",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "HOME",
        stateMachineName: "HOME_interactivity"),
  ),
  Menu(
    title: "Search",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "SEARCH",
        stateMachineName: "SEARCH_Interactivity"),
  ),
  Menu(
    title: "Favorites",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "LIKE/STAR",
        stateMachineName: "STAR_Interactivity"),
  ),
  Menu(
    title: "Help",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "CHAT",
        stateMachineName: "CHAT_Interactivity"),
  ),
];
List<Menu> sidebarMenus2 = [
  Menu(
    title: "History",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "TIMER",
        stateMachineName: "TIMER_Interactivity"),
  ),
  Menu(
    title: "Test Classes",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "SEARCH",
        stateMachineName: "SEARCH_Interactivity"),
  ),
  Menu(
    title: "Image Test",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "CHAT",
        stateMachineName: "CHAT_Interactivity"),
  ),
  Menu(
    title: "Notifications",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "BELL",
        stateMachineName: "BELL_Interactivity"),
  ),
];

// Student Navigation Items
List<Menu> bottomNavItems = [
  Menu(
    title: "Home",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "HOME",
        stateMachineName: "HOME_interactivity"),
  ),
  Menu(
    title: "Classes",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "SEARCH",
        stateMachineName: "SEARCH_Interactivity"),
  ),
  Menu(
    title: "Performance",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "LIKE/STAR",
        stateMachineName: "STAR_Interactivity"),
  ),
];

// Teacher Navigation Items - Simplified
List<Menu> teacherNavItems = [
  Menu(
    title: "Classes",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "SEARCH",
        stateMachineName: "SEARCH_Interactivity"),
  ),
  Menu(
    title: "Shared Chats",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "CHAT",
        stateMachineName: "CHAT_Interactivity"),
  ),
  Menu(
    title: "Profile",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "USER",
        stateMachineName: "USER_Interactivity"),
  ),
];

// Teacher Sidebar Menu Items - Simplified for student signup only
List<Menu> teacherSidebarMenus = [
  Menu(
    title: "Add Students",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "USER",
        stateMachineName: "USER_Interactivity"),
  ),
  Menu(
    title: "Student Requests",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "LIKE/STAR",
        stateMachineName: "STAR_Interactivity"),
  ),
];

List<Menu> teacherSidebarMenus2 = [
  Menu(
    title: "Settings",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "BELL",
        stateMachineName: "BELL_Interactivity"),
  ),
];
