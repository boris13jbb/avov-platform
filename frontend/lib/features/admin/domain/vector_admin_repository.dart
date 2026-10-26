class RebuildCareersResult {
  const RebuildCareersResult({
    required this.collection,
    required this.indexed,
    required this.vectorSize,
    required this.source,
  });

  final String collection;
  final int indexed;
  final int vectorSize;
  final String source;

  factory RebuildCareersResult.fromJson(Map<String, dynamic> json) {
    final collection = json['collection'];
    final indexed = json['indexed'];
    final vectorSize = json['vector_size'];
    final source = json['source'];
    if (collection is! String ||
        indexed is! int ||
        vectorSize is! int ||
        source is! String) {
      throw const FormatException('Respuesta de reconstrucción incompleta');
    }
    return RebuildCareersResult(
      collection: collection,
      indexed: indexed,
      vectorSize: vectorSize,
      source: source,
    );
  }
}

abstract class VectorAdminRepository {
  Future<RebuildCareersResult> rebuildCareersIndex();
}
