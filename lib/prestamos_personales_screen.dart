import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PrestamosPersonalesScreen());
}

class PrestamosPersonalesScreen extends StatefulWidget {
  const PrestamosPersonalesScreen({super.key});

  @override
  State<PrestamosPersonalesScreen> createState() =>
      _PrestamosPersonalesScreenState();
}

class _PrestamosPersonalesScreenState extends State<PrestamosPersonalesScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _cuotasController = TextEditingController();
  String? _estadoSeleccionado;

  final List<String> _estados = [
    'Activo',
    'Cancelado',
  ];

  String? _idSeleccionado;
  List<Map<String, dynamic>> prestamos = [];

  @override
  void initState() {
    super.initState();
    readPrestamos();
  }

  // Crear préstamo
  Future<void> createPrestamo() async {
    if (!_formKey.currentState!.validate()) return;

    final datos = {
      'nombre': _nombreController.text,
      'monto': double.tryParse(_montoController.text) ?? 0.0,
      'cuotas': int.tryParse(_cuotasController.text) ?? 0,
      'estado': _estadoSeleccionado,
    };

    try {
      await FirebaseFirestore.instance.collection('PrestamosPersonales').add(datos);
      limpiarFormulario();
    } catch (e) {
      print('Error al crear préstamo: $e');
    }
  }

  // Leer préstamos
  Future<void> readPrestamos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('PrestamosPersonales').get();
      setState(() {
        prestamos = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      print('Error al leer préstamos: $e');
    }
  }

  // Actualizar préstamo
  Future<void> updatePrestamo(String id) async {
    if (!_formKey.currentState!.validate()) return;

    final datos = {
      'nombre': _nombreController.text,
      'monto': double.tryParse(_montoController.text) ?? 0.0,
      'cuotas': int.tryParse(_cuotasController.text) ?? 0,
      'estado': _estadoSeleccionado,
    };

    try {
      await FirebaseFirestore.instance
          .collection('PrestamosPersonales')
          .doc(id)
          .update(datos);
      limpiarFormulario();
    } catch (e) {
      print('Error al actualizar préstamo: $e');
    }
  }

  // Eliminar préstamo
  Future<void> deletePrestamo(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('PrestamosPersonales')
          .doc(id)
          .delete();
      limpiarFormulario();
      readPrestamos();
    } catch (e) {
      print('Error al eliminar préstamo: $e');
    }
  }

  void limpiarFormulario() {
    setState(() {
      _nombreController.clear();
      _montoController.clear();
      _cuotasController.clear();
      _estadoSeleccionado = null;
      _idSeleccionado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Préstamos Personales'),
          backgroundColor: const Color.fromARGB(122, 152, 120, 102),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Nombre del cliente
                TextFormField(
                  controller: _nombreController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre del cliente'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el nombre del cliente';
                    }
                    if (value.length < 3) {
                      return 'Debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Monto
                TextFormField(
                  controller: _montoController,
                  decoration: const InputDecoration(labelText: 'Monto'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese el monto';
                    final num? monto = num.tryParse(value);
                    if (monto == null || monto <= 0) {
                      return 'Debe ser un número mayor a 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Número de cuotas
                TextFormField(
                  controller: _cuotasController,
                  decoration: const InputDecoration(labelText: 'Número de cuotas'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el número de cuotas';
                    }
                    final num? cuotas = num.tryParse(value);
                    if (cuotas == null || cuotas < 1) {
                      return 'Debe ser un número mayor o igual a 1';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Estado
                DropdownButtonFormField<String>(
                  value: _estadoSeleccionado,
                  items: _estados
                      .map((estado) =>
                          DropdownMenuItem(value: estado, child: Text(estado)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _estadoSeleccionado = val;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Estado del préstamo'),
                  validator: (value) =>
                      value == null ? 'Seleccione el estado del préstamo' : null,
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () {
                    if (_idSeleccionado == null) {
                      createPrestamo();
                    } else {
                      updatePrestamo(_idSeleccionado!);
                    }
                  },
                  icon: Icon(_idSeleccionado == null ? Icons.add : Icons.save),
                  label: Text(_idSeleccionado == null
                      ? 'Agregar Préstamo'
                      : 'Actualizar Préstamo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _idSeleccionado == null ? Colors.green : Colors.blue,
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 1),
                const SizedBox(height: 10),
                const Text(
                  'Lista de Préstamos Personales',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('PrestamosPersonales')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            Text('No hay préstamos personales registrados.'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final prestamo = docs[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.account_balance_wallet),
                            title: Text(prestamo['nombre']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Monto: S/. ${prestamo['monto']}'),
                                Text('Cuotas: ${prestamo['cuotas']}'),
                                Text('Estado: ${prestamo['estado']}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    setState(() {
                                      _idSeleccionado = prestamo.id;
                                      _nombreController.text =
                                          prestamo['nombre'];
                                      _montoController.text =
                                          prestamo['monto'].toString();
                                      _cuotasController.text =
                                          prestamo['cuotas'].toString();
                                      _estadoSeleccionado =
                                          prestamo['estado'];
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      deletePrestamo(prestamo.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}