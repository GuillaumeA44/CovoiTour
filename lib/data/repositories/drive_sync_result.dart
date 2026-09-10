class DriveRevisionConflict implements Exception {
  const DriveRevisionConflict(this.documentId);

  final String documentId;

  @override
  String toString() => 'Le document $documentId a ete modifie par un autre utilisateur.';
}

class DriveDocumentMetadata {
  const DriveDocumentMetadata({required this.documentId, required this.revision});

  final String documentId;
  final String revision;
}
