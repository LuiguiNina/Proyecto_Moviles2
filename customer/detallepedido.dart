import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restmap/views/customer/map_page.dart';

class DetallePedidoPage extends StatefulWidget {
  final String negocioId;
  final List<Map<String, dynamic>> productosSeleccionados;
  final double total;

  DetallePedidoPage({
    required this.negocioId,
    required this.productosSeleccionados,
    required this.total,
  });

  @override
  _DetallePedidoPageState createState() => _DetallePedidoPageState();
}

class _DetallePedidoPageState extends State<DetallePedidoPage> {
  String? _modalidadSeleccionada = 'delivery';
  String _nroCelular = '';
  String _direccion = '';
  String _notas = '';
  GeoPoint? _ubicacion;
  String? _metodoPagoSeleccionado = 'yape_plin'; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Pedido'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
  
            Text('Productos seleccionados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.productosSeleccionados.length,
              itemBuilder: (context, index) {
                var producto = widget.productosSeleccionados[index];
                return ListTile(
                  title: Text(producto['nombre']),
                  subtitle: Text('Cantidad: ${producto['cantidad']} - Precio: S/${producto['precio']}'),
                );
              },
            ),
            Divider(),
            Text('Total: S/${widget.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),

            Text('Modalidad de Pedido', style: TextStyle(fontSize: 18)),
            RadioListTile<String>(
              title: const Text('Delivery'),
              value: 'delivery',
              groupValue: _modalidadSeleccionada,
              onChanged: (String? value) {
                setState(() {
                  _modalidadSeleccionada = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Recojo en local'),
              value: 'recojo',
              groupValue: _modalidadSeleccionada,
              onChanged: (String? value) {
                setState(() {
                  _modalidadSeleccionada = value;
                });
              },
            ),
            const SizedBox(height: 16),


            TextField(
              decoration: InputDecoration(
                labelText: 'Número de celular',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                setState(() {
                  _nroCelular = value;
                });
              },
            ),
            const SizedBox(height: 16),

   
            if (_modalidadSeleccionada == 'delivery')
              TextField(
                decoration: InputDecoration(
                  labelText: 'Dirección (ej. Calle Los Alamos 530)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _direccion = value;
                  });
                },
              ),
            const SizedBox(height: 16),

  
            TextField(
              decoration: InputDecoration(
                labelText: 'Notas para el pedido',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _notas = value;
                });
              },
            ),
            const SizedBox(height: 16),


            if (_modalidadSeleccionada == 'delivery')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ubicación', style: TextStyle(fontSize: 18)),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPage(userId: widget.negocioId),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _ubicacion = result as GeoPoint;
                        });
                      }
                    },
                    child: Text('Seleccionar ubicación'),
                  ),
                ],
              ),
            if (_ubicacion != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Ubicación seleccionada: (${_ubicacion!.latitude}, ${_ubicacion!.longitude})'),
              ),
            const SizedBox(height: 16),

            Text('Método de Pago', style: TextStyle(fontSize: 18)),
            RadioListTile<String>(
              title: const Text('Yape/Plin'),
              value: 'yape_plin',
              groupValue: _metodoPagoSeleccionado,
              onChanged: (String? value) {
                setState(() {
                  _metodoPagoSeleccionado = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Efectivo'),
              value: 'efectivo',
              groupValue: _metodoPagoSeleccionado,
              onChanged: (String? value) {
                setState(() {
                  _metodoPagoSeleccionado = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Contraentrega'),
              value: 'contraentrega',
              groupValue: _metodoPagoSeleccionado,
              onChanged: (String? value) {
                setState(() {
                  _metodoPagoSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 16),


            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  print('Pedido guardado');
                },
                child: Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: Size(150, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
