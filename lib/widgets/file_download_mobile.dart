import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Descarga un archivo en móvil/desktop y lo guarda en una ubicación accesible
Future<void> downloadFile(String url, String fileName) async {
  final response = await http.get(Uri.parse(url));
  
  if (response.statusCode == 200) {
    // En Android intentamos guardar en Downloads, en iOS en Documents
    Directory? directory;
    
    if (Platform.isAndroid) {
      // Intentar guardar en la carpeta de descargas externa
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback a documents si no existe
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      // iOS y otros
      directory = await getApplicationDocumentsDirectory();
    }
    
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    
    // Intentar abrir el archivo automáticamente
    try {
      await OpenFilex.open(filePath);
    } catch (_) {
      // Si no se puede abrir, no es error crítico
    }
  } else {
    throw Exception('Error descargando archivo: ${response.statusCode}');
  }
}

/// Descarga y retorna la ruta del archivo (útil para PDFs)
Future<String> downloadFileAndGetPath(String url, String fileName) async {
  final response = await http.get(Uri.parse(url));
  
  if (response.statusCode == 200) {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  } else {
    throw Exception('Error descargando archivo: ${response.statusCode}');
  }
}

/// Abre un archivo ya descargado
Future<void> openFile(String filePath) async {
  await OpenFilex.open(filePath);
}
