import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doc_scan_kit/doc_scan_kit.dart';
import 'package:image_picker/image_picker.dart';

class CustomScanResult {
  final Uint8List imagesBytes;
  final String? imagePath;
  String? text;
  TextRecognitionResult? detailedText;
  List<FullLineText>? fullLines;
  String? qrCode;

  CustomScanResult({
    required this.imagesBytes,
    this.imagePath,
    this.text,
    this.detailedText,
    this.fullLines,
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
  double compressionQuality = 0.2;
  bool saveImage = true;
  bool useQrCodeScanner = true;
  bool useTextRecognizer = false;
  bool useDetailedTextRecognition = true;
  Color color = Colors.orange;
  ModalPresentationStyle modalPresentationStyle =
      ModalPresentationStyle.overFullScreen;
  DocumentScanKitTextRecognitionOptionsiOS textRecognitionOptions =
      DocumentScanKitTextRecognitionOptionsiOS(
    recognitionLanguages: ['pt-BR', 'en-US', 'es-ES'],
    usesLanguageCorrection: true,
    recognitionLevel: RecognitionLevel.accurate,
  );

  // Android configuration options
  int pageLimit = 3;
  bool recognizerTextAndroid = false;
  bool saveImageAndroid = true;
  bool isGalleryImport = true;
  ScannerModeAndroid scannerMode = ScannerModeAndroid.full;

  List<CustomScanResult> imageData = [];
  bool isLoading = false;
  String? lastScanTime;

  Future<void> scan() async {
    DocScanKit instance = DocScanKit(
      iosOptions: DocumentScanKitOptionsiOS(
        compressionQuality: compressionQuality,
        saveImage: saveImage,
        color: color,
        modalPresentationStyle: modalPresentationStyle,
      ),
      androidOptions: DocumentScanKitOptionsAndroid(
        pageLimit: pageLimit,
        saveImage: saveImageAndroid,
        isGalleryImport: isGalleryImport,
        scannerMode: scannerMode,
      ),
    );
    try {
      setState(() => isLoading = true);

      final DateTime startTime = DateTime.now();
      final List<ScanResult> images = await instance.scanner();
      List<CustomScanResult> results = [];

      for (var image in images) {
        CustomScanResult customResult = CustomScanResult(
          imagesBytes: image.imagesBytes,
          imagePath: image.imagePath,
        );

        // Processing text recognition if enabled
        if (useDetailedTextRecognition) {
          try {
            customResult.detailedText = await instance.recognizeTextDetailed(
                image.imagesBytes, textRecognitionOptions);
            log('Detailed text recognition completed: ${customResult.detailedText?.blocks.length} blocks found');

            // Extract full lines
            customResult.fullLines =
                customResult.detailedText!.extractFullLines();
            log('Full lines extracted: ${customResult.fullLines?.length}');
            for (var fullLine in customResult.fullLines ?? []) {
              debugPrint('Full Line: ${fullLine.text}');
            }
          } catch (e) {
            debugPrint('Detailed text recognition failed: $e');
          }
        } else if ((recognizerTextAndroid && Platform.isAndroid) ||
            (useTextRecognizer && Platform.isIOS)) {
          try {
            customResult.text = await instance.recognizeText(
                image.imagesBytes, textRecognitionOptions);
          } catch (e) {
            debugPrint('Text recognition failed: $e');
          }
        }

        // Processing QR code if enabled
        if (useQrCodeScanner) {
          try {
            customResult.qrCode = await instance.scanQrCode(image.imagesBytes);
          } catch (e) {
            debugPrint('QR Code scanning failed: $e');
          }
        }

        results.add(customResult);
      }

      setState(() => imageData = results);

      final DateTime endTime = DateTime.now();
      final Duration duration = endTime.difference(startTime);
      final String timeString =
          '${duration.inSeconds}.${duration.inMilliseconds % 1000}s';
      setState(() => lastScanTime = timeString);
      debugPrint('Scan completed in $timeString');
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
        iosOptions: DocumentScanKitOptionsiOS(
          compressionQuality: compressionQuality,
          saveImage: saveImage,
          color: color,
          modalPresentationStyle: modalPresentationStyle,
        ),
        androidOptions: DocumentScanKitOptionsAndroid(
          pageLimit: pageLimit,
          saveImage: saveImageAndroid,
          isGalleryImport: isGalleryImport,
          scannerMode: scannerMode,
        ),
      );

      List<CustomScanResult> results = [];

      final DateTime startTime = DateTime.now();
      for (var selectedImage in selectedImages) {
        final Uint8List imageUint8List =
            Uint8List.fromList(await selectedImage.readAsBytes());

        CustomScanResult customResult = CustomScanResult(
          imagesBytes: imageUint8List,
          imagePath: selectedImage.path,
        );

        // Text recognition
        if (useDetailedTextRecognition) {
          try {
            customResult.detailedText = await instance.recognizeTextDetailed(
              imageUint8List,
              textRecognitionOptions,
            );
            log('Detailed text recognition completed: ${customResult.detailedText?.blocks.length} blocks found');
            for (TextBlock block in customResult.detailedText?.blocks ?? []) {
              for (var line in block.lines) {
                log('Line: ${line.text}');
              }
            }

            // Extrai linhas completas
            customResult.fullLines =
                customResult.detailedText!.extractFullLines();
            log('Full lines extracted: ${customResult.fullLines?.length}');
            for (var fullLine in customResult.fullLines ?? []) {
              log('Full Line: ${fullLine.text}');
            }
          } catch (e) {
            debugPrint('Detailed text recognition failed: $e');
          }
        } else if (useTextRecognizer) {
          try {
            customResult.text = await instance.recognizeText(
                imageUint8List, textRecognitionOptions);
            log('Recognized text: ${customResult.text}');
          } catch (e) {
            debugPrint('Text recognition failed: $e');
          }
        }

        // QR code detection
        if (useQrCodeScanner) {
          try {
            customResult.qrCode = await instance.scanQrCode(imageUint8List);
            log('QR Code content: ${customResult.qrCode}');
          } catch (e) {
            debugPrint('QR Code scanning failed: $e');
          }
        }

        results.add(customResult);
      }

      setState(() => imageData.addAll(results));

      final DateTime endTime = DateTime.now();
      final Duration duration = endTime.difference(startTime);
      final String timeString =
          '${duration.inSeconds}.${duration.inMilliseconds % 1000}s';
      setState(() => lastScanTime = timeString);
      debugPrint('Gallery processing completed in $timeString');

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
          saveImage: saveImage,
          useQrCodeScanner: useQrCodeScanner,
          useTextRecognizer: useTextRecognizer,
          useDetailedTextRecognition: useDetailedTextRecognition,
          color: color,
          modalPresentationStyle: modalPresentationStyle,
          // Android options
          pageLimit: pageLimit,
          recognizerTextAndroid: recognizerTextAndroid,
          saveImageAndroid: saveImageAndroid,
          isGalleryImport: isGalleryImport,
          scannerMode: scannerMode,
          // Callbacks for updating options
          onIOSOptionsChanged: (newCompressionQuality,
              newSaveImage,
              newUseQrCodeScanner,
              newUseTextRecognizer,
              newUseDetailedTextRecognition,
              newColor,
              newModalStyle) {
            setState(() {
              compressionQuality = newCompressionQuality;
              saveImage = newSaveImage;
              useQrCodeScanner = newUseQrCodeScanner;
              useTextRecognizer = newUseTextRecognizer;
              useDetailedTextRecognition = newUseDetailedTextRecognition;
              color = newColor;
              modalPresentationStyle = newModalStyle;
            });
          },
          onAndroidOptionsChanged: (newPageLimit, newRecognizerText,
              newSaveImage, newIsGalleryImport, newScannerMode) {
            setState(() {
              pageLimit = newPageLimit;
              recognizerTextAndroid = newRecognizerText;
              saveImageAndroid = newSaveImage;
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
              : Column(
                  children: [
                    if (lastScanTime != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Último scan levou: $lastScanTime',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Expanded(child: ScanResultsList(imageData: imageData)),
                  ],
                ),
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
                      child: result.detailedText != null
                          ? TextRecognitionOverlay(
                              imageBytes: result.imagesBytes,
                              detailedText: result.detailedText!,
                              maxWidth: 250,
                            )
                          : Image.memory(
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
                    if (result.detailedText != null) ...[
                      const Text('Detailed Text Recognition:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Text: ${result.detailedText!.text}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Blocks: ${result.detailedText!.blocks.length}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            ...result.detailedText!.blocks
                                .asMap()
                                .entries
                                .map((blockEntry) {
                              int blockIndex = blockEntry.key;
                              TextBlock block = blockEntry.value;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Block ${blockIndex + 1}: "${block.text}"',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '  Lines: ${block.lines.length}, Confidence per line: ${block.lines.map((line) => line.confidence?.toStringAsFixed(2) ?? "N/A").join(", ")}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600]),
                                    ),
                                    if (block.rect != null)
                                      Text(
                                        '  Rect: (${block.rect!.left}, ${block.rect!.top}) - (${block.rect!.right}, ${block.rect!.bottom})',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500]),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (result.fullLines != null &&
                        result.fullLines!.isNotEmpty) ...[
                      const Text('Full Lines:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              result.fullLines!.asMap().entries.map((entry) {
                            int index = entry.key;
                            FullLineText fullLine = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                'Lines ${index + 1}: ${fullLine.text}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                        ),
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
  final bool saveImage;
  final bool useQrCodeScanner;
  final bool useTextRecognizer;
  final bool useDetailedTextRecognition;
  final Color color;
  final ModalPresentationStyle modalPresentationStyle;

  // Android options
  final int pageLimit;
  final bool recognizerTextAndroid;
  final bool saveImageAndroid;
  final bool isGalleryImport;
  final ScannerModeAndroid scannerMode;

  // Callbacks
  final Function(double, bool, bool, bool, bool, Color, ModalPresentationStyle)
      onIOSOptionsChanged;
  final Function(int, bool, bool, bool, ScannerModeAndroid)
      onAndroidOptionsChanged;

  const ConfigurationScreen({
    super.key,
    required this.compressionQuality,
    required this.saveImage,
    required this.useQrCodeScanner,
    required this.useTextRecognizer,
    required this.useDetailedTextRecognition,
    required this.color,
    required this.modalPresentationStyle,
    required this.pageLimit,
    required this.recognizerTextAndroid,
    required this.saveImageAndroid,
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
  late bool _saveImage;
  late bool _useQrCodeScanner;
  late bool _useTextRecognizer;
  late bool _useDetailedTextRecognition;
  late Color _color;
  late ModalPresentationStyle _modalPresentationStyle;

  late int _pageLimit;
  late bool _recognizerTextAndroid;
  late bool _saveImageAndroid;
  late bool _isGalleryImport;
  late ScannerModeAndroid _scannerMode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize with widget values
    _compressionQuality = widget.compressionQuality;
    _saveImage = widget.saveImage;
    _useQrCodeScanner = widget.useQrCodeScanner;
    _useTextRecognizer = widget.useTextRecognizer;
    _useDetailedTextRecognition = widget.useDetailedTextRecognition;
    _color = widget.color;
    _modalPresentationStyle = widget.modalPresentationStyle;

    _pageLimit = widget.pageLimit;
    _recognizerTextAndroid = widget.recognizerTextAndroid;
    _saveImageAndroid = widget.saveImageAndroid;
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
                _saveImage,
                _useQrCodeScanner,
                _useTextRecognizer,
                _useDetailedTextRecognition,
                _color,
                _modalPresentationStyle,
              );
              widget.onAndroidOptionsChanged(
                _pageLimit,
                _recognizerTextAndroid,
                _saveImageAndroid,
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
                const Text('Scanner Options',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Save Image'),
                  subtitle: const Text('Save scanned image to gallery'),
                  value: _saveImage,
                  onChanged: (value) => setState(() => _saveImage = value),
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
                SwitchListTile(
                  title: const Text('Use Detailed Text Recognition'),
                  subtitle: const Text(
                      'Detailed recognition with blocks, lines, and coordinates (iOS & Android)'),
                  value: _useDetailedTextRecognition,
                  onChanged: (value) =>
                      setState(() => _useDetailedTextRecognition = value),
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
                DropdownButtonFormField<ModalPresentationStyle>(
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
                  items: ModalPresentationStyle.values
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
                const Text('Scanner Options',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                SwitchListTile(
                  title: const Text('Save Image'),
                  subtitle: const Text('Save scanned image to gallery'),
                  value: _saveImageAndroid,
                  onChanged: (value) =>
                      setState(() => _saveImageAndroid = value),
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

/// Widget que desenha contornos sobre a imagem com base no reconhecimento de texto
class TextRecognitionOverlay extends StatefulWidget {
  final Uint8List imageBytes;
  final TextRecognitionResult detailedText;
  final double maxWidth;

  const TextRecognitionOverlay({
    super.key,
    required this.imageBytes,
    required this.detailedText,
    required this.maxWidth,
  });

  @override
  State<TextRecognitionOverlay> createState() => _TextRecognitionOverlayState();
}

class _TextRecognitionOverlayState extends State<TextRecognitionOverlay> {
  ui.Image? _image;
  bool _showBlocks = false;
  bool _showLines = false;
  bool _showElements = false;
  bool _showFullLines = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _image = frame.image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return SizedBox(
        width: widget.maxWidth,
        height: widget.maxWidth,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final imageAspectRatio = _image!.width / _image!.height;
    final displayHeight = widget.maxWidth / imageAspectRatio;

    return Column(
      children: [
        // Controles de visualização
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            FilterChip(
              label: const Text('Blocks'),
              selected: _showBlocks,
              onSelected: (value) => setState(() => _showBlocks = value),
              selectedColor: Colors.blue.withValues(alpha: 0.3),
            ),
            FilterChip(
              label: const Text('Lines'),
              selected: _showLines,
              onSelected: (value) => setState(() => _showLines = value),
              selectedColor: Colors.green.withValues(alpha: 0.3),
            ),
            FilterChip(
              label: const Text('Elements'),
              selected: _showElements,
              onSelected: (value) => setState(() => _showElements = value),
              selectedColor: Colors.red.withValues(alpha: 0.5),
            ),
            FilterChip(
              label: const Text('Full Lines'),
              selected: _showFullLines,
              onSelected: (value) => setState(() => _showFullLines = value),
              selectedColor: Colors.purple.withValues(alpha: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Image with contours
        SizedBox(
          width: widget.maxWidth,
          height: displayHeight,
          child: CustomPaint(
            painter: TextBoundingBoxPainter(
              image: _image!,
              detailedText: widget.detailedText,
              showBlocks: _showBlocks,
              showLines: _showLines,
              showElements: _showElements,
              showFullLines: _showFullLines,
            ),
            child: Container(),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter drawing bounding boxes and polygons for text recognition results
class TextBoundingBoxPainter extends CustomPainter {
  final ui.Image image;
  final TextRecognitionResult detailedText;
  final bool showBlocks;
  final bool showLines;
  final bool showElements;
  final bool showFullLines;

  TextBoundingBoxPainter({
    required this.image,
    required this.detailedText,
    required this.showBlocks,
    required this.showLines,
    required this.showElements,
    required this.showFullLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.contain,
    );

    // Calculate the scale factor between the original image and the display size
    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;

    // Draw Full Lines (complete lines grouped by Y position)
    if (showFullLines) {
      _drawFullLines(canvas, scaleX, scaleY);
    }

    // Draw blocks (only Android - iOS does not support block grouping)
    if (showBlocks && detailedText.blocks.isNotEmpty) {
      final blockPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (final block in detailedText.blocks) {
        if (block.rect != null) {
          _drawRect(canvas, block.rect!, scaleX, scaleY, blockPaint);
        } else if (block.points.isNotEmpty) {
          _drawPolygon(canvas, block.points, scaleX, scaleY, blockPaint);
        }
      }
    }

    // Draw lines
    if (showLines) {
      final linePaint = Paint()
        ..color = Colors.green.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Android: lines within blocks
      for (final block in detailedText.blocks) {
        for (final line in block.lines) {
          if (line.rect != null) {
            _drawRect(canvas, line.rect!, scaleX, scaleY, linePaint);
          } else if (line.points.isNotEmpty) {
            _drawPolygon(canvas, line.points, scaleX, scaleY, linePaint);
          }
        }
      }

      // iOS: direct lines (outside of blocks)
      for (final line in detailedText.lines) {
        if (line.rect != null) {
          _drawRect(canvas, line.rect!, scaleX, scaleY, linePaint);
        } else if (line.points.isNotEmpty) {
          _drawPolygon(canvas, line.points, scaleX, scaleY, linePaint);
        }
      }
    }

    // Draw elements (words)
    if (showElements) {
      final elementPaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Android: elements within lines within blocks
      for (final block in detailedText.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            if (element.rect != null) {
              _drawRect(canvas, element.rect!, scaleX, scaleY, elementPaint);
            } else if (element.points.isNotEmpty) {
              _drawPolygon(
                  canvas, element.points, scaleX, scaleY, elementPaint);
            }
          }
        }
      }

      // iOS: elements within direct lines
      for (final line in detailedText.lines) {
        for (final element in line.elements) {
          if (element.rect != null) {
            _drawRect(canvas, element.rect!, scaleX, scaleY, elementPaint);
          } else if (element.points.isNotEmpty) {
            _drawPolygon(canvas, element.points, scaleX, scaleY, elementPaint);
          }
        }
      }
    }
  }

  /// Draws a scaled rectangle
  void _drawRect(
      Canvas canvas, Rect rect, double scaleX, double scaleY, Paint paint) {
    final scaledRect = ui.Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
    canvas.drawRect(scaledRect, paint);
  }

  /// Draws a polygon based on points
  void _drawPolygon(Canvas canvas, List<Point> points, double scaleX,
      double scaleY, Paint paint) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].x * scaleX, points[0].y * scaleY);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x * scaleX, points[i].y * scaleY);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  /// Draws complete lines grouped by Y position
  void _drawFullLines(Canvas canvas, double scaleX, double scaleY) {
    final fullLinePaint = Paint()
      ..color = Colors.purple.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Collect all lines from all blocks (Android)
    final List<_LineInfo> allLines = [];

    for (final block in detailedText.blocks) {
      for (final line in block.lines) {
        if (line.rect != null) {
          allLines.add(_LineInfo(
            rect: line.rect!,
            top: line.rect!.top,
            bottom: line.rect!.bottom,
          ));
        }
      }
    }

    // Collect direct lines (iOS)
    for (final line in detailedText.lines) {
      if (line.rect != null) {
        allLines.add(_LineInfo(
          rect: line.rect!,
          top: line.rect!.top,
          bottom: line.rect!.bottom,
        ));
      }
    }

    if (allLines.isEmpty) return;

    // Group lines by Y position (with tolerance for variations)
    const double yTolerance = 10.0; // Tolerance in pixels
    final List<List<_LineInfo>> groupedLines = [];

    for (final line in allLines) {
      bool addedToGroup = false;

      // Try to add to an existing group
      for (final group in groupedLines) {
        final avgTop =
            group.map((l) => l.top).reduce((a, b) => a + b) / group.length;
        final avgBottom =
            group.map((l) => l.bottom).reduce((a, b) => a + b) / group.length;

        // Check if the line is at the same "height" as the group
        if ((line.top - avgTop).abs() < yTolerance &&
            (line.bottom - avgBottom).abs() < yTolerance) {
          group.add(line);
          addedToGroup = true;
          break;
        }
      }

      // If not added to any group, create a new one
      if (!addedToGroup) {
        groupedLines.add([line]);
      }
    }

    // Draw a rectangle for each group of lines
    for (final group in groupedLines) {
      // Find the bounds of the group
      final minLeft =
          group.map((l) => l.rect.left).reduce((a, b) => a < b ? a : b);
      final maxRight =
          group.map((l) => l.rect.right).reduce((a, b) => a > b ? a : b);
      final minTop =
          group.map((l) => l.rect.top).reduce((a, b) => a < b ? a : b);
      final maxBottom =
          group.map((l) => l.rect.bottom).reduce((a, b) => a > b ? a : b);

      // Draw the rectangle
      final scaledRect = ui.Rect.fromLTRB(
        minLeft * scaleX,
        minTop * scaleY,
        maxRight * scaleX,
        maxBottom * scaleY,
      );
      canvas.drawRect(scaledRect, fullLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant TextBoundingBoxPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.detailedText != detailedText ||
        oldDelegate.showBlocks != showBlocks ||
        oldDelegate.showLines != showLines ||
        oldDelegate.showElements != showElements ||
        oldDelegate.showFullLines != showFullLines;
  }
}

/// Helper class to store line information for grouping
class _LineInfo {
  final Rect rect;
  final int top;
  final int bottom;

  _LineInfo({
    required this.rect,
    required this.top,
    required this.bottom,
  });
}
