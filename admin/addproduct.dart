// import 'dart:io';

// import 'package:restmap/models/product.dart';
// import 'package:restmap/services/firestore_service.dart';
// import 'package:restmap/services/upload_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:uuid/uuid.dart';

// class AddProductPage extends StatefulWidget {
//   const AddProductPage({Key? key}) : super(key: key);

//   @override
//   _AddProductPageState createState() => _AddProductPageState();
// }

// class _AddProductPageState extends State<AddProductPage> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final TextEditingController _stockController = TextEditingController();
//   String _selectedStatus = 'disponible';
//   String? _selectedProductTypeId;
//   final TextEditingController _imageUrlController = TextEditingController();
//   final TextEditingController _idProdController = TextEditingController();
//   File? _image;
//   final List<String> _statusOptions = ['disponible', 'agotado', 'oferta'];
//   bool _isImageUploaded = false;

//   void _generateId() {
//     if (_nameController.text.isNotEmpty) {
//       var uuid = Uuid();
//       _idProdController.text = uuid.v4();
//     }
//   }

//   Future<void> pickImage() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//       );

//       if (result != null) {
//         File imageFile = File(result.files.single.path!);
//         String? imageName = await uploadImage(imageFile);
//         if (imageName != null) {
//           setState(() {
//             _image = imageFile;
//             _imageUrlController.text = imageName;
//             _isImageUploaded = true;
//             ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Image uploaded successfully')));
//           });
//         }
//       } else {
//         // El usuario canceló la selección
//         print('No image selected.');
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//     }
//   }

//   Future<void> addProduct() async {
//     if (_nameController.text.isEmpty ||
//         _descriptionController.text.isEmpty ||
//         _priceController.text.isEmpty ||
//         _stockController.text.isEmpty ||
//         _imageUrlController.text.isEmpty ||
//         _selectedProductTypeId == null ||
//         !_isImageUploaded) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text(
//               'Please fill in all fields, select an image, and ensure it is uploaded.')));
//       return;
//     }

//     if (_idProdController.text.isEmpty) {
//       var uuid = Uuid();
//       _idProdController.text = uuid.v4();
//     }

//     var newProduct = Product(
//       id: _idProdController.text,
//       name: _nameController.text,
//       description: _descriptionController.text,
//       price: double.parse(_priceController.text),
//       imageUrl: _imageUrlController.text,
//       status: _selectedStatus,
//       stock: int.parse(_stockController.text),
//       creationDate: Timestamp.now(),
//       refprod: FirebaseFirestore.instance
//           .collection('tipoproducto')
//           .doc(_selectedProductTypeId),
//     );

//     await _firestoreService.addProduct(newProduct.toFirestore());
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text('Product added successfully')));

//     _clearForm();
//   }

//   void _clearForm() {
//     _nameController.clear();
//     _descriptionController.clear();
//     _priceController.clear();
//     _stockController.clear();
//     _selectedStatus = 'disponible';
//     _selectedProductTypeId = null;
//     _imageUrlController.clear();
//     _idProdController.clear();
//     setState(() {
//       _image = null;
//       _isImageUploaded = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Add New Product'),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           children: [
//             TextField(
//               controller: _idProdController,
//               decoration: InputDecoration(labelText: 'Product ID'),
//               enabled: false,
//             ),
//             TextField(
//               controller: _nameController,
//               decoration: InputDecoration(labelText: 'Product Name'),
//               onEditingComplete: _generateId,
//             ),
//             TextField(
//               controller: _descriptionController,
//               decoration: InputDecoration(labelText: 'Description'),
//             ),
//             TextField(
//               controller: _priceController,
//               decoration: InputDecoration(labelText: 'Price'),
//               keyboardType: TextInputType.number,
//             ),
//             TextField(
//               controller: _stockController,
//               decoration: InputDecoration(labelText: 'Stock'),
//               keyboardType: TextInputType.number,
//             ),
//             DropdownButtonFormField<String>(
//               value: _selectedStatus,
//               onChanged: (String? newValue) {
//                 setState(() {
//                   _selectedStatus = newValue!;
//                 });
//               },
//               items:
//                   _statusOptions.map<DropdownMenuItem<String>>((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               decoration: InputDecoration(labelText: 'Status'),
//             ),
//             StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('tipoproducto')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return CircularProgressIndicator();
//                 var productTypes = snapshot.data!.docs;
//                 return DropdownButtonFormField<String>(
//                   value: _selectedProductTypeId,
//                   onChanged: (String? newValue) {
//                     setState(() {
//                       _selectedProductTypeId = newValue!;
//                     });
//                   },
//                   items: productTypes.map<DropdownMenuItem<String>>(
//                       (DocumentSnapshot document) {
//                     return DropdownMenuItem<String>(
//                       value: document.id,
//                       child: Text(document['nombre']),
//                     );
//                   }).toList(),
//                   decoration: InputDecoration(labelText: 'Type of Product'),
//                 );
//               },
//             ),
//             SizedBox(height: 20),
//             _image == null
//                 ? Icon(Icons.image_not_supported, size: 150)
//                 : Image.file(_image!, height: 150, width: 150),
//             ElevatedButton(onPressed: pickImage, child: Text('Pick Image')),
//             ElevatedButton(onPressed: addProduct, child: Text('Add Product')),
//           ],
//         ),
//       ),
//     );
//   }
// }
