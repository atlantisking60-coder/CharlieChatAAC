class SymbolTile {
  String id;
  String label;
  String category;
  String imageAsset; // asset path or file path
  String emoji;
  String linkedBoardId;
  bool isBoardLink;
  bool isFullScreenImage;

  // Appearance
  double tileSize; // relative scale multiplier
  String bgColor; // hex like #ffffff
  String textColor; // hex

  // Custom voice
  String customVoice; // path to custom audio file

  // Spans for merging (grid units)
  int colSpan;
  int rowSpan;

  SymbolTile({
    required this.id,
    required this.label,
    required this.category,
    required this.imageAsset,
    this.emoji = '',
    this.linkedBoardId = '',
    this.isBoardLink = false,
    this.isFullScreenImage = false,
    this.tileSize = 1.0,
    this.bgColor = 'transparent',
    this.textColor = '#000000',
    this.customVoice = '',
    this.colSpan = 1,
    this.rowSpan = 1,
  });

  bool get speaks => !isBoardLink && !isFullScreenImage;

  String get speechText => speaks ? label : '';

  Map<String, dynamic> toMap() {
    var asset = imageAsset;
    // CRITICAL: Never persist session-specific blob URLs to storage.
    // They break immediately upon refresh.
    if (asset.startsWith('blob:')) {
      asset = '';
    }
    return {
      'id': id,
      'label': label,
      'category': category,
      'imageAsset': asset,
      'emoji': emoji,
      'linkedBoardId': linkedBoardId,
      'isBoardLink': isBoardLink,
      'isFullScreenImage': isFullScreenImage,
      'tileSize': tileSize,
      'bgColor': bgColor,
      'textColor': textColor,
      'customVoice': customVoice,
      'colSpan': colSpan,
      'rowSpan': rowSpan,
    };
  }

  factory SymbolTile.fromMap(Map<String, dynamic> m) => SymbolTile(
        id: m['id'] ?? '',
        label: m['label'] ?? '',
        category: m['category'] ?? 'Home',
        imageAsset: m['imageAsset'] ?? '',
        emoji: m['emoji'] ?? '',
        linkedBoardId: m['linkedBoardId'] ?? '',
        isBoardLink: m['isBoardLink'] ?? false,
        isFullScreenImage: m['isFullScreenImage'] ?? false,
        tileSize:
            (m['tileSize'] is num) ? (m['tileSize'] as num).toDouble() : 1.0,
        bgColor: m['bgColor'] ?? 'transparent',
        textColor: m['textColor'] ?? '#000000',
        customVoice: m['customVoice'] ?? '',
        colSpan: m['colSpan'] ?? 1,
        rowSpan: m['rowSpan'] ?? 1,
      );

  SymbolTile copyWith({
    String? id,
    String? label,
    String? category,
    String? imageAsset,
    String? emoji,
    String? linkedBoardId,
    bool? isBoardLink,
    bool? isFullScreenImage,
    double? tileSize,
    String? bgColor,
    String? textColor,
    String? customVoice,
    int? colSpan,
    int? rowSpan,
  }) {
    return SymbolTile(
      id: id ?? this.id,
      label: label ?? this.label,
      category: category ?? this.category,
      imageAsset: imageAsset ?? this.imageAsset,
      emoji: emoji ?? this.emoji,
      linkedBoardId: linkedBoardId ?? this.linkedBoardId,
      isBoardLink: isBoardLink ?? this.isBoardLink,
      isFullScreenImage: isFullScreenImage ?? this.isFullScreenImage,
      tileSize: tileSize ?? this.tileSize,
      bgColor: bgColor ?? this.bgColor,
      textColor: textColor ?? this.textColor,
      customVoice: customVoice ?? this.customVoice,
      colSpan: colSpan ?? this.colSpan,
      rowSpan: rowSpan ?? this.rowSpan,
    );
  }
}
