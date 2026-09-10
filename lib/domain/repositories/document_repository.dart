abstract interface class DocumentRepository {
  Future<String> readDocument(String documentId);
  Future<void> writeDocument({
    required String documentId,
    required String json,
    required String expectedRevision,
  });
}
