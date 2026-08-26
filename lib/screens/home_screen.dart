import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../dialogs/categoria_dialog.dart';
import '../dialogs/gasto_dialog.dart';
import '../dialogs/tarjeta_dialog.dart';
import '../models/app_data.dart';
import '../models/budget_item.dart';
import '../models/ingreso.dart';
import '../models/movimiento.dart';
import '../models/resumen_mensual.dart';
import '../models/resumen_financiero.dart';
import '../models/tarjeta_credito.dart';
import '../services/storage_service.dart';
import '../services/notificaciones_service.dart';
import '../services/ticket_scanner_service.dart';
import '../widgets/categoria_card.dart';
import '../widgets/grafica_gastos.dart';
import '../widgets/tarjeta_card.dart';

class BudgetHomePage extends StatefulWidget {
  const BudgetHomePage({super.key});

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  final StorageService _storageService = StorageService();
  final NotificacionesService _notificacionesService = NotificacionesService();
  final TicketScannerService _ticketScannerService = TicketScannerService();

  final List<Ingreso> ingresos = [];
  double _ingresoMensualManual = 0;

  double get ingresoMensual {
    final ingresosExtra = ingresos.fold<double>(
      0,
      (sum, ingreso) => sum + ingreso.monto,
    );
    return _ingresoMensualManual + ingresosExtra;
  }

  double metaAhorro = 0;

  double get totalGastado =>
      items.fold<double>(0, (sum, item) => sum + item.real);

  double get disponibleActual => ResumenFinanciero.efectivoDisponible(
    ingresos: ingresoMensual,
    reservaMensual: metaAhorro,
    movimientos: movimientos,
  );

  bool _esNombreReservadoParaReserva(String nombre) {
    final normalizado = nombre.trim().toLowerCase();
    const nombresReservados = {
      'ahorro',
      'meta ahorro',
      'meta de ahorro',
      'reserva',
      'reserva mensual',
    };
    return nombresReservados.contains(normalizado);
  }

  static List<BudgetItem> _crearCategoriasIniciales() {
    return [
      BudgetItem(categoria: 'Casa', presupuesto: 100.00, nota: 'Pago fijo'),
      BudgetItem(
        categoria: 'Pr\u00e9stamo Banco Cuscatl\u00e1n',
        presupuesto: 139.62,
        nota: 'Descuento planilla',
      ),
      BudgetItem(
        categoria: 'Tarjetas',
        presupuesto: 120.00,
        nota: 'No financiar saldo',
      ),
      BudgetItem(categoria: 'Gas / Transporte', presupuesto: 60.00),
      BudgetItem(categoria: 'Mascota', presupuesto: 20.00),
      BudgetItem(categoria: 'Personal', presupuesto: 40.00),
      BudgetItem(categoria: 'Servicios varios', presupuesto: 20.00),
      BudgetItem(
        categoria: 'Fondo colch\u00f3n',
        presupuesto: 70.00,
        nota: 'Hasta llegar a \$500',
      ),
      BudgetItem(
        categoria: 'Margen libre',
        presupuesto: -58.19,
        nota: 'Ajustar gastos variables',
      ),
    ];
  }

  final List<BudgetItem> items = _crearCategoriasIniciales();

  final List<TarjetaCredito> tarjetas = [];
  final List<Movimiento> movimientos = [];
  final List<ResumenMensual> historial = [];

