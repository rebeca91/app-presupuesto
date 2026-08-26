import 'package:flutter_test/flutter_test.dart';
import 'package:app_presupuesto/models/tarjeta_credito.dart';

void main() {
  test('genera saldo de ultimo corte y aplica pagos', () {
    final tarjeta = TarjetaCredito(
      nombre: 'BAC',
      limite: 1000,
      saldoActual: 120,
      saldoUltimoCorte: 0,
      diaCorte: 25,
      diaPago: 15,
    );

    tarjeta.generarCorte();

    expect(tarjeta.saldoUltimoCorte, 120);
    expect(tarjeta.consumoNuevo, 0);

    tarjeta.saldoActual += 80;

    expect(tarjeta.saldoActual, 200);
    expect(tarjeta.saldoUltimoCorte, 120);
    expect(tarjeta.consumoNuevo, 80);
    expect(tarjeta.creditoDisponible, 800);

    tarjeta.registrarPago(50);

    expect(tarjeta.saldoUltimoCorte, 70);
    expect(tarjeta.saldoActual, 150);
    expect(tarjeta.consumoNuevo, 80);
    expect(tarjeta.creditoDisponible, 850);

    tarjeta.registrarPago(70);

    expect(tarjeta.saldoUltimoCorte, 0);
    expect(tarjeta.saldoActual, 80);
    expect(tarjeta.consumoNuevo, 80);
    expect(tarjeta.creditoDisponible, 920);
  });

  test('genera el corte pendiente una vez por mes', () {
    final tarjeta = TarjetaCredito(
      nombre: 'BAC',
      limite: 1000,
      saldoActual: 250,
      saldoUltimoCorte: 0,
      diaCorte: 15,
      diaPago: 25,
    );
    final fechaDeCorte = DateTime(2026, 7, 15, 9);

    expect(tarjeta.debeGenerarCorteAutomatico(fechaDeCorte), isTrue);

    tarjeta.generarCorte(fecha: fechaDeCorte);

    expect(tarjeta.saldoUltimoCorte, 250);
    expect(tarjeta.debeGenerarCorteAutomatico(fechaDeCorte), isFalse);
    expect(
      tarjeta.debeGenerarCorteAutomatico(DateTime(2026, 8, 15, 9)),
      isTrue,
    );
  });

  test('ajustar saldo conserva la consistencia con el último corte', () {
    final tarjeta = TarjetaCredito(
      nombre: 'BAC',
      limite: 1000,
      saldoActual: 300,
      saldoUltimoCorte: 200,
      diaCorte: 15,
      diaPago: 25,
    );

    tarjeta.ajustarSaldo(120);

    expect(tarjeta.saldoActual, 120);
    expect(tarjeta.saldoUltimoCorte, 120);
    expect(tarjeta.consumoNuevo, 0);
  });

  test('un pago nunca descuenta más que el saldo actual', () {
    final tarjeta = TarjetaCredito(
      nombre: 'BAC',
      limite: 1000,
      saldoActual: 100,
      saldoUltimoCorte: 100,
      diaCorte: 15,
      diaPago: 25,
    );

    tarjeta.registrarPago(200);

    expect(tarjeta.saldoActual, 0);
    expect(tarjeta.saldoUltimoCorte, 0);
  });
}
