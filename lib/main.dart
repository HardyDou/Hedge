import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hedge/features/tray_panel/tray_panel.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:hedge/core/platform/platform_utils.dart';
import 'package:hedge/presentation/providers/locale_provider.dart';
import 'package:hedge/presentation/providers/theme_provider.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';

import 'package:hedge/src/dart/vault.dart';
import 'package:hedge/presentation/pages/mobile/detail_page.dart';
import 'package:hedge/presentation/pages/mobile/settings_page.dart';
import 'package:hedge/presentation/pages/shared/unlock_page.dart';
import 'package:hedge/presentation/pages/shared/onboarding_page.dart';
import 'package:hedge/presentation/pages/shared/splash_page.dart';
import 'package:hedge/presentation/pages/mobile/add_item_page.dart';
import 'package:hedge/presentation/pages/desktop/desktop_home_page.dart';
import 'package:hedge/presentation/pages/desktop/settings_panel.dart';
import 'package:hedge/presentation/widgets/alphabet_index_bar.dart';

class SlideFromLeftRoute<T> extends PageRouteBuilder<T> {
  SlideFromLeftRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 桌面平台：初始化窗口管理器和托盘
  if (PlatformUtils.isDesktop) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: CupertinoColors.systemBackground,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    runApp(const ProviderScope(child: TrayEnabledApp()));
  } else {
    // 移动平台：直接运行应用
    runApp(const ProviderScope(child: NotePasswordApp()));
  }
}

class NotePasswordApp extends ConsumerWidget {
  const NotePasswordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final vaultState = ref.watch(vaultProvider);

    return CupertinoApp(
      title: 'NotePassword',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: themeMode == ThemeModeOption.dark 
            ? Brightness.dark 
            : (themeMode == ThemeModeOption.light ? Brightness.light : null),
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: themeMode == ThemeModeOption.dark 
            ? CupertinoColors.black 
            : CupertinoColors.systemGroupedBackground,
      ),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      builder: (context, child) {
        // We start disabled to avoid showing lock screen during loading
        // AuthGuard will handle enabling it when ready
        return AppLock(
          initiallyEnabled: false,
          initialBackgroundLockLatency: Duration(seconds: vaultState.autoLockTimeout),
          builder: (context, arg) => child ?? const AuthGuard(),
          lockScreenBuilder: (lockContext) {
            // Disable menu when AppLock is showing
            if (PlatformUtils.isDesktop) {
              const MethodChannel('app.menu').invokeMethod('setMenuEnabled', false).catchError((e) {
                // Ignore error during hot reload
                debugPrint('[Menu] Failed to disable menu: $e');
              });
            }

            return Builder(
              builder: (builderContext) => UnlockPage(
                isLockOverlay: true,
                onUnlocked: () {
                  AppLock.of(builderContext)!.didUnlock();
                  // Re-enable menu when unlocked
                  if (PlatformUtils.isDesktop) {
                    const MethodChannel('app.menu').invokeMethod('setMenuEnabled', true).catchError((e) {
                      // Ignore error during hot reload
                      debugPrint('[Menu] Failed to enable menu: $e');
                    });
                  }
                },
              ),
            );
          },
        );
      },
      home: const AuthGuard(),
    );
  }
}

/// 带托盘功能的应用包装器（桌面版）
class TrayEnabledApp extends StatefulWidget {
  const TrayEnabledApp({super.key});

  @override
  State<TrayEnabledApp> createState() => _TrayEnabledAppState();
}

class _TrayEnabledAppState extends State<TrayEnabledApp> with WindowListener {
  late PanelWindowService _panelWindowService;
  late TrayService _trayService;
  bool _isInitialized = false;
  bool _hasRefreshedData = false;

  @override
  void initState() {
    super.initState();
    _initializeTray();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _trayService.dispose();
    super.dispose();
  }

  Future<void> _initializeTray() async {
    try {
      _panelWindowService = PanelWindowService();
      _trayService = TrayService(panelWindowService: _panelWindowService);
      await _trayService.initialize();
      await windowManager.setPreventClose(true);

      setState(() {
        _isInitialized = true;
      });

      debugPrint('托盘功能初始化完成');
    } catch (e) {
      debugPrint('托盘功能初始化失败: $e');
    }
  }

  @override
  void onWindowClose() async {
    debugPrint('窗口关闭事件');
    await _panelWindowService.onWindowClose();
  }

  @override
  void onWindowBlur() async {
    await _panelWindowService.onPanelBlur();
  }

