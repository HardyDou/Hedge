import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hedge/domain/services/qr_scanner_service.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/core/theme/app_colors.dart';

/// 桌面端相机扫描对话框
class DesktopCameraScannerDialog extends StatefulWidget {
  const DesktopCameraScannerDialog({super.key});

  @override
  State<DesktopCameraScannerDialog> createState() => _DesktopCameraScannerDialogState();
}

class _DesktopCameraScannerDialogState extends State<DesktopCameraScannerDialog> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    final result = barcode.rawValue!;
    final totpData = QrScannerService.parseTotpUri(result);

    if (totpData != null && mounted) {
      Navigator.pop(context, totpData);
    } else if (mounted) {
      _showError('无效的 TOTP 二维码');
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AppColors.isDark(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.surface1.resolveFrom(context),
        middle: Text(l10n.scanQrCode),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ),
      child: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: CupertinoColors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '将二维码放入框内',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
