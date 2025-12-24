import 'package:doc_scan_kit/doc_scan_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CustomScanResult {
  final Uint8List imagesBytes;
  final String? imagePath;
  String? text;
  String? qrCode;

  CustomScanResult({
    required this.imagesBytes,
    this.imagePath,
    this.text,
    this.qrCode,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const DocumentScannerScreen(),
    );
  }
}

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  // iOS configuration options
  DocScanKitFormat format = DocScanKitFormat.images;
  double compressionQuality = 0.2;
  bool useQrCodeScanner = false;
  bool useTextRecognizer = false;
  Color color = Colors.orange;
  ModalPresentationStyleIOS modalPresentationStyle =
      ModalPresentationStyleIOS.overFullScreen;

  // Android configuration options
  DocScanKitFormat formatAndroid = DocScanKitFormat.images;
  int pageLimit = 3;
  bool recognizerTextAndroid = false;
  bool isGalleryImport = false;
  ScannerModeAndroid scannerMode = ScannerModeAndroid.full;

  List<CustomScanResult> imageData = [];
  bool isLoading = false;

  Future<void> scan() async {
    final instance = DocScanKit(
      iosOptions: DocScanKitOptionsIOS(
        compressionQuality: compressionQuality,
        format: format,
        color: color,
        modalPresentationStyle: modalPresentationStyle,
      ),
      androidOptions: DocScanKitOptionsAndroid(
        pageLimit: pageLimit,
        format: formatAndroid,
        isGalleryImport: isGalleryImport,
        scannerMode: scannerMode,
      ),
    );
    try {
      setState(() => isLoading = true);

      final List<DocScanKitResult> files = await instance.scanner();
      final results = <CustomScanResult>[];

      for (final file in files) {
        // CustomScanResult customResult = CustomScanResult(
        //   imagesBytes: file.imagesBytes,
        //   imagePath: file.imagePath,
        // );
        //
        // // Processing text recognition if enabled
        // if ((recognizerTextAndroid && Platform.isAndroid) ||
        //     (useTextRecognizer && Platform.isIOS)) {
        //   try {
        //     customResult.text = await instance.recognizeText(file.imagesBytes);
        //   } catch (e) {
        //     debugPrint('Text recognition failed: $e');
        //   }
        // }
        //
        // // Processing QR code if enabled
        // if (useQrCodeScanner) {
        //   try {
        //     customResult.qrCode = await instance.scanQrCode(file.imagesBytes);
        //   } catch (e) {
        //     debugPrint('QR Code scanning failed: $e');
        //   }
        // }
        //
        // results.add(customResult);
      }

      setState(() => imageData = results);
    } on PlatformException catch (e) {
      debugPrint('Failed $e');
    } finally {
      instance.close();
      setState(() => isLoading = false);
    }
  }

  Future<void> processImageFromLibrary() async {
    setState(() => isLoading = true);

    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> selectedImages = await picker.pickMultiImage();

      if (selectedImages.isEmpty) {
        debugPrint('No images selected');
        return;
      }

      DocScanKit instance = DocScanKit(
        iosOptions: DocScanKitOptionsIOS(
          compressionQuality: compressionQuality,
          format: format,
          color: color,
          modalPresentationStyle: modalPresentationStyle,
        ),
        androidOptions: DocScanKitOptionsAndroid(
          pageLimit: pageLimit,
          format: formatAndroid,
          isGalleryImport: isGalleryImport,
          scannerMode: scannerMode,
        ),
      );

      List<CustomScanResult> results = [];

      for (var selectedImage in selectedImages) {
        final Uint8List imageUint8List =
            Uint8List.fromList(await selectedImage.readAsBytes());

        CustomScanResult customResult = CustomScanResult(
          imagesBytes: imageUint8List,
          imagePath: selectedImage.path,
        );

        // Text recognition
        if (recognizerTextAndroid || useTextRecognizer) {
          try {
            customResult.text = await instance.recognizeText(imageUint8List);
          } catch (e) {
            debugPrint('Text recognition failed: $e');
          }
        }

        // QR code detection
        if (useQrCodeScanner) {
          try {
            customResult.qrCode = await instance.scanQrCode(imageUint8List);
          } catch (e) {
            debugPrint('QR Code scanning failed: $e');
          }
        }

        results.add(customResult);
      }

      setState(() => imageData.addAll(results));
      instance.close();
    } catch (e) {
      debugPrint('Error processing gallery images: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openSettingsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfigurationScreen(
          // iOS options
          compressionQuality: compressionQuality,
          format: format,
          useQrCodeScanner: useQrCodeScanner,
          useTextRecognizer: useTextRecognizer,
          color: color,
          modalPresentationStyle: modalPresentationStyle,
          // Android options
          pageLimit: pageLimit,
          recognizerTextAndroid: recognizerTextAndroid,
          formatAndroid: formatAndroid,
          isGalleryImport: isGalleryImport,
          scannerMode: scannerMode,
          // Callbacks for updating options
          onIOSOptionsChanged: (
            newCompressionQuality,
            newFormat,
            newUseQrCodeScanner,
            newUseTextRecognizer,
            newColor,
            newModalStyle,
          ) {
            setState(() {
              compressionQuality = newCompressionQuality;
              format = newFormat;
              useQrCodeScanner = newUseQrCodeScanner;
              useTextRecognizer = newUseTextRecognizer;
              color = newColor;
              modalPresentationStyle = newModalStyle;
            });
          },
          onAndroidOptionsChanged: (
            newPageLimit,
            newRecognizerText,
            newFormat,
            newIsGalleryImport,
            newScannerMode,
          ) {
            setState(() {
              pageLimit = newPageLimit;
              recognizerTextAndroid = newRecognizerText;
              formatAndroid = newFormat;
              isGalleryImport = newIsGalleryImport;
              scannerMode = newScannerMode;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: processImageFromLibrary,
            tooltip: 'Import from gallery',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsScreen,
            tooltip: 'Scanner Settings',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: imageData.isEmpty
                ? null
                : () => setState(() => imageData.clear()),
            tooltip: 'Clear results',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: scan,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : imageData.isEmpty
              ? const Center(child: Text('No documents scanned yet'))
              : ScanResultsList(imageData: imageData),
    );
  }
}

class ScanResultsList extends StatelessWidget {
  final List<CustomScanResult> imageData;

  const ScanResultsList({super.key, required this.imageData});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: imageData.length,
      itemBuilder: (context, index) {
        final result = imageData[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ExpansionTile(
            title: Text('Document ${index + 1}'),
            leading: SizedBox(
              width: 60,
              child: Image.memory(
                result.imagesBytes,
                fit: BoxFit.cover,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.memory(
                        result.imagesBytes,
                        width: 250,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (result.imagePath != null) ...[
                      const Text('Image Path:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(result.imagePath!,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                    ],
                    if (result.text != null && result.text!.isNotEmpty) ...[
                      const Text('Recognized Text:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(result.text!),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (result.qrCode != null && result.qrCode!.isNotEmpty) ...[
                      const Text('QR Code Content:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(result.qrCode!),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ConfigurationScreen extends StatefulWidget {
  // iOS options
  final double compressionQuality;
  final DocScanKitFormat format;
  final bool useQrCodeScanner;
  final bool useTextRecognizer;
  final Color color;
  final ModalPresentationStyleIOS modalPresentationStyle;

  // Android options
  final int pageLimit;
  final bool recognizerTextAndroid;
  final DocScanKitFormat formatAndroid;
  final bool isGalleryImport;
  final ScannerModeAndroid scannerMode;

  // Callbacks
  final Function(
    double compressionQuality,
    DocScanKitFormat format,
    bool useQrCodeScanner,
    bool useTextRecognizer,
    Color color,
    ModalPresentationStyleIOS modalPresentationStyle,
  ) onIOSOptionsChanged;

  final Function(
    int pageLimit,
    bool recognizerTextAndroid,
    DocScanKitFormat formatAndroid,
    bool isGalleryImport,
    ScannerModeAndroid scannerMode,
  ) onAndroidOptionsChanged;

  const ConfigurationScreen({
    super.key,
    required this.compressionQuality,
    required this.format,
    required this.useQrCodeScanner,
    required this.useTextRecognizer,
    required this.color,
    required this.modalPresentationStyle,
    required this.pageLimit,
    required this.recognizerTextAndroid,
    required this.formatAndroid,
    required this.isGalleryImport,
    required this.scannerMode,
    required this.onIOSOptionsChanged,
    required this.onAndroidOptionsChanged,
  });

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Local state variables
  late double _compressionQuality;
  late DocScanKitFormat _format;
  late bool _useQrCodeScanner;
  late bool _useTextRecognizer;
  late Color _color;
  late ModalPresentationStyleIOS _modalPresentationStyle;

  late int _pageLimit;
  late bool _recognizerTextAndroid;
  late DocScanKitFormat _formatAndroid;
  late bool _isGalleryImport;
  late ScannerModeAndroid _scannerMode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize with widget values
    _compressionQuality = widget.compressionQuality;
    _format = widget.format;
    _useQrCodeScanner = widget.useQrCodeScanner;
    _useTextRecognizer = widget.useTextRecognizer;
    _color = widget.color;
    _modalPresentationStyle = widget.modalPresentationStyle;

    _pageLimit = widget.pageLimit;
    _recognizerTextAndroid = widget.recognizerTextAndroid;
    _formatAndroid = widget.formatAndroid;
    _isGalleryImport = widget.isGalleryImport;
    _scannerMode = widget.scannerMode;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Configuration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'iOS',
              icon: Icon(Icons.apple),
            ),
            Tab(
              text: 'Android',
              icon: Icon(Icons.android),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onIOSOptionsChanged(
                _compressionQuality,
                _format,
                _useQrCodeScanner,
                _useTextRecognizer,
                _color,
                _modalPresentationStyle,
              );
              widget.onAndroidOptionsChanged(
                _pageLimit,
                _recognizerTextAndroid,
                _formatAndroid,
                _isGalleryImport,
                _scannerMode,
              );
              Navigator.pop(context);
            },
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // iOS Configuration Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scanner Options',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Result Format',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButtonFormField<DocScanKitFormat>(
                  initialValue: _format,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _format = value);
                    }
                  },
                  items: DocScanKitFormat.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name),
                          ))
                      .toList(),
                ),
                SwitchListTile(
                  title: const Text('Use QR Code Scanner'),
                  subtitle: const Text('Detect QR codes in images'),
                  value: _useQrCodeScanner,
                  onChanged: (value) =>
                      setState(() => _useQrCodeScanner = value),
                ),
                SwitchListTile(
                  title: const Text('Use Text Recognizer'),
                  subtitle: const Text('Extract text from images'),
                  value: _useTextRecognizer,
                  onChanged: (value) =>
                      setState(() => _useTextRecognizer = value),
                ),
                const Divider(),
                const Text('Compression Quality',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _compressionQuality,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: _compressionQuality.toStringAsFixed(1),
                  onChanged: (value) =>
                      setState(() => _compressionQuality = value),
                ),
                const Divider(),
                const Text('Scanner Color',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _colorOption(Colors.orange),
                    _colorOption(Colors.blue),
                    _colorOption(Colors.green),
                    _colorOption(Colors.red),
                  ],
                ),
                const Divider(),
                const Text('Modal Presentation Style',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<ModalPresentationStyleIOS>(
                  initialValue: _modalPresentationStyle,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _modalPresentationStyle = value);
                    }
                  },
                  items: ModalPresentationStyleIOS.values
                      .map((style) => DropdownMenuItem(
                            value: style,
                            child: Text(style.toString().split('.').last),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // Android Configuration Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scanner Options',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Page Limit'),
                  subtitle: const Text('Maximum number of pages to scan'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _pageLimit > 1
                            ? () => setState(() => _pageLimit--)
                            : null,
                      ),
                      Text('$_pageLimit'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _pageLimit < 10
                            ? () => setState(() => _pageLimit++)
                            : null,
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: const Text('Text Recognition'),
                  subtitle: const Text('Extract text from scanned images'),
                  value: _recognizerTextAndroid,
                  onChanged: (value) =>
                      setState(() => _recognizerTextAndroid = value),
                ),
                SwitchListTile(
                  title: const Text('Use QR Code Scanner'),
                  subtitle: const Text('Detect QR codes in images'),
                  value: _useQrCodeScanner,
                  onChanged: (value) =>
                      setState(() => _useQrCodeScanner = value),
                ),
                const Text('Result Format',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<DocScanKitFormat>(
                  initialValue: _formatAndroid,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _formatAndroid = value);
                    }
                  },
                  items: DocScanKitFormat.values
                      .map((mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(mode.name),
                          ))
                      .toList(),
                ),
                SwitchListTile(
                  title: const Text('Gallery Import'),
                  subtitle: const Text('Allow importing from gallery'),
                  value: _isGalleryImport,
                  onChanged: (value) =>
                      setState(() => _isGalleryImport = value),
                ),
                const Divider(),
                const Text('Scanner Mode',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<ScannerModeAndroid>(
                  initialValue: _scannerMode,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _scannerMode = value);
                    }
                  },
                  items: ScannerModeAndroid.values
                      .map((mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(mode.toString().split('.').last),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _color = color),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _color == color ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}
