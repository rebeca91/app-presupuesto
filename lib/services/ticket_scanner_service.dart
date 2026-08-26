import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class TicketScanResult {
  const TicketScanResult({required this.monto, required this.texto});

  final double? monto;
  final String texto;
}

class TicketScannerService {
  TicketScannerService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<TicketScanResult?> escanear(ImageSource origen) async {
    final imagen = await _imagePicker.pickImage(
      source: origen,
      imageQuality: 85,
    );
    if (imagen == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final textoReconocido = await recognizer.processImage(
        InputImage.fromFilePath(imagen.path),
      );
      final texto = textoReconocido.text;
      return TicketScanResult(monto: extraerMonto(texto), texto: texto);
    } finally {
      await recognizer.close();
    }
  }

  static double? extraerMonto(String texto) {
    final lineas = texto.split(RegExp(r'\r?\n'));
    double? ultimoMonto;

    for (final linea in lineas) {
      final montos = _montosEn(linea);
      if (montos.isEmpty) continue;

      ultimoMonto = montos.last;
      if (RegExp(
        r'\b(total|importe|a pagar|pago)\b',
        caseSensitive: false,
      ).hasMatch(linea)) {
        return montos.last;
      }
    }

    return ultimoMonto;
  }

  static List<double> _montosEn(String texto) {
    final patron = RegExp(
      r'(?:US\$|USD|\$)?\s*([0-9]{1,3}(?:[.,][0-9]{3})*[.,][0-9]{2})',
      caseSensitive: false,
    );

    return patron
        .allMatches(texto)
        .map((match) => _convertirMonto(match.group(1)!))
        .whereType<double>()
        .toList();
  }

  static double? _convertirMonto(String valor) {
    final ultimaComa = valor.lastIndexOf(',');
    final ultimoPunto = valor.lastIndexOf('.');
    final separadorDecimal = ultimaComa > ultimoPunto ? ',' : '.';
    final sinMiles = valor.replaceAll(separadorDecimal == ',' ? '.' : ',', '');
    return double.tryParse(sinMiles.replaceAll(separadorDecimal, '.'));
  }
}
