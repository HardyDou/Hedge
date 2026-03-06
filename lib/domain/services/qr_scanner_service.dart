import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart' as img;

/// QR 码扫描服务
class QrScannerService {
  /// 尝试解码图片中的二维码
  static String? _tryDecodeImage(img.Image image) {
    try {
      final reader = QRCodeReader();

      // 将图片转换为 Int32List 格式
      final width = image.width;
      final height = image.height;
      final pixels = Int32List(width * height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = image.getPixel(x, y);
          // 转换为 0xAARRGGBB 格式
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          final a = pixel.a.toInt();
          pixels[y * width + x] = (a << 24) | (r << 16) | (g << 8) | b;
        }
      }

      // 创建 LuminanceSource
      final source = RGBLuminanceSource(width, height, pixels);

      // 尝试 HybridBinarizer
      try {
        final bitmap = BinaryBitmap(HybridBinarizer(source));
        final result = reader.decode(bitmap);
        return result.text;
      } catch (e) {
        // HybridBinarizer 失败，尝试 GlobalHistogramBinarizer
        try {
          final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
          final result = reader.decode(bitmap);
          return result.text;
        } catch (e) {
          return null;
        }
      }
    } catch (e) {
      return null;
    }
  }

  /// 从图片中识别 QR 码（用于桌面端）
  static Future<String?> scanFromImage() async {
    try {
      print('开始选择图片...');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        print('用户取消选择图片');
        return null;
      }

      print('图片路径: ${image.path}');
      print('图片名称: ${image.name}');

      // 读取图片文件
      print('开始读取图片文件...');
      final bytes = await File(image.path).readAsBytes();

      // 解码图片
      print('开始解码图片...');
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        print('图片解码失败');
        return null;
      }

      print('图片尺寸: ${decodedImage.width}x${decodedImage.height}');

      // 尝试多种策略识别二维码
      print('开始使用 zxing2 识别二维码...');

      // 策略1: 直接识别原图
      String? result = _tryDecodeImage(decodedImage);
      if (result != null) {
        print('策略1成功: 直接识别原图');
        return result;
      }

      // 策略2: 调整图片大小后识别（如果图片太大）
      if (decodedImage.width > 1000 || decodedImage.height > 1000) {
        print('策略2: 缩小图片后识别...');
        final resized = img.copyResize(
          decodedImage,
          width: decodedImage.width > decodedImage.height ? 1000 : null,
          height: decodedImage.height > decodedImage.width ? 1000 : null,
        );
        result = _tryDecodeImage(resized);
        if (result != null) {
          print('策略2成功: 缩小图片后识别');
          return result;
        }
      }

      // 策略3: 增强对比度后识别
      print('策略3: 增强对比度后识别...');
      final contrasted = img.adjustColor(
        decodedImage,
        contrast: 1.5,
        brightness: 1.1,
      );
      result = _tryDecodeImage(contrasted);
      if (result != null) {
        print('策略3成功: 增强对比度后识别');
        return result;
      }

      // 策略4: 转为灰度图后识别
      print('策略4: 转为灰度图后识别...');
      final grayscale = img.grayscale(decodedImage);
      result = _tryDecodeImage(grayscale);
      if (result != null) {
        print('策略4成功: 转为灰度图后识别');
        return result;
      }

      print('所有识别策略均失败');
      return null;
    } catch (e, stackTrace) {
      print('扫描图片错误: $e');
      print('堆栈跟踪: $stackTrace');
      return null;
    }
  }

  /// 解析 TOTP URI
  /// 格式: otpauth://totp/Issuer:Account?secret=SECRET&issuer=Issuer
  static Map<String, String>? parseTotpUri(String uri) {
    try {
      if (!uri.startsWith('otpauth://totp/')) {
        return null;
      }

      final parsedUri = Uri.parse(uri);
      final secret = parsedUri.queryParameters['secret'];

      if (secret == null || secret.isEmpty) {
        return null;
      }

      // 提取 issuer 和 account
      String? issuer = parsedUri.queryParameters['issuer'];
      String? account;

      // 从路径中提取 issuer 和 account
      // 格式: /Issuer:Account 或 /Account
      final path = parsedUri.path;
      if (path.contains(':')) {
        final parts = path.substring(1).split(':');
        issuer ??= parts[0];
        account = parts.length > 1 ? parts[1] : null;
      } else {
        account = path.substring(1);
      }

      return {
        'secret': secret,
        'issuer': issuer ?? '',
        'account': account ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  /// 验证 TOTP Secret 格式
  static bool isValidSecret(String secret) {
    // Base32 字符集: A-Z, 2-7
    final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
    return secret.isNotEmpty && base32Regex.hasMatch(secret.toUpperCase());
  }
}
