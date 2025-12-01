import 'dart:html' as html;
import 'package:http/http.dart' as http;

/// Descarga un archivo en web usando anchor download
Future<void> downloadFile(String url, String fileName) async {
  // Abrir URL directamente para descargar
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..setAttribute('target', '_blank')
    ..click();
}

/// En web no aplica guardar path, solo descarga
Future<String> downloadFileAndGetPath(String url, String fileName) async {
  await downloadFile(url, fileName);
  return ''; // En web no hay path local
}

/// En web no aplica abrir archivo local
Future<void> openFile(String filePath) async {
  // No-op en web
}

/// Descarga con fetch y blob (alternativa si CORS está habilitado)
Future<void> downloadFileWithFetch(String url, String fileName) async {
  final response = await http.get(Uri.parse(url));
  
  if (response.statusCode == 200) {
    final blob = html.Blob([response.bodyBytes]);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    
    html.AnchorElement(href: blobUrl)
      ..setAttribute('download', fileName)
      ..click();
    
    html.Url.revokeObjectUrl(blobUrl);
  } else {
    throw Exception('Error descargando archivo: ${response.statusCode}');
  }
}