  @override
  void onWindowEvent(String eventName) {
    debugPrint('窗口事件: $eventName');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const CupertinoApp(
        debugShowCheckedModeBanner: false,
        home: CupertinoPageScaffold(
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _panelWindowService,
      builder: (context, child) {
        final isPanelMode = _panelWindowService.state.isPanelMode;

        // 从 Panel 切换回主窗口时刷新数据
        if (!isPanelMode && !_hasRefreshedData) {
          _hasRefreshedData = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint('🔄 从 Panel 切换回主窗口，触发数据刷新');
            final container = ProviderScope.containerOf(context, listen: false);
            container.read(vaultProvider.notifier).searchItems('');
            debugPrint('✅ 数据刷新已触发');
          });
        } else if (isPanelMode) {
          _hasRefreshedData = false;
        }

        if (isPanelMode) {
          // Panel 模式：显示快捷面板
          return Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeProvider);
              final locale = ref.watch(localeProvider);

              return CupertinoApp(
                debugShowCheckedModeBanner: false,
                theme: CupertinoThemeData(
                  brightness: themeMode == ThemeModeOption.dark
                      ? Brightness.dark
                      : (themeMode == ThemeModeOption.light ? Brightness.light : null),
                  primaryColor: CupertinoColors.activeBlue,
                  scaffoldBackgroundColor: themeMode == ThemeModeOption.dark
                      ? CupertinoColors.black
                      : CupertinoColors.systemGroupedBackground,
                ),
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('zh'),
                ],
                home: CupertinoPageScaffold(
                  child: TrayPanel(
                    panelWindowService: _panelWindowService,
                    trayService: _trayService,
                  ),
                ),
              );
            },
          );
        } else {
          // 主窗口模式：显示主应用
          return const NotePasswordApp();
        }
      },
    );
  }
}

class AuthGuard extends ConsumerStatefulWidget {
  const AuthGuard({super.key});

  @override
  ConsumerState<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends ConsumerState<AuthGuard> with WidgetsBindingObserver {
  static const _menuChannel = MethodChannel('app.menu');
  bool _isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(vaultProvider.notifier).checkInitialStatus());

