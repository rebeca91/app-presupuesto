import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/tarjeta_credito.dart';

class NotificacionesService {
  NotificacionesService._();

  static final NotificacionesService _instancia = NotificacionesService._();
  static final FlutterLocalNotificationsPlugin _notificaciones =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _canalZonaHoraria = MethodChannel(
    'app_presupuesto/zona_horaria',
  );

  factory NotificacionesService() => _instancia;

  Future<void> inicializar() async {
    tz.initializeTimeZones();
    final zonaHoraria = await _obtenerZonaHoraria();
    tz.setLocalLocation(tz.getLocation(zonaHoraria));

    const configuracion = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notificaciones.initialize(settings: configuracion);

    await _notificaciones
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _notificaciones
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> programarRecordatorios(TarjetaCredito tarjeta) async {
    await cancelarRecordatorios(tarjeta);
    if (!tarjeta.recordatoriosActivos) return;

    await _programarRecordatorio(
      id: _idNotificacion(tarjeta, 0),
      fecha: _proximaFecha(tarjeta.diaCorte),
      titulo: 'Corte de ${tarjeta.nombre}',
      mensaje: 'Hoy es la fecha de corte de tu tarjeta ${tarjeta.nombre}.',
    );
    await _programarRecordatorio(
      id: _idNotificacion(tarjeta, 1),
      fecha: _proximaFecha(
        tarjeta.diaPago,
        anticipacionDias: tarjeta.diasAnticipacionPago,
      ),
      titulo: 'Pago de ${tarjeta.nombre}',
      mensaje: tarjeta.diasAnticipacionPago == 0
          ? 'Hoy es la fecha de pago de tu tarjeta ${tarjeta.nombre}.'
          : 'Tu pago vence en ${tarjeta.diasAnticipacionPago} ${tarjeta.diasAnticipacionPago == 1 ? 'día' : 'días'}.',
    );
  }

  Future<void> cancelarRecordatorios(TarjetaCredito tarjeta) async {
    await _notificaciones.cancel(id: _idNotificacion(tarjeta, 0));
    await _notificaciones.cancel(id: _idNotificacion(tarjeta, 1));
  }

  Future<void> cancelarTodosLosRecordatorios() => _notificaciones.cancelAll();

  Future<String> _obtenerZonaHoraria() async {
    try {
      return await _canalZonaHoraria.invokeMethod<String>('obtener') ??
          'America/El_Salvador';
    } on PlatformException {
      return 'America/El_Salvador';
    } on MissingPluginException {
      return 'America/El_Salvador';
    }
  }

  Future<void> _programarRecordatorio({
    required int id,
    required tz.TZDateTime fecha,
    required String titulo,
    required String mensaje,
  }) {
    return _notificaciones.zonedSchedule(
      id: id,
      title: titulo,
      body: mensaje,
      scheduledDate: fecha,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'recordatorios_tarjetas',
          'Recordatorios de tarjetas',
          channelDescription: 'Avisos de corte y pago de tarjetas de crédito',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  tz.TZDateTime _proximaFecha(int dia, {int anticipacionDias = 0}) {
    final ahora = tz.TZDateTime.now(tz.local);
    var fecha = _fechaConDiaValido(ahora.year, ahora.month, dia);
    if (!fecha.subtract(Duration(days: anticipacionDias)).isAfter(ahora)) {
      fecha = _fechaConDiaValido(ahora.year, ahora.month + 1, dia);
    }
    return fecha.subtract(Duration(days: anticipacionDias));
  }

  tz.TZDateTime _fechaConDiaValido(int year, int month, int dia) {
    final ultimoDiaDelMes = DateTime(year, month + 1, 0).day;
    return tz.TZDateTime(
      tz.local,
      year,
      month,
      dia.clamp(1, ultimoDiaDelMes),
      9,
    );
  }

  int _idNotificacion(TarjetaCredito tarjeta, int tipo) {
    var hash = 0;
    for (final codigo in tarjeta.nombre.codeUnits) {
      hash = (hash * 31 + codigo) & 0x3fffffff;
    }
    return hash * 2 + tipo;
  }
}
