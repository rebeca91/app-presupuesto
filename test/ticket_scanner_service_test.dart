import 'package:app_presupuesto/services/ticket_scanner_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prioriza el monto indicado como total', () {
    const ticket = 'Subtotal   \$8.50\nIVA        \$1.11\nTOTAL     \$9.61';

    expect(TicketScannerService.extraerMonto(ticket), 9.61);
  });

  test('interpreta montos con separadores de miles y coma decimal', () {
    const ticket = 'IMPORTE TOTAL: USD 1.234,56';

    expect(TicketScannerService.extraerMonto(ticket), 1234.56);
  });
}
