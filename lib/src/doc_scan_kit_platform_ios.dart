import 'package:doc_scan_kit/src/doc_scan_kit_method_channel.dart';

import 'doc_scan_kit_platform.dart';

/// iOS-specific implementation of [DocScanKitPlatform].
/// 
/// This class provides the iOS implementation for document scanning,
/// text recognition, and QR code scanning using Apple's native APIs
/// including VNDocumentCameraViewController and Vision framework
/// through method channel communication.
/// 
/// The implementation extends [DocScanKitMethodChannel] to inherit the
/// common method channel communication logic while providing iOS-specific
/// registration and initialization.
/// 
/// This class is automatically registered when the plugin is initialized
/// on iOS devices through the Flutter plugin system.
class DocScanKitPlatformIOS extends DocScanKitMethodChannel {
  /// Registers this iOS implementation as the default platform implementation.
  /// 
  /// This method is called automatically by the Flutter plugin system
  /// when the app runs on iOS devices. It sets this instance as the
  /// active platform implementation for all DocScanKit operations.
  /// 
  /// The registration ensures that all document scanning, text recognition,
  /// and QR code scanning operations will use iOS-specific native code
  /// through Apple's Vision and Document Camera frameworks.
  static void registerWith() {
    DocScanKitPlatform.instance = DocScanKitPlatformIOS();
  }
}
