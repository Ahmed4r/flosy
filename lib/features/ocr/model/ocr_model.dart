class OcrParseResult {
  final double amount;
  final DateTime date;
  final String title;
  final String category;
  final String currency;
  final double confidence;

  OcrParseResult({
    required this.amount,
    required this.date,
    required this.title,
    required this.category,
    required this.currency,
    required this.confidence,
  });
}
