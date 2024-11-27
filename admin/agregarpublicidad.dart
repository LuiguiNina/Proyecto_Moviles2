import 'dart:io';

import 'package:restmap/services/firestore_service.dart';
import 'package:restmap/services/upload_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AddPublicityPage extends StatefulWidget {
  const AddPublicityPage({Key? key}) : super(key: key);

  @override
  _AddPublicityPageState createState() => _AddPublicityPageState();
}

class _AddPublicityPageState extends State<AddPublicityPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _imageUrlController = TextEditingController();
  File? _image;
  bool _isImageUploaded = false;
  String _selectedStatus = 'Activo';

  Future<void> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        File imageFile = File(result.files.single.path!);
        String? imageName = await uploadPublicityImage(imageFile);
        if (imageName != null) {
          setState(() {
            _image = imageFile;
            _imageUrlController.text = imageName;
            _isImageUploaded = true;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Imagen subida exitosamente')));
          });
        }
      } else {
       
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> addPublicity() async {
    if (_imageUrlController.text.isEmpty || !_isImageUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, seleccione y suba una imagen.')));
      return;
    }

    await _firestoreService.addPublicity({
      'publimage': _imageUrlController.text,
      'estado': _selectedStatus == 'Activo',
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publicidad agregada exitosamente')));

    _clearForm();
  }

  void _clearForm() {
    _imageUrlController.clear();
    setState(() {
      _image = null;
      _isImageUploaded = false;
      _selectedStatus = 'Activo';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Publicidad'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _image == null
                ? Icon(Icons.image_not_supported, size: 150)
                : Image.file(_image!, height: 150, width: 150),
            ElevatedButton(
                onPressed: pickImage, child: Text('Seleccionar Imagen')),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStatus = newValue!;
                });
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
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: addPublicity, child: Text('Agregar Publicidad')),
          ],
        ),
      ),
    );
  }
}
