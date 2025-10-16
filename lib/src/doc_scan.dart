import '../doc_scan_kit.dart';
import 'doc_scan_kit_platform_interface.dart';

class DocScanKit {
  final DocumentScanKitOptionsAndroid? androidOptions;
  final DocumentScanKitOptionsiOS? iosOptions;

  DocScanKit({
    this.androidOptions,
    this.iosOptions,
  });

  Future<List<ScanResult>> scanner() {
    return DocScanKitPlatform.instance.scanner(
        androidOptions ?? DocumentScanKitOptionsAndroid(),
        iosOptions ?? DocumentScanKitOptionsiOS());
  }

  /// Recognizes text from the provided image bytes
  ///
  /// Returns the recognized text as a string
  Future<String> recognizeText(
    List<int> imageBytes, [
    DocumentScanKitTextRecognitionOptionsiOS? textRecognitionOptions,
  ]) {
    return DocScanKitPlatform.instance.recognizeText(
      imageBytes,
      textRecognitionOptions ?? DocumentScanKitTextRecognitionOptionsiOS(),
    );
  }

  /// Recognizes text with full details (blocks, lines, elements, symbols)
  ///
  /// Returns a [TextRecognitionResult] containing the complete text hierarchy
  Future<TextRecognitionResult> recognizeTextDetailed(
    List<int> imageBytes, [
    DocumentScanKitTextRecognitionOptionsiOS? textRecognitionOptions,
  ]) {
    return DocScanKitPlatform.instance.recognizeTextDetailed(
      imageBytes,
      textRecognitionOptions ?? DocumentScanKitTextRecognitionOptionsiOS(),
    );
  }

  /// Scans for QR codes in the provided image bytes
  ///
  /// Returns the detected QR code content as a string
  Future<String> scanQrCode(List<int> imageBytes) {
    return DocScanKitPlatform.instance.scanQrCode(imageBytes);
  }

  Future<void> close() => DocScanKitPlatform.instance.close();
}
