import 'package:flutter/material.dart';
import 'models/budget_item.dart';
import 'models/movimiento.dart';
import 'models/ingreso.dart';
import 'models/tarjeta_credito.dart';
import 'models/resumen_mensual.dart';
import 'services/storage_service.dart';
import 'models/app_data.dart';
import 'widgets/categoria_card.dart';
import 'widgets/grafica_gastos.dart';
import 'widgets/tarjeta_card.dart';

void main() {
  runApp(const BudgetApp());
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Presupuesto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const BudgetHomePage(),
    );
  }
}

class BudgetHomePage extends StatefulWidget {
  const BudgetHomePage({super.key});

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  final StorageService _storageService = StorageService();

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

  double get disponibleActual => ingresoMensual - totalGastado - metaAhorro;

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

  List<BudgetItem> _crearCategoriasIniciales() {
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

  final List<BudgetItem> items = [
    BudgetItem(categoria: 'Casa', presupuesto: 100.00, nota: 'Pago fijo'),
    BudgetItem(
      categoria: 'Préstamo Banco Cuscatlán',
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
      categoria: 'Ahorro colchón',
      presupuesto: 70.00,
      nota: 'Hasta llegar a \$500',
    ),
    BudgetItem(
      categoria: 'Margen libre',
      presupuesto: -58.19,
      nota: 'Ajustar gastos variables',
    ),
  ];

  final List<TarjetaCredito> tarjetas = [];
  final List<Movimiento> movimientos = [];
  final List<ResumenMensual> historial = [];

  Future<void> cargarDatos() async {
    final AppData datos = await _storageService.cargarDatos();

    _ingresoMensualManual = datos.ingresoMensual;
    metaAhorro = datos.metaAhorro;

    items
      ..clear()
      ..addAll(datos.items);

    historial
      ..clear()
      ..addAll(datos.historial);

    ingresos
      ..clear()
      ..addAll(datos.ingresos);

    tarjetas
      ..clear()
      ..addAll(datos.tarjetas);

    if (!mounted) return;
    setState(() {});
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

    for (final item in items) {
      if (item.categoria == 'Ahorro colchÃ³n' ||
          item.categoria == 'Ahorro colchón') {
        item.categoria = 'Fondo colchon';
      }
    }

    cargarDatos().then((_) {
      for (final item in items) {
        if (item.categoria == 'Ahorro colchÃ³n' ||
            item.categoria == 'Ahorro colchón') {
          item.categoria = 'Fondo colchon';
        }
      }

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

  void agregarCategoria() {
    final nombreController = TextEditingController();
    final montoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva categoría'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Presupuesto'),
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
                final nombre = nombreController.text.trim();
                final monto = double.tryParse(montoController.text) ?? 0;

                if (nombre.isEmpty) return;
                if (_esNombreReservadoParaReserva(nombre)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ese nombre se usa para la reserva mensual. Usa otro nombre para la categoria.',
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  items.add(BudgetItem(categoria: nombre, presupuesto: monto));
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

  void editarCategoria(BudgetItem item) {
    final nombreController = TextEditingController(text: item.categoria);
    final montoController = TextEditingController(
      text: item.presupuesto.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar categoría'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Presupuesto'),
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
                final nombre = nombreController.text.trim();
                final monto = double.tryParse(montoController.text);

                if (nombre.isEmpty || monto == null) return;
                if (_esNombreReservadoParaReserva(nombre)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ese nombre se usa para la reserva mensual. Usa otro nombre para la categoria.',
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  item.categoria = nombre;
                  item.presupuesto = monto;
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

  void agregarTarjeta() {
    final nombreController = TextEditingController();
    final limiteController = TextEditingController();
    final saldoController = TextEditingController();
    final diaCorteController = TextEditingController();
    final diaPagoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva tarjeta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: limiteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Limite'),
                ),
                TextField(
                  controller: saldoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Saldo pendiente inicial',
                  ),
                ),
                TextField(
                  controller: diaCorteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Dia de corte'),
                ),
                TextField(
                  controller: diaPagoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Dia de pago'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nombre = nombreController.text.trim();
                final limite = double.tryParse(limiteController.text);
                final saldoInicial = double.tryParse(saldoController.text) ?? 0;
                final diaCorte = int.tryParse(diaCorteController.text);
                final diaPago = int.tryParse(diaPagoController.text);

                if (nombre.isEmpty ||
                    limite == null ||
                    limite <= 0 ||
                    saldoInicial < 0 ||
                    saldoInicial > limite ||
                    diaCorte == null ||
                    diaPago == null ||
                    diaCorte < 1 ||
                    diaCorte > 31 ||
                    diaPago < 1 ||
                    diaPago > 31) {
                  return;
                }

                setState(() {
                  tarjetas.add(
                    TarjetaCredito(
                      nombre: nombre,
                      limite: limite,
                      saldoActual: saldoInicial,
                      diaCorte: diaCorte,
                      diaPago: diaPago,
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

  void ajustarSaldoTarjeta(TarjetaCredito tarjeta) {
    final saldoController = TextEditingController(
      text: tarjeta.saldoActual.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajustar saldo de ${tarjeta.nombre}'),
          content: TextField(
            controller: saldoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Saldo pendiente'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nuevoSaldo = double.tryParse(saldoController.text);

                if (nuevoSaldo == null ||
                    nuevoSaldo < 0 ||
                    nuevoSaldo > tarjeta.limite) {
                  return;
                }

                setState(() {
                  tarjeta.saldoActual = nuevoSaldo;
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

  void registrarPagoTarjeta(TarjetaCredito tarjeta) {
    if (tarjeta.saldoActual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta tarjeta no tiene saldo pendiente.')),
      );
      return;
    }

    final montoController = TextEditingController(
      text: tarjeta.saldoActual.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pagar ${tarjeta.nombre}'),
          content: TextField(
            controller: montoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto a pagar'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final monto = double.tryParse(montoController.text);

                if (monto == null ||
                    monto <= 0 ||
                    monto > tarjeta.saldoActual) {
                  return;
                }

                setState(() {
                  tarjeta.saldoActual -= monto;
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
              child: const Text('Registrar pago'),
            ),
          ],
        );
      },
    );
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
              child: const Text('Reiniciar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> reiniciarTodosLosDatos() async {
    await _storageService.reiniciarTodosLosDatos();

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

  void mostrarFormularioGasto() {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega una categoria antes de registrar un gasto.'),
        ),
      );
      return;
    }

    final montoController = TextEditingController();
    BudgetItem categoriaSeleccionada = items.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<BudgetItem>(
                initialValue: categoriaSeleccionada,
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item.categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    categoriaSeleccionada = value;
                  }
                },
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              TextField(
                controller: montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto'),
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

                if (monto == null || monto <= 0) {
                  return;
                }

                setState(() {
                  categoriaSeleccionada.real += monto;

                  movimientos.insert(
                    0,
                    Movimiento(
                      categoria: categoriaSeleccionada.categoria,
                      monto: monto,
                      fecha: DateTime.now(),
                      metodoPago: 'Efectivo',
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

  void mostrarFormularioGastoConTarjeta() {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega una categoria antes de registrar un gasto.'),
        ),
      );
      return;
    }

    final montoController = TextEditingController();
    BudgetItem categoriaSeleccionada = items.first;
    String metodoPagoSeleccionado = 'Efectivo';
    TarjetaCredito? tarjetaSeleccionada = tarjetas.isNotEmpty
        ? tarjetas.first
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar gasto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<BudgetItem>(
                      initialValue: categoriaSeleccionada,
                      items: items.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item.categoria),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          categoriaSeleccionada = value;
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Monto'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: metodoPagoSeleccionado,
                      items: const [
                        DropdownMenuItem(
                          value: 'Efectivo',
                          child: Text('Efectivo'),
                        ),
                        DropdownMenuItem(
                          value: 'Tarjeta',
                          child: Text('Tarjeta de credito'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          metodoPagoSeleccionado = value;
                          if (metodoPagoSeleccionado == 'Tarjeta' &&
                              tarjetas.isNotEmpty) {
                            tarjetaSeleccionada ??= tarjetas.first;
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Metodo de pago',
                      ),
                    ),
                    if (metodoPagoSeleccionado == 'Tarjeta') ...[
                      const SizedBox(height: 12),
                      if (tarjetas.isEmpty)
                        const Text(
                          'Agrega una tarjeta antes de registrar compras con credito.',
                          style: TextStyle(color: Colors.white70),
                        )
                      else
                        DropdownButtonFormField<TarjetaCredito>(
                          initialValue: tarjetaSeleccionada,
                          items: tarjetas.map((tarjeta) {
                            return DropdownMenuItem(
                              value: tarjeta,
                              child: Text(tarjeta.nombre),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                tarjetaSeleccionada = value;
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Tarjeta',
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final monto = double.tryParse(montoController.text);

                    if (monto == null || monto <= 0) {
                      return;
                    }

                    if (metodoPagoSeleccionado == 'Tarjeta') {
                      final tarjeta = tarjetaSeleccionada;

                      if (tarjeta == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecciona una tarjeta valida.'),
                          ),
                        );
                        return;
                      }

                      if (tarjeta.saldoActual + monto > tarjeta.limite) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La compra supera el limite de la tarjeta.',
                            ),
                          ),
                        );
                        return;
                      }
                    }

                    setState(() {
                      categoriaSeleccionada.real += monto;

                      if (metodoPagoSeleccionado == 'Tarjeta' &&
                          tarjetaSeleccionada != null) {
                        tarjetaSeleccionada!.saldoActual += monto;
                      }

                      movimientos.insert(
                        0,
                        Movimiento(
                          categoria: categoriaSeleccionada.categoria,
                          monto: monto,
                          fecha: DateTime.now(),
                          metodoPago: metodoPagoSeleccionado == 'Tarjeta'
                              ? tarjetaSeleccionada!.nombre
                              : 'Efectivo',
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
      },
    );
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
        title: const Text(
          'Mi Presupuesto',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: agregarIngreso,
            icon: const Icon(Icons.attach_money),
          ),
          IconButton(
            onPressed: agregarTarjeta,
            icon: const Icon(Icons.credit_card),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mes') {
                reiniciarMes();
              }

              if (value == 'todo') {
                confirmarReinicioTotal();
              }
            },
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => const [
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
