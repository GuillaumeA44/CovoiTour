import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../domain/repositories/document_repository.dart';

class GoogleDriveDocumentRepository implements DocumentRepository {
  GoogleDriveDocumentRepository(this._driveApi);

  final drive.DriveApi _driveApi;
  static const String _fileName = 'CovoiTour_data.json';

  @override
  Future<String> readDocument(String documentId) async {
    final fileId = await _findFileId();
    if (fileId == null) {
      throw Exception('Fichier non trouvé sur Google Drive.');
    }

    final response = await _driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> data = [];
    await for (final chunk in response.stream) {
      data.addAll(chunk);
    }
    return utf8.decode(data);
  }

  @override
  Future<void> writeDocument({
    required String documentId,
    required String json,
    required String expectedRevision,
  }) async {
    final fileId = await _findFileId();
    final media = drive.Media(
      Stream.value(utf8.encode(json)),
      json.length,
    );

    if (fileId == null) {
      // Création
      final driveFile = drive.File()
        ..name = _fileName
        ..mimeType = 'application/json';
      await _driveApi.files.create(driveFile, uploadMedia: media);
    } else {
      // Mise à jour
      final driveFile = drive.File();
      await _driveApi.files.update(
        driveFile,
        fileId,
        uploadMedia: media,
      );
    }
  }

  Future<String?> _findFileId() async {
    final list = await _driveApi.files.list(
      q: "name = '$_fileName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name, headRevisionId)',
    );
    if (list.files == null || list.files!.isEmpty) return null;
    return list.files!.first.id;
  }
  
  /// Récupère la révision actuelle pour la détection de conflit
  Future<String?> getLatestRevisionId() async {
    final list = await _driveApi.files.list(
      q: "name = '$_fileName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, headRevisionId)',
    );
    if (list.files == null || list.files!.isEmpty) return null;
    return list.files!.first.headRevisionId;
  }
}
