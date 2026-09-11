import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/document_repository.dart';

class LocalDocumentRepository implements DocumentRepository {
  static const String _storageKeyPrefix = 'covoitour_doc_';

  @override
  Future<String> readDocument(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_storageKeyPrefix$documentId');
    if (json == null) {
      throw Exception('Document non trouvé localement : $documentId');
    }
    return json;
  }

  @override
  Future<void> writeDocument({
    required String documentId,
    required String json,
    required String expectedRevision,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Pour la version locale simple, on ne gère pas encore les révisions complexes
    // mais on pourrait stocker une métadonnée de révision.
    await prefs.setString('$_storageKeyPrefix$documentId', json);
    await prefs.setString('$_storageKeyPrefix${documentId}_rev', DateTime.now().millisecondsSinceEpoch.toString());
  }
  
  Future<bool> hasDocument(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_storageKeyPrefix$documentId');
  }
}
