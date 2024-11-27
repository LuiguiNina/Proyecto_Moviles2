import 'package:restmap/services/firestore_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class PublicityManagementPage extends StatefulWidget {
  @override
  _PublicityManagementPageState createState() =>
      _PublicityManagementPageState();
}

class _PublicityManagementPageState extends State<PublicityManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar Publicidad'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getPublicities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Algo salió mal'));
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            var publicities = snapshot.data!;
            return ListView.builder(
              itemCount: publicities.length,
              itemBuilder: (context, index) {
                var publicity = publicities[index];
                return FutureBuilder<String?>(
                  future: _getImageUrl(publicity['publimage'] ?? ''),
                  builder: (context, imageSnapshot) {
                    Widget imageWidget;
                    if (imageSnapshot.connectionState == ConnectionState.done &&
                        imageSnapshot.hasData) {
                      imageWidget = ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(imageSnapshot.data!,
                            fit: BoxFit.cover, width: 100, height: 100),
                      );
                    } else if (imageSnapshot.connectionState ==
                            ConnectionState.done &&
                        !imageSnapshot.hasData) {
                      imageWidget = Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.image_not_supported, size: 60),
                      );
                    } else {
                      imageWidget = Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CircularProgressIndicator(),
                      );
                    }
                    return ListTile(
                      title: Text('Publicidad ${index + 1}'),
                      subtitle: Text(
                          'Estado: ${publicity['estado'] == true ? 'Activo' : 'Inactivo'}'),
                      leading: imageWidget,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editPublicity(publicity),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await _firestoreService
                                  .deletePublicity(publicity['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return Center(child: Text('No hay publicidades disponibles'));
          }
        },
      ),
    );
  }

  Future<String?> _getImageUrl(String imageName) async {
    if (imageName.isEmpty) {
      print("No image name provided, returning null.");
      return null;
    }
    try {
      var ref = _storage.ref('publicidad/$imageName');
      var url = await ref.getDownloadURL();
      print("Download URL for $imageName: $url");
      return url;
    } catch (e) {
      print('Error al cargar la imagen: $e');
      return null;
    }
  }

  void _editPublicity(Map<String, dynamic> publicity) {
    String estado = publicity['estado'] ? 'Activo' : 'Inactivo';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Publicidad'),
          content: DropdownButtonFormField<String>(
            value: estado,
            onChanged: (String? newValue) {
              estado = newValue!;
            },
            items: ['Activo', 'Inactivo']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            decoration: InputDecoration(labelText: 'Estado'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Actualizar'),
              onPressed: () {
                _firestoreService.updatePublicity(
                    publicity['id'], {'estado': estado == 'Activo'});
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