  Future<void> cargarDatos() async {
    final AppData datos = await _storageService.cargarDatos();

    _ingresoMensualManual = datos.ingresoMensual;
    metaAhorro = datos.metaAhorro;

    // En el primer inicio no existe la clave de categorías todavía: en ese
    // caso se conservan las categorías iniciales. Una lista guardada vacía sí
    // se respeta, porque puede ser una decisión del usuario.
    if (datos.tieneItemsGuardados) {
      items
        ..clear()
        ..addAll(datos.items);
    }

    // Un pago de tarjeta no se añade como gasto de presupuesto: la compra ya
    // está en su categoría. Sí se descuenta del efectivo disponible cuando
    // se paga en efectivo, a partir de su movimiento.
    final cantidadCategoriasAntesDeLimpiar = items.length;
    items.removeWhere(
      (item) => item.categoria == 'Pago de tarjetas' && item.presupuesto == 0,
    );
    final seEliminoPagoDeTarjetaGenerado =
        items.length != cantidadCategoriasAntesDeLimpiar;

    historial
      ..clear()
      ..addAll(datos.historial);

    movimientos
      ..clear()
      ..addAll(datos.movimientos);

    ingresos
      ..clear()
      ..addAll(datos.ingresos);

    tarjetas
      ..clear()
      ..addAll(datos.tarjetas);

    final seGeneraronCortes = _generarCortesPendientes();

    for (final tarjeta in tarjetas) {
      await _notificacionesService.programarRecordatorios(tarjeta);
    }

    if (seGeneraronCortes || seEliminoPagoDeTarjetaGenerado) {
      await _guardarDatos();
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _guardarDatos() {
    return _storageService.guardarDatos(
      items: items,
      ingresos: ingresos,
      tarjetas: tarjetas,
      historial: historial,
      ingresoMensual: _ingresoMensualManual,
      metaAhorro: metaAhorro,
      movimientos: movimientos,
    );
  }

  bool _generarCortesPendientes() {
    final ahora = DateTime.now();
    var seGeneroCorte = false;

    for (final tarjeta in tarjetas) {
      if (!tarjeta.debeGenerarCorteAutomatico(ahora)) continue;
      tarjeta.generarCorte(fecha: ahora);
      seGeneroCorte = true;
    }

    return seGeneroCorte;
  }

  void _normalizarCategorias() {
    for (final item in items) {
      if (item.categoria == 'Ahorro colchÃ³n' ||
          item.categoria == 'Ahorro colchón') {
        item.categoria = 'Fondo colchon';
      }
    }
  }

  void editarIngreso() {
    final ingresoController = TextEditingController(
      text: _ingresoMensualManual.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar ingreso mensual'),
          content: TextField(
            controller: ingresoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Ingreso mensual'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nuevoIngreso = double.tryParse(ingresoController.text);

                if (nuevoIngreso == null || nuevoIngreso <= 0) {
                  return;
                }

                setState(() {
                  _ingresoMensualManual = nuevoIngreso;
                });

                _storageService.guardarDatos(
                  items: items,
                  ingresos: ingresos,
                  tarjetas: tarjetas,
                  historial: historial,
                  ingresoMensual: _ingresoMensualManual,
                  metaAhorro: metaAhorro,
                  movimientos: movimientos,
                );
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _normalizarCategorias();

    cargarDatos().then((_) {
      _normalizarCategorias();

      if (ingresoMensual == 0) {
        Future.delayed(Duration.zero, () {
          editarIngreso();
        });
      }
    });
  }

  void editarMetaAhorro() {
    final metaController = TextEditingController(
      text: metaAhorro.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar reserva mensual'),
          content: TextField(
            controller: metaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Reserva mensual',
              helperText: 'Se descuenta del disponible, no es una categoria.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nuevaMeta = double.tryParse(metaController.text);

                if (nuevaMeta == null || nuevaMeta < 0) return;

                setState(() {
                  metaAhorro = nuevaMeta;
                });

                _storageService.guardarDatos(
                  items: items,
                  ingresos: ingresos,
                  tarjetas: tarjetas,
                  historial: historial,
                  ingresoMensual: _ingresoMensualManual,
                  metaAhorro: metaAhorro,
                  movimientos: movimientos,
                );

                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> agregarCategoria() async {
    final resultado = await showCategoriaDialog(
      context: context,
      esNombreReservado: _esNombreReservadoParaReserva,
    );

    if (resultado == null) return;

    setState(() {
      items.add(
        BudgetItem(
          categoria: resultado.nombre,
          presupuesto: resultado.presupuesto,
        ),
      );
    });

    await _guardarDatos();
  }

  Future<void> editarCategoria(BudgetItem item) async {
    final resultado = await showCategoriaDialog(
      context: context,
      item: item,
      esNombreReservado: _esNombreReservadoParaReserva,
    );

    if (resultado == null) return;

    setState(() {
      item.categoria = resultado.nombre;
      item.presupuesto = resultado.presupuesto;
    });

    await _guardarDatos();
  }

  void eliminarCategoria(BudgetItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar categoría'),
          content: Text('¿Deseas eliminar "${item.categoria}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  items.remove(item);
                });

                _storageService.guardarDatos(
                  items: items,
                  ingresos: ingresos,
                  tarjetas: tarjetas,
                  historial: historial,
                  ingresoMensual: _ingresoMensualManual,
                  metaAhorro: metaAhorro,
                );
                Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> agregarTarjeta() async {
    final tarjeta = await showNuevaTarjetaDialog(context);

    if (tarjeta == null) return;

    setState(() {
      tarjetas.add(tarjeta);
    });

    await _notificacionesService.programarRecordatorios(tarjeta);
    await _guardarDatos();
  }

  Future<void> ajustarSaldoTarjeta(TarjetaCredito tarjeta) async {
    final nuevoSaldo = await showAjustarSaldoTarjetaDialog(
      context: context,
      tarjeta: tarjeta,
    );

    if (nuevoSaldo == null) return;

    setState(() {
      tarjeta.ajustarSaldo(nuevoSaldo);
    });

    await _guardarDatos();
  }

  Future<void> generarCorteTarjeta(TarjetaCredito tarjeta) async {
    setState(() {
      tarjeta.generarCorte();
    });
    await _guardarDatos();
  }

  void eliminarTarjeta(TarjetaCredito tarjeta) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar tarjeta'),
          content: Text('Deseas eliminar "${tarjeta.nombre}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                _notificacionesService.cancelarRecordatorios(tarjeta);
                setState(() {
                  tarjetas.remove(tarjeta);
                });

                _storageService.guardarDatos(
                  items: items,
                  ingresos: ingresos,
                  tarjetas: tarjetas,
                  historial: historial,
                  ingresoMensual: _ingresoMensualManual,
                  metaAhorro: metaAhorro,
                );
                Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> registrarPagoTarjeta(TarjetaCredito tarjeta) async {
    if (tarjeta.saldoActual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta tarjeta no tiene saldo pendiente.')),
      );
      return;
    }

    final pago = await showRegistrarPagoTarjetaDialog(
      context: context,
      tarjeta: tarjeta,
      tarjetas: tarjetas,
    );

    if (pago == null) return;

    setState(() {
      tarjeta.registrarPago(pago.monto);
      pago.tarjetaPago?.saldoActual += pago.monto;
      movimientos.insert(
        0,
        Movimiento(
          categoria: 'Pago de ${tarjeta.nombre}',
          monto: pago.monto,
          fecha: DateTime.now(),
          metodoPago: pago.tarjetaPago?.nombre ?? 'Efectivo',
        ),
      );
    });

    await _guardarDatos();
  }

  void reiniciarMes() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reiniciar mes'),
          content: const Text(
            'Esto pondrá todos los gastos reales en 0 y limpiará los movimientos. Las categorías se conservarán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  final ahora = DateTime.now();

                  final nombreMes = '${ahora.month}/${ahora.year}';

                  historial.insert(
                    0,
                    ResumenMensual(
                      mes: nombreMes,
                      gastado: totalGastado,
                      disponible: disponibleActual,
                    ),
                  );

                  for (final item in items) {
                    item.real = 0;
                  }

                  movimientos.clear();
                  ingresos.clear();
                });

                _storageService.guardarDatos(
                  items: items,
                  ingresos: ingresos,
                  tarjetas: tarjetas,
                  historial: historial,
                  ingresoMensual: _ingresoMensualManual,
                  metaAhorro: metaAhorro,
                  movimientos: movimientos,
                );
                Navigator.pop(context);
              },
              child: const Text('Reiniciar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> reiniciarTodosLosDatos() async {
    await _storageService.reiniciarTodosLosDatos();
    await _notificacionesService.cancelarTodosLosRecordatorios();

    if (!mounted) return;

    setState(() {
      _ingresoMensualManual = 0;
      metaAhorro = 0;
      ingresos.clear();
      tarjetas.clear();
      historial.clear();
      movimientos.clear();
      items
        ..clear()
        ..addAll(_crearCategoriasIniciales());
    });
  }

  void confirmarReinicioTotal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reiniciar todos los datos'),
          content: const Text(
            'Esto borrara ingresos, historial, movimientos y cambios en categorias. La app volvera a su estado inicial.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                await reiniciarTodosLosDatos();

                if (!context.mounted) return;
                Navigator.pop(context);

                Future.delayed(Duration.zero, () {
                  if (mounted) {
                    editarIngreso();
                  }
                });
              },
              child: const Text('Reiniciar todo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> mostrarFormularioGasto() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega una categoria antes de registrar un gasto.'),
        ),
      );
      return;
    }

    final resultado = await showGastoDialog(
      context: context,
      categorias: items,
      tarjetas: tarjetas,
      permitirTarjeta: false,
    );

    if (resultado == null) return;

    setState(() {
      resultado.categoria.real += resultado.monto;

      movimientos.insert(
        0,
        Movimiento(
          categoria: resultado.categoria.categoria,
          monto: resultado.monto,
          fecha: DateTime.now(),
          metodoPago: resultado.metodoPago,
        ),
      );
    });

    await _guardarDatos();
  }

  Future<void> mostrarFormularioGastoConTarjeta() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega una categoria antes de registrar un gasto.'),
        ),
      );
      return;
    }

    final resultado = await showGastoDialog(
      context: context,
      categorias: items,
      tarjetas: tarjetas,
    );

    if (resultado == null) return;

    setState(() {
      resultado.categoria.real += resultado.monto;
      resultado.tarjeta?.saldoActual += resultado.monto;

      movimientos.insert(
        0,
        Movimiento(
          categoria: resultado.categoria.categoria,
          monto: resultado.monto,
          fecha: DateTime.now(),
          metodoPago: resultado.metodoPago,
        ),
      );
    });

    await _guardarDatos();
  }

  Future<void> escanearTicket() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El escaneo de tickets está disponible en Android y iOS.',
          ),
        ),
      );
      return;
    }

    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origen == null || !mounted) return;

    try {
      final ticket = await _ticketScannerService.escanear(origen);
      if (ticket == null || !mounted) return;

      if (ticket.monto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos detectar el total. Ingresa el monto manualmente.',
            ),
          ),
        );
      }

      await mostrarFormularioGastoDesdeTicket(ticket.monto);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible leer el ticket. Intenta con una foto más clara.',
          ),
        ),
      );
    }
  }

  Future<void> mostrarFormularioGastoDesdeTicket(double? montoInicial) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega una categoría antes de registrar un gasto.'),
        ),
      );
      return;
    }

    final resultado = await showGastoDialog(
      context: context,
      categorias: items,
      tarjetas: tarjetas,
      montoInicial: montoInicial,
    );
    if (resultado == null) return;

    setState(() {
      resultado.categoria.real += resultado.monto;
      resultado.tarjeta?.saldoActual += resultado.monto;
      movimientos.insert(
        0,
        Movimiento(
          categoria: resultado.categoria.categoria,
          monto: resultado.monto,
          fecha: DateTime.now(),
          metodoPago: resultado.metodoPago,
        ),
      );
    });
    await _guardarDatos();
  }

  void agregarIngreso() {
    final montoController = TextEditingController();
    final notaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar ingreso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto'),
              ),
              TextField(
                controller: notaController,
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  hintText: 'Salario, horas extra, bono...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final monto = double.tryParse(montoController.text);
                final nota = notaController.text.trim();

                if (monto == null || monto <= 0) return;

                setState(() {
                  ingresos.insert(
                    0,
                    Ingreso(
                      monto: monto,
                      nota: nota.isEmpty ? 'Ingreso' : nota,
                      fecha: DateTime.now(),
                    ),
                  );
                });

                _storageService.guardarDatos(
                  items: items,
                  ingresos: ingresos,
                  tarjetas: tarjetas,
                  historial: historial,
                  ingresoMensual: _ingresoMensualManual,
                  metaAhorro: metaAhorro,
                );
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void eliminarIngreso(Ingreso ingreso) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar ingreso'),
          content: Text(
            '¿Deseas eliminar "${ingreso.nota}" por \$${ingreso.monto.toStringAsFixed(2)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  ingresos.remove(ingreso);
                });

                _storageService.guardarDatos(
                  items: items,
                  ingresos: ingresos,
                  tarjetas: tarjetas,
                  historial: historial,
                  ingresoMensual: _ingresoMensualManual,
                  metaAhorro: metaAhorro,
                );
                Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalReal = totalGastado;
    final disponible = disponibleActual;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: false,
        title: Row(
          children: [
            Image.asset('assets/images/Logo.png', width: 32, height: 32),
            const SizedBox(width: 10),
            const Flexible(
            child: Text(
            'BFINANCE',
            overflow: TextOverflow.ellipsis,
            ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: agregarIngreso,
            icon: const Icon(Icons.attach_money),
          ),
          
          PopupMenuButton<String>(
    onSelected: (value) {
      if (value == 'tarjeta') {
        agregarTarjeta();
      }

      if (value == 'ticket') {
        escanearTicket();
      }

      if (value == 'mes') {
        reiniciarMes();
      }

      if (value == 'todo') {
        confirmarReinicioTotal();
      }
    },
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'tarjeta', child: Text('Agregar tarjeta')),
              PopupMenuItem<String>(value: 'ticket', child: Text('Escanear ticket')),
              PopupMenuItem<String>(value: 'mes', child: Text('Reiniciar mes')),
              PopupMenuItem<String>(
                value: 'todo',
                child: Text('Reiniciar todos los datos'),
              ),
            ],
          ),
          IconButton(
            onPressed: agregarCategoria,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF1D4ED8),
                  Color(0xFF1E40AF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const SizedBox(height: 8),
                Text(
                  '\$${disponible.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'La reserva mensual se descuenta del disponible y no funciona como categoria.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: editarIngreso,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ingreso ✎',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '\$${ingresoMensual.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gastado',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '\$${totalReal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: editarMetaAhorro,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ahorro ✎',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '\$${metaAhorro.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Text(
                            'Reserva mensual',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Grafica de gastos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GraficaGastos(items: items),
          const SizedBox(height: 16),
          const Text(
            'Categorías',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ...items.map((item) {
            return CategoriaCard(
              item: item,
              onEditar: () => editarCategoria(item),
              onEliminar: () => eliminarCategoria(item),
            );
          }),

          const SizedBox(height: 16),

          const Text(
            'Tarjetas de credito',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          if (tarjetas.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: Text(
                'Aun no has agregado tarjetas.',
                style: TextStyle(color: Colors.white70),
              ),
            ),

          ...tarjetas.map((tarjeta) {
            return TarjetaCard(
              tarjeta: tarjeta,
              onAjustarSaldo: () => ajustarSaldoTarjeta(tarjeta),
              onGenerarCorte: () => generarCorteTarjeta(tarjeta),
              onPagar: () => registrarPagoTarjeta(tarjeta),
              onEliminar: () => eliminarTarjeta(tarjeta),
            );
          }),

          const SizedBox(height: 16),

          const Text(
            'Ingresos extra',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          if (ingresos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: Text(
                'Aún no has agregado ingresos extra.',
                style: TextStyle(color: Colors.white70),
              ),
            ),

          ...ingresos.map((ingreso) {
            return Card(
              child: ListTile(
                title: Text(ingreso.nota),
                subtitle: Text(
                  '${ingreso.fecha.day}/${ingreso.fecha.month}/${ingreso.fecha.year}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\$${ingreso.monto.toStringAsFixed(2)}'),
                    IconButton(
                      onPressed: () => eliminarIngreso(ingreso),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          const Text(
            'Movimientos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          ...movimientos.map((m) {
            return Card(
              child: ListTile(
                title: Text(m.categoria),
                subtitle: Text(
                  '${m.fecha.day}/${m.fecha.month}/${m.fecha.year} - ${m.metodoPago}',
                ),
                trailing: Text('\$${m.monto.toStringAsFixed(2)}'),
              ),
            );
          }),

          const SizedBox(height: 16),

          const Text(
            'Historial mensual',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          ...historial.map((h) {
            return Card(
              child: ListTile(
                title: Text(h.mes),
                subtitle: Text('Gastado: \$${h.gastado.toStringAsFixed(2)}'),
                trailing: Text(
                  'Disponible: \$${h.disponible.toStringAsFixed(2)}',
                ),
              ),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: mostrarFormularioGastoConTarjeta,
        child: const Icon(Icons.add),
      ),
    );
  }
}
