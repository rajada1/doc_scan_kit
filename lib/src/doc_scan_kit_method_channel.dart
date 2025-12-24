import 'package:doc_scan_kit/src/models/doc_scan_kit_method.dart';
import 'package:doc_scan_kit/src/models/doc_scan_kit_options.dart';
import 'package:doc_scan_kit/src/models/doc_scan_kit_result.dart';
import 'package:doc_scan_kit/src/models/doc_scan_kit_result_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'doc_scan_kit_platform.dart';

/// Abstract base class for method channel implementation of [DocScanKitPlatform].
///
/// This class provides the common implementation for communicating with
/// native platform code through Flutter's method channel system. It handles
/// serialization of method calls and deserialization of results.
///
/// Platform-specific implementations ([DocScanKitPlatformAndroid] and
/// [DocScanKitPlatformIOS]) extend this class to provide the actual
/// registration and platform-specific behavior.
///
/// This class is abstract and cannot be instantiated directly. Use the
/// platform-specific implementations instead.
abstract class DocScanKitMethodChannel extends DocScanKitPlatform {
  /// The method channel used to communicate with native platform implementations.
  ///
  /// This channel is used for all method calls to native code including
  /// document scanning, text recognition, and QR code scanning operations.
  ///
  /// The channel name 'doc_scan_kit' must match the channel name registered
  /// in the native platform implementations.
  @visibleForTesting
  final methodChannel = const MethodChannel('doc_scan_kit');

  /// Unique identifier for this plugin instance.
  ///
  /// This ID is generated based on the current timestamp and is used to
  /// identify this specific instance when communicating with native code.
  /// It helps distinguish between multiple plugin instances and manage
  /// platform-specific resources properly.
  final id = DateTime.now().microsecondsSinceEpoch.toString();

  /// Invokes the native document scanner through method channel communication.
  ///
  /// This method serializes the provided [options] and sends them to the native
  /// platform implementation via the 'scanKit#startDocumentScanner' method call.
  ///
  /// [options] - Platform-specific configuration options that control scanner behavior.
  ///
  /// The native implementation will:
  /// 1. Launch the appropriate document scanner UI
  /// 2. Handle user interactions and document capture
  /// 3. Process scanned images according to the format setting
  /// 4. Return results as a list of file paths and types
  ///
  /// Returns a [Future] that completes with a list of [DocScanKitResult] objects.
  /// Each result contains the file path and type (JPEG or PDF) of scanned content.
  ///
  /// Throws [PlatformException] if the native scanner encounters an error.
  @override
  Future<List<DocScanKitResult>> scanner(final DocScanKitOptions options) async {
    final result = await methodChannel.invokeMethod<List<Object?>>(
      DocScanKitMethod.startDocumentScanner.platformName,
      {'id': id, 'options': options.toJson()},
    );

    return result
            ?.cast<Map>()
            .map((e) => DocScanKitResult(
                  type: DocScanKitResultType.values.byName(e['type']),
                  path: e['path'] as String,
                ))
            .toList() ??
        [];
  }

  /// Closes the scanner and releases native resources through method channel.
  ///
  /// This method notifies the native platform implementation to clean up
  /// any resources associated with this plugin instance via the
  /// 'scanKit#closeDocumentScanner' method call.
  ///
  /// The native implementation will:
  /// 1. Dispose of any active scanner sessions
  /// 2. Release ML Kit or other native resources
  /// 3. Clean up temporary files if any
  ///
  /// This is particularly important on Android where ML Kit resources
  /// need explicit cleanup to prevent memory leaks.
  ///
  /// Returns a [Future] that completes when the cleanup is finished.
  @override
  Future<void> close() {
    return methodChannel.invokeMethod<void>(
      DocScanKitMethod.closeDocumentScanner.platformName,
      {'id': id},
    );
  }

  /// Invokes native text recognition through method channel communication.
  ///
  /// This method sends the image bytes to the native platform implementation
  /// via the 'scanKit#recognizeText' method call for OCR processing.
  ///
  /// [imageBytes] - Raw bytes of the image file to process for text recognition.
  ///
  /// The native implementation will:
  /// 1. Convert the byte array to a platform-specific image format
  /// 2. Apply OCR using platform-specific text recognition APIs
  /// 3. Return the extracted text as a string
  ///
  /// Returns a [Future] that completes with the recognized text as a [String].
  /// Returns an empty string if no text is found or recognition fails.
  @override
  Future<String> recognizeText(final List<int> imageBytes) async {
    final result = await methodChannel.invokeMethod<String>(
      DocScanKitMethod.recognizeText.platformName,
      {'id': id, 'imageBytes': imageBytes},
    );
    return result ?? '';
  }

  /// Invokes native QR code scanning through method channel communication.
  ///
  /// This method sends the image bytes to the native platform implementation
  /// via the 'scanKit#scanQrCode' method call for barcode detection and decoding.
  ///
  /// [imageBytes] - Raw bytes of the image file containing QR code(s) to scan.
  ///
  /// The native implementation will:
  /// 1. Convert the byte array to a platform-specific image format
  /// 2. Detect and decode QR codes using platform-specific barcode APIs
  /// 3. Return the decoded content as a string
  ///
  /// Returns a [Future] that completes with the QR code content as a [String].
  /// Returns an empty string if no QR code is found or decoding fails.
  @override
  Future<String> scanQrCode(final List<int> imageBytes) async {
    final result = await methodChannel.invokeMethod<String>(
      DocScanKitMethod.scanQrCode.platformName,
      {'id': id, 'imageBytes': imageBytes},
    );
    return result ?? '';
  }
}
