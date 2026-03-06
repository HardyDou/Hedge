import 'package:flutter/cupertino.dart';
import 'package:hedge/domain/services/qr_scanner_service.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/pages/desktop/desktop_camera_scanner_dialog.dart';

/// 桌面端 QR 码扫描对话框
/// 提供三种方式：相机扫描、选择图片、手动输入
class DesktopQrScannerDialog extends StatefulWidget {
  const DesktopQrScannerDialog({super.key});

  @override
  State<DesktopQrScannerDialog> createState() => _DesktopQrScannerDialogState();
}

class _DesktopQrScannerDialogState extends State<DesktopQrScannerDialog> {
  bool _isProcessing = false;

  Future<void> _openCameraScanner() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      CupertinoPageRoute(
        builder: (context) => const DesktopCameraScannerDialog(),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isProcessing = true);

    try {
      final result = await QrScannerService.scanFromImage();

      if (result == null) {
        setState(() => _isProcessing = false);
        if (mounted) {
          _showError('未识别到二维码\n\n请确保：\n1. 图片清晰可见\n2. 二维码完整无遮挡\n3. 图片格式正确');
        }
        return;
      }

      print('识别到二维码内容: $result');

      // 解析 TOTP URI
      final totpData = QrScannerService.parseTotpUri(result);

      if (totpData != null && mounted) {
        print('解析成功: $totpData');
        Navigator.pop(context, totpData);
      } else if (mounted) {
        print('解析失败，原始内容: $result');
        _showError('无效的 TOTP 二维码\n\n识别到的内容：\n$result\n\n请确保二维码是 TOTP 格式');
      }
    } catch (e) {
      print('识别异常: $e');
      if (mounted) {
        _showError('识别失败\n\n错误信息：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showManualInputDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.manualInput),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              l10n.manualInputHint,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: 'TOTP Secret',
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final secret = controller.text.trim().toUpperCase();
              if (QrScannerService.isValidSecret(secret)) {
                Navigator.pop(context);
                Navigator.pop(this.context, {
                  'secret': secret,
                  'issuer': '',
                  'account': '',
                });
              } else {
                _showError(l10n.invalidSecret);
              }
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
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

    return CupertinoAlertDialog(
      title: Text(l10n.addTotp),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.addTotpHint,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          onPressed: _isProcessing ? null : _openCameraScanner,
          child: Text(l10n.scanQrCode),
        ),
        CupertinoDialogAction(
          onPressed: _isProcessing ? null : _pickImage,
          child: Text(
            _isProcessing
                ? l10n.processing
                : l10n.selectImage,
          ),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context);
            _showManualInputDialog();
          },
          child: Text(l10n.manualInput),
        ),
      ],
    );
  }
}
