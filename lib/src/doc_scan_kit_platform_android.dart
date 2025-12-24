import 'package:doc_scan_kit/src/doc_scan_kit_method_channel.dart';

import 'doc_scan_kit_platform.dart';

/// Android-specific implementation of [DocScanKitPlatform].
/// 
/// This class provides the Android implementation for document scanning,
/// text recognition, and QR code scanning using Google's ML Kit APIs
/// through method channel communication.
/// 
/// The implementation extends [DocScanKitMethodChannel] to inherit the
/// common method channel communication logic while providing Android-specific
/// registration and initialization.
/// 
/// This class is automatically registered when the plugin is initialized
/// on Android devices through the Flutter plugin system.
class DocScanKitPlatformAndroid extends DocScanKitMethodChannel {
  /// Registers this Android implementation as the default platform implementation.
  /// 
  /// This method is called automatically by the Flutter plugin system
  /// when the app runs on Android devices. It sets this instance as the
  /// active platform implementation for all DocScanKit operations.
  /// 
  /// The registration ensures that all document scanning, text recognition,
  /// and QR code scanning operations will use Android-specific native code
  /// through the ML Kit APIs.
  static void registerWith() {
    DocScanKitPlatform.instance = DocScanKitPlatformAndroid();
  }
}
