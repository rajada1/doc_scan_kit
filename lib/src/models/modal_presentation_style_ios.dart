/// iOS modal presentation styles for the document scanner view controller.
///
/// This enum defines how the document scanner interface is presented
/// to the user on iOS devices. Each style affects the visual transition
/// and layout behavior of the scanner view controller.
///
/// These styles correspond to UIKit's UIModalPresentationStyle options
/// and provide different user experience patterns.
///
/// Example usage:
/// ```dart
/// final iosOptions = DocScanKitOptionsIOS(
///   modalPresentationStyle: ModalPresentationStyleIOS.overFullScreen,
/// );
/// ```
enum ModalPresentationStyleIOS {
  /// The system automatically chooses the most appropriate presentation style.
  ///
  /// This style allows iOS to select the best presentation method based on:
  /// - Device type (iPhone vs iPad)
  /// - Screen size and orientation
  /// - Current interface idiom
  /// - System preferences and accessibility settings
  ///
  /// This is often the safest choice for apps that need to work well
  /// across different iOS devices and configurations.
  automatic,

  /// Presents the scanner over the current view controller's content.
  ///
  /// In this style:
  /// - The scanner is presented within the bounds of the current context
  /// - The underlying content may remain partially visible
  /// - Useful for maintaining visual context with the presenting view
  /// - May not cover the entire screen on larger devices
  ///
  /// This style works well when you want to maintain some connection
  /// to the presenting interface.
  currentContext,

  /// Presents the scanner covering the entire screen.
  ///
  /// In this style:
  /// - The scanner completely covers the screen content
  /// - Provides maximum screen real estate for scanning
  /// - Creates a focused, distraction-free scanning experience
  /// - Works consistently across all device sizes
  ///
  /// This is the recommended style for most scanning scenarios as it
  /// provides the best user experience for document capture.
  overFullScreen,

  /// Presents the scanner in a popover view (primarily for iPad).
  ///
  /// In this style:
  /// - The scanner appears in a floating popover window
  /// - Particularly useful on iPad with larger screen sizes
  /// - Allows users to see and interact with underlying content
  /// - May automatically adapt to other styles on smaller devices
  ///
  /// This style is ideal for iPad apps where the scanner is part of
  /// a larger workflow and context preservation is important.
  popover,
}
