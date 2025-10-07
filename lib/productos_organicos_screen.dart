import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProductosOrganicosScreen());
}

class ProductosOrganicosScreen extends StatefulWidget {
  const ProductosOrganicosScreen({super.key});

  @override
  State<ProductosOrganicosScreen> createState() =>
      _ProductosOrganicosScreenState();
}

class _ProductosOrganicosScreenState extends State<ProductosOrganicosScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  String? _categoriaSeleccionada;

  final List<String> _categorias = [
    'Fruta',
    'Verdura',
    'Bebida',
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
      'categoria': _categoriaSeleccionada,
      'precio': double.tryParse(_precioController.text) ?? 0.0,
      'ciudad': _ciudadController.text,
    };

    try {
      await FirebaseFirestore.instance.collection('ProductosOrganicos').add(datos);
      limpiarFormulario();
    } catch (e) {
      print('Error al crear producto: $e');
    }
  }

  // Leer productos
  Future<void> readProductos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('ProductosOrganicos').get();
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
      'categoria': _categoriaSeleccionada,
      'precio': double.tryParse(_precioController.text) ?? 0.0,
      'ciudad': _ciudadController.text,
    };

    try {
      await FirebaseFirestore.instance
          .collection('ProductosOrganicos')
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
          .collection('ProductosOrganicos')
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
      _precioController.clear();
      _ciudadController.clear();
      _categoriaSeleccionada = null;
      _idSeleccionado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Productos Orgánicos'),
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

                // Categoría
                DropdownButtonFormField<String>(
                  value: _categoriaSeleccionada,
                  items: _categorias
                      .map((categoria) =>
                          DropdownMenuItem(value: categoria, child: Text(categoria)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _categoriaSeleccionada = val;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  validator: (value) =>
                      value == null ? 'Seleccione una categoría' : null,
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

                // Ciudad de origen
                TextFormField(
                  controller: _ciudadController,
                  decoration: const InputDecoration(labelText: 'Ciudad de origen'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese la ciudad de origen';
                    }
                    return null;
                  },
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
                  icon: Icon(_idSeleccionado == null ? Icons.add : Icons.save),
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
                  'Lista de Productos Orgánicos',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ProductosOrganicos')
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
                            Text('No hay productos orgánicos registrados.'),
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
                            leading: const Icon(Icons.eco),
                            title: Text(producto['nombre']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Categoría: ${producto['categoria']}'),
                                Text('Precio: S/. ${producto['precio']}'),
                                Text('Ciudad: ${producto['ciudad']}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon:
                                      const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    setState(() {
                                      _idSeleccionado = producto.id;
                                      _nombreController.text =
                                          producto['nombre'];
                                      _categoriaSeleccionada =
                                          producto['categoria'];
                                      _precioController.text =
                                          producto['precio'].toString();
                                      _ciudadController.text =
                                          producto['ciudad'];
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