    // Setup menu channel for desktop
    if (PlatformUtils.isDesktop) {
      _setupMenuChannel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isAppInBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      // When app comes back, wait a bit to see if AppLock will show
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() => _isAppInBackground = false);
        }
      });
    }
  }

  void _setupMenuChannel() {
    _menuChannel.setMethodCallHandler((call) async {
      if (call.method == 'openSettings' || call.method == 'showSettings') {
        _handleOpenSettings();
      }
    });
  }

  void _handleOpenSettings() {
    final vaultState = ref.read(vaultProvider);

    // If not authenticated, show a message
    if (!vaultState.isAuthenticated) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('需要解锁'),
          content: const Text('请先解锁密码库才能访问设置'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    // If authenticated, show settings dialog
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Center(
        child: Container(
          width: 450,
          height: 380,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SettingsPanel(
            isModal: true,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);

    // Listen for state changes to enable/disable AppLock and menu
    ref.listen<VaultState>(vaultProvider, (previous, next) {
      if (next.hasVaultFile && !next.isLoading) {
        // AppLock won't auto-update if initially disabled, so we force enable it
        if (previous == null || !previous.hasVaultFile || previous.isLoading) {
          AppLock.of(context)?.setEnabled(true);
        }

        // Update timeout if changed
        if (previous?.autoLockTimeout != next.autoLockTimeout) {
          AppLock.of(context)?.setBackgroundLockLatency(Duration(seconds: next.autoLockTimeout));
        }

        // Enable menu when authenticated
        if (next.isAuthenticated && PlatformUtils.isDesktop) {
          _menuChannel.invokeMethod('setMenuEnabled', true).catchError((e) {
            // Ignore error during hot reload
            debugPrint('[Menu] Failed to enable menu: $e');
          });
        }
      } else if (!next.hasVaultFile) {
        AppLock.of(context)?.setEnabled(false);
        // Clear navigation stack when vault is reset to show OnboardingPage
        if (previous != null && previous.hasVaultFile) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }

      // Disable menu when not authenticated
      if (!next.isAuthenticated && PlatformUtils.isDesktop) {
        _menuChannel.invokeMethod('setMenuEnabled', false).catchError((e) {
          // Ignore error during hot reload
          debugPrint('[Menu] Failed to disable menu: $e');
        });
      }
    });

    // 显示启动页面（加载中）
    if (vaultState.isLoading && vaultState.vault == null) {
      return const SplashPage();
    }

    if (!vaultState.hasVaultFile) {
      return const OnboardingPage();
    }

    if (!vaultState.isAuthenticated) {
      return const UnlockPage();
    }

    return PlatformUtils.isDesktop
        ? const DesktopHomePage()
        : const HomePage();
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 初始化时清空搜索，确保显示所有数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vaultProvider.notifier).searchItems('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final items = vaultState.filteredVaultItems ?? []; // Use filtered items from provider, default to empty list
    final groupedList = _buildGroupedList(items);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          l10n.myVault.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        backgroundColor: CupertinoColors.systemBackground.withValues(alpha: 0.0),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.settings,
            color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6),
          ),
          onPressed: () {
            Navigator.push(
              context,
              SlideFromLeftRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
        trailing: vaultState.isSelectionMode
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final count = vaultState.selectedIds.length;
                      if (count == 0) return;
                      
                      final confirmed = await showCupertinoDialog<bool>(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: Text(l10n.deleteSelected),
                          content: Text(l10n.deleteSelectedConfirm(count)),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.cancel),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        await ref.read(vaultProvider.notifier).deleteSelectedItems();
                      }
                    },
                    child: Text(
                      vaultState.selectedIds.isEmpty ? '' : l10n.deleteSelected,
                      style: TextStyle(
                        color: vaultState.selectedIds.isEmpty 
                            ? CupertinoColors.systemBackground 
                            : CupertinoColors.destructiveRed,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.xmark),
                    onPressed: () => ref.read(vaultProvider.notifier).toggleSelectionMode(),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      CupertinoIcons.trash,
                      color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6),
                    ),
                    onPressed: () => ref.read(vaultProvider.notifier).toggleSelectionMode(),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      CupertinoIcons.lock_open,
                      color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6),
                    ),
                    onPressed: () => ref.read(vaultProvider.notifier).lock(),
                  ),
                ],
              ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? CupertinoColors.white.withValues(alpha: 0.08) 
                        : CupertinoColors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CupertinoTextField(
                    controller: _searchController,
                    onChanged: (v) => ref.read(vaultProvider.notifier).searchItems(v),
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      fontSize: 16,
                    ),
                    placeholder: l10n.search,
                    placeholderStyle: TextStyle(
                      color: isDark ? CupertinoColors.white.withValues(alpha: 0.4) : CupertinoColors.black.withValues(alpha: 0.4),
                      fontSize: 16,
                    ),
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        CupertinoIcons.search, 
                        color: isDark ? CupertinoColors.white.withValues(alpha: 0.4) : CupertinoColors.black.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ),
                    suffix: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              ref.read(vaultProvider.notifier).searchItems("");
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                CupertinoIcons.clear_circled_solid, 
                                color: isDark ? CupertinoColors.white.withValues(alpha: 0.4) : CupertinoColors.black.withValues(alpha: 0.4),
                                size: 18,
                              ),
                            ),
                          )
                        : null,
                    decoration: null,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: isDark 
                      ? CupertinoColors.black
                      : const Color(0xFFF2F2F7),
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.lock,
                                size: 56,
                                color: (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.15),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noPasswords,
                                style: TextStyle(
                                  color: (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.3),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: CustomScrollView(
                                controller: _scrollController,
                                slivers: [
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final element = groupedList[index];
                                          if (element is String) {
                                            return _buildGroupHeader(element, isDark);
                                          }
                                          final item = element as VaultItem;
                                          String? domain;
                                          if (item.url != null && item.url!.isNotEmpty) {
                                            try {
                                              String urlStr = item.url!;
                                              if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
                                                urlStr = 'https://$urlStr';
                                              }
                                              final uri = Uri.parse(urlStr);
                                              domain = uri.host.isNotEmpty ? uri.host : null;
                                            } catch (_) {}
                                          }

                                          String displayChar = '?';
                                          if (item.title.isNotEmpty) {
                                            displayChar = item.title[0].toUpperCase();
                                          } else if (domain != null && domain.isNotEmpty) {
                                            displayChar = domain[0].toUpperCase();
                                          }

                                          String? subtitle;
                                          if (item.username != null && item.username!.isNotEmpty) {
                                            subtitle = item.username;
                                          } else if (domain != null && domain.isNotEmpty) {
                                            subtitle = domain;
                                          } else {
                                            subtitle = null;
                                          }

                                          return _iOSListItem(
                                            title: item.title,
                                            subtitle: subtitle,
                                            updatedAt: item.updatedAt,
                                            displayChar: displayChar,
                                            domain: domain,
                                            isDark: isDark,
                                            isSelectionMode: vaultState.isSelectionMode,
                                            isSelected: vaultState.selectedIds.contains(item.id),
                                            onSelect: () => ref.read(vaultProvider.notifier).toggleItemSelection(item.id),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                  builder: (context) => DetailPage(item: item),
                                                ),
                                              );
                                            },
                                            getColorForChar: _getColorForChar,
                                          );
                                        },
                                        childCount: groupedList.length,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (items.length >= 20)
                              AlphabetIndexBar(
                                letters: _getAvailableLetters(items),
                                onLetterSelected: (letter) => _scrollToLetter(letter, groupedList),
                                isDark: isDark,
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 32,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const AddItemPage()),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.add,
                  size: 28,
                  color: isDark ? CupertinoColors.black : CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Color _getColorForChar(String char) {
    final colors = [
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFAF52DE),
      const Color(0xFFFF3B30),
      const Color(0xFF5AC8FA),
      const Color(0xFFFF2D55),
      const Color(0xFF5856D6),
      const Color(0xFF00C7BE),
      const Color(0xFFFFCC00),
    ];
    final index = char.toUpperCase().codeUnitAt(0) % colors.length;
    return colors[index];
  }

  /// 获取条目在索引栏中对应的字母：英文取首字母，中文取拼音首字母，数字返回 '#'
  String _getIndexLetter(item) {
    if (item.title.isEmpty) return '#';
    final code = item.title[0].codeUnitAt(0);
    if (code >= 48 && code <= 57) return '#'; // 数字
    if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) {
      return item.title[0].toUpperCase(); // 英文
    }
    // 中文：取拼音首字母
    final pinyin = item.titlePinyin as String?;
    if (pinyin != null && pinyin.isNotEmpty) {
      return pinyin[0].toUpperCase();
    }
    return '#';
  }

  List<String> _getAvailableLetters(List items) {
    final letters = <String>{};
    for (final item in items) {
      letters.add(_getIndexLetter(item));
    }
    return letters.toList()..sort();
  }

  void _scrollToLetter(String letter, List<Object> groupedList) {
    const double itemHeight = 79.0;
    const double headerHeight = 32.0;
    double offset = 8.0; // SliverPadding top
    for (final element in groupedList) {
      if (element is String && element == letter) break;
      offset += element is String ? headerHeight : itemHeight;
    }
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Object> _buildGroupedList(List items) {
    final result = <Object>[];
    String? currentLetter;
    for (final item in items) {
      final letter = _getIndexLetter(item);
      if (letter != currentLetter) {
        result.add(letter);
        currentLetter = letter;
      }
      result.add(item);
    }
    return result;
  }

  Widget _buildGroupHeader(String letter, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Text(
        letter,
        style: TextStyle(
          color: isDark
              ? CupertinoColors.white.withValues(alpha: 0.4)
              : CupertinoColors.black.withValues(alpha: 0.45),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _iOSListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final DateTime? updatedAt;
  final String displayChar;
  final String? domain;
  final bool isDark;
  final VoidCallback onTap;
  final Color Function(String) getColorForChar;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const _iOSListItem({
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.displayChar,
    required this.domain,
    required this.isDark,
    required this.onTap,
    required this.getColorForChar,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColorForChar(displayChar);
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: isSelectionMode ? onSelect : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF1C1C1E)
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? CupertinoColors.activeBlue
                  : isDark 
                      ? CupertinoColors.white.withValues(alpha: 0.08)
                      : CupertinoColors.black.withValues(alpha: 0.06),
              width: isSelected ? 2 : 0.5,
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (isSelectionMode) ...[
                Icon(
                  isSelected 
                      ? CupertinoIcons.check_mark_circled_solid 
                      : CupertinoIcons.circle,
                  color: isSelected 
                      ? CupertinoColors.activeBlue
                      : isDark ? CupertinoColors.white.withValues(alpha: 0.4) : CupertinoColors.black.withValues(alpha: 0.4),
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              _buildIcon(color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6),
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (updatedAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(updatedAt),
                        style: TextStyle(
                          color: isDark ? CupertinoColors.white.withValues(alpha: 0.4) : CupertinoColors.black.withValues(alpha: 0.4),
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            Icon(
              CupertinoIcons.chevron_forward,
              color: isDark ? CupertinoColors.white.withValues(alpha: 0.25) : CupertinoColors.black.withValues(alpha: 0.25),
              size: 18,
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    if (domain != null && domain!.isNotEmpty) {
      final faviconUrl = 'https://$domain/favicon.ico';
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: faviconUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildFallbackIcon(color),
            errorWidget: (context, url, error) => _buildFallbackIcon(color),
          ),
        ),
      );
    }
    return _buildFallbackIcon(color);
  }

  Widget _buildFallbackIcon(Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          displayChar[0].toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
