import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:hedge/domain/services/qr_scanner_service.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';

/// QR 码扫描页面（移动端）
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_isProcessing) return;

      final code = scanData.code;
      if (code != null && code.isNotEmpty) {
        _handleScannedCode(code);
      }
    });
  }

  void _handleScannedCode(String code) {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    // 解析 TOTP URI
    final result = QrScannerService.parseTotpUri(code);

    if (result != null) {
      // 扫描成功，返回结果
      controller?.pauseCamera();
      Navigator.pop(context, result);
    } else {
      // 扫描失败，显示错误提示
      _showError();
      setState(() => _isProcessing = false);
    }
  }

  void _showError() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.scanFailed),
        content: Text(l10n.invalidQrCode),
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

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        middle: Text(
          l10n.scanQrCode,
          style: const TextStyle(color: CupertinoColors.white),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Stack(
        children: [
          // 相机预览
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: CupertinoColors.activeBlue,
              borderRadius: 16,
              borderLength: 40,
              borderWidth: 8,
              cutOutSize: 280,
            ),
          ),
          // 提示文字
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.scanQrCodeHint,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
