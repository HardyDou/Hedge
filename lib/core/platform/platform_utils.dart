import 'dart:io';

enum AppPlatform { mobile, desktop, web }

class PlatformUtils {
  static AppPlatform get platform {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return AppPlatform.desktop;
    }
    return AppPlatform.mobile;
  }

  static bool get isDesktop => platform == AppPlatform.desktop;
  static bool get isMobile => platform == AppPlatform.mobile;

  static bool get isMacOS => Platform.isMacOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
}
