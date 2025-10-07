import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProductosTecnologicosScreen());
}

class ProductosTecnologicosScreen extends StatefulWidget {
  const ProductosTecnologicosScreen({super.key});

  @override
  State<ProductosTecnologicosScreen> createState() =>
      _ProductosTecnologicosScreenState();
}

class _ProductosTecnologicosScreenState
    extends State<ProductosTecnologicosScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  String? _tipoSeleccionado;
  bool _activo = true;

  final List<String> _tipos = [
    'Accesorio',
    'Dispositivo',
    'Componente',
  ];

  String? _idSeleccionado;
  List<Map<String, dynamic>> productos = [];

  @override
  void initState() {
    super.initState();
    readProductos();
  }

  // Crear producto
  Future<void> createProducto() async {
    if (!_formKey.currentState!.validate()) return;

    final datos = {
      'nombre': _nombreController.text,
      'marca': _marcaController.text,
      'precio': double.tryParse(_precioController.text) ?? 0.0,
      'stock': int.tryParse(_stockController.text) ?? 0,
      'tipo': _tipoSeleccionado,
      'activo': _activo,
    };

    try {
      await FirebaseFirestore.instance.collection('ProductosTecnologicos').add(datos);
      limpiarFormulario();
    } catch (e) {
      print('Error al crear producto: $e');
    }
  }

  // Leer productos
  Future<void> readProductos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('ProductosTecnologicos').get();
      setState(() {
        productos = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      print('Error al leer productos: $e');
    }
  }

  // Actualizar producto
  Future<void> updateProducto(String id) async {
    if (!_formKey.currentState!.validate()) return;

    final datos = {
      'nombre': _nombreController.text,
      'marca': _marcaController.text,
      'precio': double.tryParse(_precioController.text) ?? 0.0,
      'stock': int.tryParse(_stockController.text) ?? 0,
      'tipo': _tipoSeleccionado,
      'activo': _activo,
    };

    try {
      await FirebaseFirestore.instance
          .collection('ProductosTecnologicos')
          .doc(id)
          .update(datos);
      limpiarFormulario();
    } catch (e) {
      print('Error al actualizar producto: $e');
    }
  }

  // Eliminar producto
  Future<void> deleteProducto(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('ProductosTecnologicos')
          .doc(id)
          .delete();
      limpiarFormulario();
      readProductos();
    } catch (e) {
      print('Error al eliminar producto: $e');
    }
  }

  void limpiarFormulario() {
    setState(() {
      _nombreController.clear();
      _marcaController.clear();
      _precioController.clear();
      _stockController.clear();
      _tipoSeleccionado = null;
      _activo = true;
      _idSeleccionado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Productos Tecnológicos'),
          backgroundColor: const Color.fromARGB(122, 152, 120, 102),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre del producto'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el nombre del producto';
                    }
                    if (value.length < 3) {
                      return 'Debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Marca
                TextFormField(
                  controller: _marcaController,
                  decoration:
                      const InputDecoration(labelText: 'Marca del producto'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese la marca del producto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Precio
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese el precio';
                    final num? precio = num.tryParse(value);
                    if (precio == null || precio <= 0) {
                      return 'Debe ser un número positivo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Stock
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese el stock';
                    final num? stock = num.tryParse(value);
                    if (stock == null || stock <= 0) {
                      return 'Debe ser un número mayor que 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Tipo
                DropdownButtonFormField<String>(
                  value: _tipoSeleccionado,
                  items: _tipos
                      .map((tipo) =>
                          DropdownMenuItem(value: tipo, child: Text(tipo)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _tipoSeleccionado = val;
                    });
                  },
                  decoration:
                      const InputDecoration(labelText: 'Tipo de producto'),
                  validator: (value) =>
                      value == null ? 'Seleccione un tipo de producto' : null,
                ),
                const SizedBox(height: 10),

                // Estado
                SwitchListTile(
                  title: const Text('¿Activo?'),
                  value: _activo,
                  onChanged: (value) {
                    setState(() {
                      _activo = value;
                    });
                  },
                  secondary: Icon(
                    _activo ? Icons.check_circle : Icons.cancel,
                    color: _activo ? Colors.green : Colors.red,
                  ),
                ),

                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_idSeleccionado == null) {
                      createProducto();
                    } else {
                      updateProducto(_idSeleccionado!);
                    }
                  },
                  icon: Icon(
                      _idSeleccionado == null ? Icons.add : Icons.save),
                  label: Text(_idSeleccionado == null
                      ? 'Agregar Producto'
                      : 'Actualizar Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _idSeleccionado == null ? Colors.green : Colors.blue,
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 1),
                const SizedBox(height: 10),
                const Text(
                  'Lista de Productos Tecnológicos',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ProductosTecnologicos')
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
                            Text('No hay productos tecnológicos registrados.'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final producto = docs[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.computer),
                            title: Text(producto['nombre']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Marca: ${producto['marca']}'),
                                Text('Precio: S/. ${producto['precio']}'),
                                Text('Stock: ${producto['stock']}'),
                                Text('Tipo: ${producto['tipo']}'),
                                Text('Estado: ${producto['activo'] ? 'Activo' : 'Inactivo'}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    setState(() {
                                      _idSeleccionado = producto.id;
                                      _nombreController.text = producto['nombre'];
                                      _marcaController.text = producto['marca'];
                                      _precioController.text =
                                          producto['precio'].toString();
                                      _stockController.text =
                                          producto['stock'].toString();
                                      _tipoSeleccionado = producto['tipo'];
                                      _activo = producto['activo'];
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      deleteProducto(producto.id),
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
