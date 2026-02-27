import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';

class LargePasswordPage extends StatefulWidget {
  final String password;
  const LargePasswordPage({super.key, required this.password});

  static void show(BuildContext context, String password) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => LargePasswordPage(password: password),
      ),
    );
  }

  @override
  State<LargePasswordPage> createState() => _LargePasswordPageState();
}

class _LargePasswordPageState extends State<LargePasswordPage> {
  bool _isLandscape = false;
  bool _copied = false;

  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: widget.password));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _close() async {
    if (_isLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark),
          onPressed: _close,
        ),
        title: Text(l10n.password),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        runSpacing: 12,
                        spacing: 8,
                        children: List.generate(widget.password.length, (index) {
                          return _buildCharWithIndex(widget.password[index], index + 1);
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: _isLandscape ? Icons.screen_rotation : Icons.rotate_right,
                    label: _isLandscape ? l10n.vertical : l10n.horizontal,
                    onTap: _toggleOrientation,
                  ),
                  const SizedBox(width: 32),
                  _buildActionButton(
                    icon: _copied ? CupertinoIcons.checkmark : CupertinoIcons.doc_on_doc,
                    label: _copied ? l10n.copied(l10n.password) : l10n.copyPassword,
                    onTap: _copyPassword,
                    isHighlighted: _copied,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFF34C759) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharWithIndex(String char, int index) {
    final isEven = index % 2 == 0;
    final bgColor = isEven ? const Color(0xFF2C2C2E) : const Color(0xFF3A3A3C);
    final textColor = isEven ? Colors.white : Colors.white.withValues(alpha: 0.85);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              char,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'monospace',
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$index',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
