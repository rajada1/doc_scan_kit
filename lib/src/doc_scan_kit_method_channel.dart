import 'package:doc_scan_kit/src/options/android_options.dart';
import 'package:doc_scan_kit/src/options/ios_options.dart';
import 'package:doc_scan_kit/src/options/ios_text_recognition_options.dart';
import 'package:doc_scan_kit/src/options/scan_result.dart';
import 'package:doc_scan_kit/src/options/text_recognition_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'doc_scan_kit_platform_interface.dart';

/// An implementation of [DocScanKitPlatform] that uses method channels.
class MethodChannelDocScanKit extends DocScanKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('doc_scan_kit');

  /// Instance id.
  final id = DateTime.now().microsecondsSinceEpoch.toString();
  @override
  Future<List<ScanResult>> scanner(
    final DocumentScanKitOptionsAndroid androidOptions,
    final DocumentScanKitOptionsiOS iosOptions,
  ) async {
    return (await methodChannel.invokeMethod<List<Object?>>(
                'scanKit#startDocumentScanner', <String, dynamic>{
          'androidOptions': androidOptions.toJson(),
          'id': id,
          'iosOptions': iosOptions.toJson()
        }))
            ?.map(
          (e) {
            e as Map;
            return ScanResult(imagePath: e['path'], imagesBytes: e['bytes']);
          },
        ).toList() ??
        [];
  }

  @override

  /// Recognizes text from image bytes
  Future<String> recognizeText(List<int> imageBytes,
      DocumentScanKitTextRecognitionOptionsiOS textRecognitionOptions) async {
    final result = await methodChannel.invokeMethod<String>(
      'scanKit#recognizeText',
      {
        'imageBytes': imageBytes,
        'iosOptions': textRecognitionOptions.toJson(),
        'id': id,
      },
    );
    return result ?? '';
  }

  @override

  /// Recognizes text with full details (blocks, lines, elements, symbols)
  Future<TextRecognitionResult> recognizeTextDetailed(
    List<int> imageBytes,
    DocumentScanKitTextRecognitionOptionsiOS textRecognitionOptions,
  ) async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'vision#startTextRecognizer',
      {
        'imageData': {
          'type': 'bytes',
          'bytes': Uint8List.fromList(imageBytes),
        },
        'iosOptions': textRecognitionOptions.toJson(),
        'id': id,
      },
    );

    if (result == null) {
      return TextRecognitionResult(text: '', blocks: []);
    }

    return TextRecognitionResult.fromMap(result);
  }

  @override

  /// Scans for QR codes in image bytes
  Future<String> scanQrCode(List<int> imageBytes) async {
    final result = await methodChannel.invokeMethod<String>(
      'scanKit#scanQrCode',
      {
        'imageBytes': imageBytes,
        'id': id,
      },
    );
    return result ?? '';
  }

  @override

  /// Close the detector and release resources.
  Future<void> close() {
    return methodChannel
        .invokeMethod<void>("scanKit#closeDocumentScanner", {'id': id});
  }
}
