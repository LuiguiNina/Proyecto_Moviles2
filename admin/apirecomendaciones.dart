import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ApirecomendacionesPage extends StatefulWidget {
  @override
  _ApirecomendacionesPageState createState() => _ApirecomendacionesPageState();
}

class _ApirecomendacionesPageState extends State<ApirecomendacionesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _metodoController;
  late TextEditingController _cantidadController;
  late TextEditingController _diasController;
  late TextEditingController _intervaloController;
  late String _hora;
  late Stream<DocumentSnapshot> _apiConfigStream;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Lima'));

    _apiConfigStream = _firestore.collection('apirecomendaciones').doc('config').snapshots();
    _metodoController = TextEditingController();
    _cantidadController = TextEditingController();
    _diasController = TextEditingController();
    _intervaloController = TextEditingController();
    _hora = "00:00:00 AM";
  }

  @override
  void dispose() {
    _metodoController.dispose();
    _cantidadController.dispose();
    _diasController.dispose();
    _intervaloController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      await _updateApiEjecucion();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Configuración guardada')));
    }
  }

  Future<void> _updateApiEjecucion() async {
    final now = tz.TZDateTime.now(tz.local);
    final selectedTime = DateFormat('hh:mm:ss a').parse(_hora);
    final formattedHora = DateFormat('hh:mm:ss a').format(selectedTime);

    final ultimaModificacion = now;
    final dias = int.parse(_diasController.text);
    final intervalo = int.parse(_intervaloController.text);
    final nextExecutionDate = ultimaModificacion.add(Duration(days: dias));
    final apiejecucion = DateTime(nextExecutionDate.year, nextExecutionDate.month, nextExecutionDate.day, selectedTime.hour, selectedTime.minute, selectedTime.second);
    final formattedApiEjecucion = DateFormat('yyyy-MM-dd hh:mm:ss a').format(apiejecucion);

    await _firestore.collection('apirecomendaciones').doc('config').set({
      'metodo': _metodoController.text,
      'cantidad': int.parse(_cantidadController.text),
      'dias': dias,
      'intervalo': intervalo,
      'hora': formattedHora,
      'apiejecucion': formattedApiEjecucion,
      'ultimamodif': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _rebootAPI() async {
    bool isApiConnected = await _checkApiConnection();
    if (isApiConnected) {
      try {
        await _firestore.collection('apirecomendaciones').doc('config').update({'estado': 'Reiniciando API'});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API reiniciada')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al reiniciar la API')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API apagada o sin conexión')));
    }
  }

Future<void> _generateCouponsForAll() async {
  bool isApiConnected = await _checkApiConnection();
  if (isApiConnected) {
    try {
      final url = 'http://161.132.49.197:3003/generate-coupons-all';
      print('Intentando acceder a: $url');
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cupones generados para todos los clientes')));
      } else {
        print('Error al generar cupones: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al generar cupones: ${response.statusCode}')));
      }
    } catch (e) {
      print('Error al generar cupones: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al generar cupones: $e')));
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API apagada o sin conexión')));
  }
}



Future<bool> _checkApiConnection() async {
  print('Verificando conexión a la API...');
  try {
    final response = await http.get(Uri.parse('http://161.132.49.197:3003/status')).timeout(Duration(seconds: 5));
    if (response.statusCode == 200) {
      print('Conexión exitosa');
      return true;
    } else {
      print('Error en la respuesta: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al verificar conexión de la API: $e');
  }
  return false;
}



  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _hora = DateFormat('hh:mm:ss a').format(DateTime(0, 1, 1, picked.hour, picked.minute));
        _updateApiEjecucion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración de API Recomendaciones'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _apiConfigStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar configuración'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No hay configuración disponible'));
          }

          final config = snapshot.data!.data() as Map<String, dynamic>;
          final ultimamodif = (config['ultimamodif'] as Timestamp?)?.toDate();
          final formattedUltimaModif = ultimamodif != null ? DateFormat('dd/MM/yyyy hh:mm a').format(ultimamodif) : 'Desconocido';

          _metodoController.text = config['metodo'] ?? '';
          _cantidadController.text = config['cantidad']?.toString() ?? '';
          _diasController.text = config['dias']?.toString() ?? '';
          _intervaloController.text = config['intervalo']?.toString() ?? '';
          _hora = config['hora'] ?? '00:00:00 AM';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _metodoController.text.isNotEmpty ? _metodoController.text : null,
                    items: [
                      DropdownMenuItem(value: 'pedidos', child: Text('Pedidos')),
                      DropdownMenuItem(value: 'productos', child: Text('Productos')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _metodoController.text = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Método (pedidos/productos)'),
                    validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: _cantidadController,
                    decoration: InputDecoration(labelText: 'Cantidad'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: _diasController,
                    decoration: InputDecoration(labelText: 'Intervalo de días'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: _intervaloController,
                    decoration: InputDecoration(labelText: 'Intervalo'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _selectTime(context),
                          child: Text('Seleccionar hora de ejecución'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveConfig,
                    child: Text('Guardar'),
                  ),
                  ElevatedButton(
                    onPressed: _rebootAPI,
                    child: Text('Reiniciar API'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _generateCouponsForAll,
                    child: Text('Generar Cupones a Todos los Clientes'),
                  ),
                  SizedBox(height: 20),
                  Text('Última modificación: $formattedUltimaModif'),
                  Text('Método: ${config['metodo']}'),
                  Text('Cantidad: ${config['cantidad']}'),
                  Text('Intervalo de días: ${config['dias']}'),
                  Text('Intervalo: ${config['intervalo']}'),
                  Text('Hora de ejecución: $_hora'),
                  Text('Próxima ejecución: ${config['apiejecucion'] ?? 'No disponible'}'),
                  SizedBox(height: 20),
                  Text('Estado de la API:', style: TextStyle(fontWeight: FontWeight.bold)),
                  StreamBuilder<String>(
                    stream: _apiStatusStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Cargando estado de la API...');
                      }

                      return Text(snapshot.data ?? 'Desconocido');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Stream<String> _apiStatusStream() async* {
    while (true) {
      await Future.delayed(Duration(seconds: 5));
      final docSnapshot = await _firestore.collection('apirecomendaciones').doc('config').get();
      yield docSnapshot.exists ? (docSnapshot.data()!['estado'] ?? 'Desconocido') : 'Desconocido';
    }
  }
}
