import 'dart:convert';

import '../../domain/entities/group.dart';

class CarpoolJsonCodec {
  String encode(CarpoolGroup group) => const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'document': group.toJson(),
      });

  Map<String, dynamic> decode(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic> || decoded['document'] is! Map<String, dynamic>) {
      throw const FormatException('Document CovoiTour invalide.');
    }
    return decoded;
  }
}
