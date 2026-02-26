import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:note_password/presentation/pages/detail_page.dart';
import 'package:note_password/presentation/pages/settings_page.dart';
import 'package:note_password/presentation/pages/unlock_page.dart';
import 'package:note_password/presentation/pages/onboarding_page.dart';
import 'package:note_password/presentation/providers/locale_provider.dart';
import 'package:note_password/presentation/providers/theme_provider.dart';
import 'package:note_password/presentation/providers/vault_provider.dart';
import 'package:note_password/src/rust/api/model.dart';
import 'package:note_password/src/rust/frb_generated.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';
import 'package:note_password/presentation/pages/add_item_page.dart';

class SlideFromLeftRoute<T> extends CupertinoPageRoute<T> {
  SlideFromLeftRoute({required super.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
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
  }

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const ProviderScope(child: NotePasswordApp()));
}

class NotePasswordApp extends ConsumerWidget {
  const NotePasswordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'NotePassword',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
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
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A1A),
        ),
        useMaterial3: true,
      ),
      home: const AuthGuard(),
    );
  }
}

class AuthGuard extends ConsumerStatefulWidget {
  const AuthGuard({super.key});

  @override
  ConsumerState<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends ConsumerState<AuthGuard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vaultProvider.notifier).checkInitialStatus());
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);

    if (vaultState.isLoading && vaultState.vault == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!vaultState.hasVaultFile) {
      return const OnboardingPage();
    }

    if (!vaultState.isAuthenticated) {
      return const UnlockPage();
    }

    return const HomePage();
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = vaultState.vault?.items.where((item) {
          final query = _searchQuery.toLowerCase();
          return item.title.toLowerCase().contains(query) ||
              (item.username?.toLowerCase().contains(query) ?? false) ||
              (item.notes?.toLowerCase().contains(query) ?? false);
        }).toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myVault.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white38 : Colors.black38),
          onPressed: () {
            Navigator.push(
              context,
              SlideFromLeftRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
        actions: vaultState.isSelectionMode
            ? [
                TextButton(
                  onPressed: () async {
                    final count = vaultState.selectedIds.length;
                    if (count == 0) return;
                    
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.deleteSelected),
                        content: Text(l10n.deleteSelectedConfirm(count)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
                    style: TextStyle(color: vaultState.selectedIds.isEmpty ? Colors.transparent : Colors.red),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(vaultProvider.notifier).toggleSelectionMode(),
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.delete_outline, color: isDark ? Colors.white38 : Colors.black38),
                  onPressed: () => ref.read(vaultProvider.notifier).toggleSelectionMode(),
                ),
                IconButton(
                  icon: Icon(Icons.lock_open_rounded, color: isDark ? Colors.white38 : Colors.black38),
                  onPressed: () => ref.read(vaultProvider.notifier).lock(),
                ),
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.08) 
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: l10n.search,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search, 
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: isDark 
                  ? const Color(0xFF000000)
                  : const Color(0xFFF2F2F7),
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 56,
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noPasswords,
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
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
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const AddItemPage()),
          );
        },
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
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
}

class _iOSListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? updatedAt;
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

  String _formatDate(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
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
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF007AFF)
                  : isDark 
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
              width: isSelected ? 2 : 0.5,
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                      ? Icons.check_circle 
                      : Icons.circle_outlined,
                  color: isSelected 
                      ? const Color(0xFF007AFF) 
                      : isDark ? Colors.white38 : Colors.black38,
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
                        color: isDark ? Colors.white : Colors.black,
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
                          color: isDark ? Colors.white54 : Colors.black54,
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
                          color: isDark ? Colors.white38 : Colors.black38,
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
              Icons.chevron_right,
              color: isDark ? Colors.white24 : Colors.black26,
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
          color: Colors.white,
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
        color: color.withOpacity(0.15),
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
