class ConversionHistory {
  final String id;
  final String type;
  final String inputPath;
  final String outputPath;
  final DateTime timestamp;

  ConversionHistory({
    required this.id,
    required this.type,
    required this.inputPath,
    required this.outputPath,
    required this.timestamp,
  });

  factory ConversionHistory.create({
    required String type,
    required String inputPath,
    required String outputPath,
  }) {
    return ConversionHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      inputPath: inputPath,
      outputPath: outputPath,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'inputPath': inputPath,
      'outputPath': outputPath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConversionHistory.fromJson(Map<String, dynamic> json) {
    return ConversionHistory(
      id: json['id'],
      type: json['type'],
      inputPath: json['inputPath'],
      outputPath: json['outputPath'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}