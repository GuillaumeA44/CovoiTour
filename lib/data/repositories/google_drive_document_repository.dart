import '../../domain/repositories/document_repository.dart';

/// Point d'integration de Google Drive.
///
/// L'implementation concrete sera ajoutee apres configuration OAuth et des
/// revisions Drive. Les regles metier ne dependent pas de cette classe.
class GoogleDriveDocumentRepository implements DocumentRepository {
  @override
  Future<String> readDocument(String documentId) {
    throw UnimplementedError('Google Drive sera branche dans une etape dediee.');
  }

  @override
  Future<void> writeDocument({
    required String documentId,
    required String json,
    required String expectedRevision,
  }) {
    throw UnimplementedError('Google Drive sera branche dans une etape dediee.');
  }
}
