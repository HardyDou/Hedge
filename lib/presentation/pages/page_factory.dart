import 'package:flutter/cupertino.dart';
import 'package:hedge/core/platform/platform_utils.dart';

import 'mobile/detail_page.dart' as mobile;
import 'mobile/settings_page.dart' as mobile;
import 'shared/unlock_page.dart' as shared;
import 'shared/onboarding_page.dart' as shared;
import 'mobile/add_item_page.dart' as mobile;
import 'mobile/edit_page.dart' as mobile;

import 'desktop/desktop_home_page.dart' as desktop;
import 'desktop/detail_panel.dart' as desktop;
import 'desktop/settings_panel.dart' as desktop;

class PageFactory {
  static Widget getHomePage() {
    if (PlatformUtils.isDesktop) {
      return const desktop.DesktopHomePage();
    }
    // 移动端 HomePage 定义在 main.dart 中
    return const SizedBox.shrink();
  }

  static Widget getDetailPage(dynamic item) {
    if (PlatformUtils.isDesktop) {
      return desktop.DetailPanel(item: item);
    }
    return mobile.DetailPage(item: item);
  }

  static Widget getSettingsPage() {
    if (PlatformUtils.isDesktop) {
      return const desktop.SettingsPanel();
    }
    return const mobile.SettingsPage();
  }

  static Widget getUnlockPage() {
    return const shared.UnlockPage();
  }

  static Widget getOnboardingPage() {
    return const shared.OnboardingPage();
  }

  static Widget getAddItemPage() {
    return const mobile.AddItemPage();
  }

  static Widget getEditPage(dynamic item) {
    return mobile.EditPage(item: item);
  }
}
