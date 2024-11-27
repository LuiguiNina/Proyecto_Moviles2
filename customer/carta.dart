import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restmap/views/customer/detallepedido.dart';

class CartaPage extends StatefulWidget {
  final String negocioId;
  final String userId;

  CartaPage({required this.negocioId, required this.userId});

  @override
  _CartaPageState createState() => _CartaPageState();
}

class _CartaPageState extends State<CartaPage> {
  Map<String, int> selectedQuantities = {};
  Map<String, bool> showFullDescription = {};
  Map<String, List<Map<String, dynamic>>> productosPorCategoria = {};
  double total = 0.0;
  int totalProducts = 0;

  @override
  void initState() {
    super.initState();
    _loadProductosAgrupados();
  }

  Future<void> _loadProductosAgrupados() async {
    final cartaSnapshot = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .get();

    if (cartaSnapshot.exists) {
      var cartaData = cartaSnapshot.data();
      if (cartaData != null) {
        var productos = List<Map<String, dynamic>>.from(cartaData['carta'] ?? []);
        var categorias = List<Map<String, dynamic>>.from(cartaData['categoriasprod'] ?? []);
        _agruparProductosPorCategoria(productos, categorias);
      }
    }
  }

  Future<void> _agruparProductosPorCategoria(
      List<Map<String, dynamic>> productos, List<Map<String, dynamic>> categorias) async {
    Map<String, String> categoriaIdToNombre = {};

    for (var cat in categorias) {
      categoriaIdToNombre[cat['id']] = cat['nombre'];
    }

    Map<String, List<Map<String, dynamic>>> agrupados = {};

    for (var producto in productos) {
      String categoriaId = producto['catprod'] ?? 'Sin Categoría';
      String categoriaNombre = categoriaIdToNombre[categoriaId] ?? 'Sin Categoría';

      if (!agrupados.containsKey(categoriaNombre)) {
        agrupados[categoriaNombre] = [];
      }
      agrupados[categoriaNombre]!.add(producto);
    }

    setState(() {
      productosPorCategoria = agrupados;
    });
  }

  void _updateTotal() {
    total = 0.0;
    totalProducts = 0;
    selectedQuantities.forEach((key, value) {
      var producto = productosPorCategoria.values.expand((prod) => prod).firstWhere((p) => p['codigo'] == key);
      total += (producto['precio'] * value);
      totalProducts += value;
    });
    setState(() {});
  }

  void agregarProductoaCarrito() async {
    final carrito = selectedQuantities.entries.map((entry) {
      var producto = productosPorCategoria.values.expand((prod) => prod).firstWhere((p) => p['codigo'] == entry.key);
      return {
        'nombre': producto['nombre'],
        'cantidad': entry.value,
        'precio': producto['precio'],
      };
    }).toList();

    await FirebaseFirestore.instance.collection('usuarios').doc(widget.userId).update({
      'carrito': FieldValue.arrayUnion(carrito)
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallePedidoPage(
          negocioId: widget.negocioId,
          productosSeleccionados: carrito,
          total: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carta del Negocio'),
      ),
      body: Stack(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('negocios').doc(widget.negocioId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: Image.asset('assets/loadingbeli.gif', width: 100, height: 100));
              }

              var negocio = snapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    productosPorCategoria.isNotEmpty && productosPorCategoria.entries.first.value.isNotEmpty
                        ? Image.network(productosPorCategoria.entries.first.value[0]['urlImagen'],
                            width: double.infinity, height: 200, fit: BoxFit.cover)
                        : SizedBox(height: 200, child: Icon(Icons.store, size: 100)),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          negocio['logo'] != null
                              ? Image.network(negocio['logo'], width: 50, height: 50)
                              : Icon(Icons.store, size: 50),
                          SizedBox(width: 10),
                          Text(
                            negocio['nombre'],
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Dirección: ${negocio['direccion']}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Divider(),

                    productosPorCategoria.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: productosPorCategoria.entries.map((entry) {
                              String categoria = entry.key;
                              List<Map<String, dynamic>> productos = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      categoria,
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: productos.length,
                                    itemBuilder: (context, index) {
                                      var producto = productos[index];
                                      String codigoProducto = producto['codigo'];
                                      bool mostrarDescripcionCompleta = showFullDescription[codigoProducto] ?? false;

                                      int stock = producto['stock'];
                                      String estado = producto['estado'];
                                      int selectedQuantity = selectedQuantities[producto['codigo']] ?? 0;

                                      bool isAvailable = estado == 'disponible' || estado == 'promocion';
                                      bool isStockLimited = stock > 0;
                                      bool canAddMore = isStockLimited ? selectedQuantity < stock : true;

                                      return Card(
                                        margin: EdgeInsets.symmetric(vertical: 8),
                                        child: ListTile(
                                          leading: producto['urlImagen'] != null
                                              ? Image.network(producto['urlImagen'], width: 80, height: 80, fit: BoxFit.cover)
                                              : Icon(Icons.fastfood, size: 50),
                                          title: Text(producto['nombre']),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                producto['descripcion'],
                                                maxLines: mostrarDescripcionCompleta ? null : 2,
                                                overflow: mostrarDescripcionCompleta ? TextOverflow.visible : TextOverflow.ellipsis,
                                                textAlign: TextAlign.justify,
                                              ),
                                              if (producto['descripcion'].length > 50)
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      showFullDescription[codigoProducto] = !mostrarDescripcionCompleta;
                                                    });
                                                  },
                                                  child: Text(
                                                    mostrarDescripcionCompleta ? 'Leer menos' : 'Leer más',
                                                    style: TextStyle(color: Colors.blue),
                                                  ),
                                                ),
                                              Text('S/${producto['precio']}'),
                                              if (isStockLimited)
                                                Text('Stock: $stock', style: TextStyle(color: Colors.green)),
                                              if (estado == 'agotado')
                                                Text('Agotado', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                          trailing: isAvailable
                                              ? Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (selectedQuantity > 0)
                                                      IconButton(
                                                        icon: Icon(Icons.remove),
                                                        onPressed: () {
                                                          setState(() {
                                                            selectedQuantities[producto['codigo']] =
                                                                selectedQuantity - 1;
                                                            _updateTotal();
                                                          });
                                                        },
                                                      ),
                                                    Text('$selectedQuantity'),
                                                    IconButton(
                                                      icon: Icon(Icons.add),
                                                      onPressed: canAddMore
                                                          ? () {
                                                              setState(() {
                                                                selectedQuantities[producto['codigo']] =
                                                                    selectedQuantity + 1;
                                                                _updateTotal();
                                                              });
                                                            }
                                                          : null,
                                                    ),
                                                  ],
                                                )
                                              : ElevatedButton(
                                                  onPressed: null,
                                                  child: Text(
                                                    'Agotado',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            }).toList(),
                          )
                        : Center(
                            child: Text('No hay productos disponibles'),
                          ),
                  ],
                ),
              );
            },
          ),

          
          if (total > 0)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalProducts producto(s)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'S/${total.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: agregarProductoaCarrito,
                      child: Text(
                        'Ordenar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


