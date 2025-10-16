/// Represents a complete line of text (may include text from multiple blocks)
class FullLineText {
  /// The full text of the line
  final String text;

  /// Average Y position of the top of the line
  final int avgTop;

  /// Average Y position of the bottom of the line
  final int avgBottom;

  /// Minimum X position (start of the line)
  final int minLeft;

  /// Maximum X position (end of the line)
  final int maxRight;

  FullLineText({
    required this.text,
    required this.avgTop,
    required this.avgBottom,
    required this.minLeft,
    required this.maxRight,
  });

  @override
  String toString() => text;
}

/// Represents the complete text recognition result
class TextRecognitionResult {
  /// The full recognized text
  final String text;

  /// List of recognized text blocks
  /// On iOS, this will be an empty list since Vision does not support block grouping
  final List<TextBlock> blocks;

  /// List of recognized text lines
  /// On iOS, lines are returned directly here (not inside blocks)
  /// On Android, this list will be empty as lines are inside blocks
  final List<TextLine> lines;

  TextRecognitionResult({
    required this.text,
    required this.blocks,
    List<TextLine>? lines,
  }) : lines = lines ?? [];

  factory TextRecognitionResult.fromMap(Map<dynamic, dynamic> map) {
    return TextRecognitionResult(
      text: map['text'] as String? ?? '',
      blocks: (map['blocks'] as List<dynamic>?)
              ?.map((e) => TextBlock.fromMap(e as Map<dynamic, dynamic>))
              .toList() ??
          [],
      lines: (map['lines'] as List<dynamic>?)
          ?.map((e) => TextLine.fromMap(e as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'blocks': blocks.map((e) => e.toMap()).toList(),
      'lines': lines.map((e) => e.toMap()).toList(),
    };
  }

  /// Extracts complete lines of text by grouping by Y position
  ///
  /// This method groups text lines from all blocks that are
  /// at the same height (Y position) into a single complete line.
  ///
  /// Parameters:
  /// - [yTolerance]: Tolerance in pixels to group lines at the same height (default: 10.0)
  ///
  /// Returns a list of [FullLineText] ordered from top to bottom.
  List<FullLineText> extractFullLines({double yTolerance = 10.0}) {
    // Collect all lines from all blocks and direct lines
    final List<_LineData> allLines = [];

    // Collect lines from blocks (Android)
    for (final block in blocks) {
      for (final line in block.lines) {
        if (line.rect != null && line.text.trim().isNotEmpty) {
          allLines.add(_LineData(
            text: line.text,
            rect: line.rect!,
            top: line.rect!.top,
            bottom: line.rect!.bottom,
            left: line.rect!.left,
            right: line.rect!.right,
          ));
        }
      }
    }

    // Collect direct lines (iOS)
    for (final line in lines) {
      if (line.rect != null && line.text.trim().isNotEmpty) {
        allLines.add(_LineData(
          text: line.text,
          rect: line.rect!,
          top: line.rect!.top,
          bottom: line.rect!.bottom,
          left: line.rect!.left,
          right: line.rect!.right,
        ));
      }
    }

    if (allLines.isEmpty) return [];

    // Group lines by Y position (with tolerance)
    final List<List<_LineData>> groupedLines = [];

    for (final line in allLines) {
      bool addedToGroup = false;

      for (final group in groupedLines) {
        final avgTop =
            group.map((l) => l.top).reduce((a, b) => a + b) / group.length;
        final avgBottom =
            group.map((l) => l.bottom).reduce((a, b) => a + b) / group.length;

        if ((line.top - avgTop).abs() < yTolerance &&
            (line.bottom - avgBottom).abs() < yTolerance) {
          group.add(line);
          addedToGroup = true;
          break;
        }
      }

      if (!addedToGroup) {
        groupedLines.add([line]);
      }
    }

    // Convert groups to FullLineText, sorting by horizontal position
    final List<FullLineText> fullLines = [];

    for (final group in groupedLines) {
      // Sort group lines from left to right
      group.sort((a, b) => a.left.compareTo(b.left));

      // Combine text
      final combinedText = group.map((l) => l.text.trim()).join(' ');

      // Calculate averages and limits
      final avgTop =
          (group.map((l) => l.top).reduce((a, b) => a + b) / group.length)
              .round();
      final avgBottom =
          (group.map((l) => l.bottom).reduce((a, b) => a + b) / group.length)
              .round();
      final minLeft = group.map((l) => l.left).reduce((a, b) => a < b ? a : b);
      final maxRight =
          group.map((l) => l.right).reduce((a, b) => a > b ? a : b);

      fullLines.add(FullLineText(
        text: combinedText,
        avgTop: avgTop,
        avgBottom: avgBottom,
        minLeft: minLeft,
        maxRight: maxRight,
      ));
    }

    // Sort complete lines from top to bottom
    fullLines.sort((a, b) => a.avgTop.compareTo(b.avgTop));

    return fullLines;
  }
}

/// Private helper class to store line data during extraction
class _LineData {
  final String text;
  final Rect rect;
  final int top;
  final int bottom;
  final int left;
  final int right;

  _LineData({
    required this.text,
    required this.rect,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });
}

/// Represents a text block
class TextBlock {
  /// The text of the block
  final String text;

  /// Corner points of the block (usually 4 points)
  final List<Point> points;

  /// Bounding rectangle
  final Rect? rect;

  /// Recognized languages
  final List<String> recognizedLanguages;

  /// Text lines within the block
  final List<TextLine> lines;

  /// Text angle (may be null)
  final double? angle;

  TextBlock({
    required this.text,
    required this.points,
    this.rect,
    required this.recognizedLanguages,
    required this.lines,
    this.angle,
  });

  factory TextBlock.fromMap(Map<dynamic, dynamic> map) {
    return TextBlock(
      text: map['text'] as String? ?? '',
      points: (map['points'] as List<dynamic>?)
              ?.map((e) => Point.fromMap(e as Map<dynamic, dynamic>))
              .toList() ??
          [],
      rect: map['rect'] != null
          ? Rect.fromMap(map['rect'] as Map<dynamic, dynamic>)
          : null,
      recognizedLanguages: (map['recognizedLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lines: (map['lines'] as List<dynamic>?)
              ?.map((e) => TextLine.fromMap(e as Map<dynamic, dynamic>))
              .toList() ??
          [],
      angle: (map['angle'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'points': points.map((e) => e.toMap()).toList(),
      'rect': rect?.toMap(),
      'recognizedLanguages': recognizedLanguages,
      'lines': lines.map((e) => e.toMap()).toList(),
      'angle': angle,
    };
  }
}

/// Represents a text line
class TextLine {
  /// The text of the line
  final String text;

  /// Corner points of the line
  final List<Point> points;

  /// Bounding rectangle
  final Rect? rect;

  /// Recognized languages
  final List<String> recognizedLanguages;

  /// Elements (words) within the line
  final List<TextElement> elements;

  /// Recognition confidence
  final double? confidence;

  /// Text angle
  final double? angle;

  TextLine({
    required this.text,
    required this.points,
    this.rect,
    required this.recognizedLanguages,
    required this.elements,
    this.confidence,
    this.angle,
  });

  factory TextLine.fromMap(Map<dynamic, dynamic> map) {
    return TextLine(
      text: map['text'] as String? ?? '',
      points: (map['points'] as List<dynamic>?)
              ?.map((e) => Point.fromMap(e as Map<dynamic, dynamic>))
              .toList() ??
          [],
      rect: map['rect'] != null
          ? Rect.fromMap(map['rect'] as Map<dynamic, dynamic>)
          : null,
      recognizedLanguages: (map['recognizedLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      elements: (map['elements'] as List<dynamic>?)
              ?.map((e) => TextElement.fromMap(e as Map<dynamic, dynamic>))
              .toList() ??
          [],
      confidence: (map['confidence'] as num?)?.toDouble(),
      angle: (map['angle'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'points': points.map((e) => e.toMap()).toList(),
      'rect': rect?.toMap(),
      'recognizedLanguages': recognizedLanguages,
      'elements': elements.map((e) => e.toMap()).toList(),
      'confidence': confidence,
      'angle': angle,
    };
  }
}

/// Represents a text element (usually a word)
class TextElement {
  /// The text of the element
  final String text;

  /// Corner points of the element
  final List<Point> points;

  /// Bounding rectangle
  final Rect? rect;

  /// Recognized languages
  final List<String> recognizedLanguages;

  /// Symbols (characters) within the element
  final List<TextSymbol> symbols;

  /// Recognition confidence
  final double? confidence;

  /// Text angle
  final double? angle;

  TextElement({
    required this.text,
    required this.points,
    this.rect,
    required this.recognizedLanguages,
    required this.symbols,
    this.confidence,
    this.angle,
  });

  factory TextElement.fromMap(Map<dynamic, dynamic> map) {
    return TextElement(
      text: map['text'] as String? ?? '',
      points: (map['points'] as List<dynamic>?)
              ?.map((e) => Point.fromMap(e as Map<dynamic, dynamic>))
              .toList() ??
          [],
      rect: map['rect'] != null
          ? Rect.fromMap(map['rect'] as Map<dynamic, dynamic>)
          : null,
      recognizedLanguages: (map['recognizedLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      symbols: (map['symbols'] as List<dynamic>?)
              ?.map((e) => TextSymbol.fromMap(e as Map<dynamic, dynamic>))
              .toList() ??
          [],
      confidence: (map['confidence'] as num?)?.toDouble(),
      angle: (map['angle'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'points': points.map((e) => e.toMap()).toList(),
      'rect': rect?.toMap(),
      'recognizedLanguages': recognizedLanguages,
      'symbols': symbols.map((e) => e.toMap()).toList(),
      'confidence': confidence,
      'angle': angle,
    };
  }
}

/// Represents a text symbol (usually a character)
class TextSymbol {
  /// The text of the symbol
  final String text;

  /// Corner points of the symbol
  final List<Point> points;

  /// Bounding rectangle
  final Rect? rect;

  /// Recognized languages
  final List<String> recognizedLanguages;

  /// Recognition confidence
  final double? confidence;

  /// Text angle
  final double? angle;

  TextSymbol({
    required this.text,
    required this.points,
    this.rect,
    required this.recognizedLanguages,
    this.confidence,
    this.angle,
  });

  factory TextSymbol.fromMap(Map<dynamic, dynamic> map) {
    return TextSymbol(
      text: map['text'] as String? ?? '',
      points: (map['points'] as List<dynamic>?)
              ?.map((e) => Point.fromMap(e as Map<dynamic, dynamic>))
              .toList() ??
          [],
      rect: map['rect'] != null
          ? Rect.fromMap(map['rect'] as Map<dynamic, dynamic>)
          : null,
      recognizedLanguages: (map['recognizedLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      confidence: (map['confidence'] as num?)?.toDouble(),
      angle: (map['angle'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'points': points.map((e) => e.toMap()).toList(),
      'rect': rect?.toMap(),
      'recognizedLanguages': recognizedLanguages,
      'confidence': confidence,
      'angle': angle,
    };
  }
}

/// Represents a 2D point
class Point {
  final int x;
  final int y;

  Point({required this.x, required this.y});

  factory Point.fromMap(Map<dynamic, dynamic> map) {
    return Point(
      x: map['x'] as int? ?? 0,
      y: map['y'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }
}

/// Represents a bounding rectangle
class Rect {
  final int left;
  final int top;
  final int right;
  final int bottom;

  Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory Rect.fromMap(Map<dynamic, dynamic> map) {
    return Rect(
      left: map['left'] as int? ?? 0,
      top: map['top'] as int? ?? 0,
      right: map['right'] as int? ?? 0,
      bottom: map['bottom'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }

  int get width => right - left;
  int get height => bottom - top;
}
