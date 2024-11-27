import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'carta.dart';

class NegocioListaPage extends StatefulWidget {
  final String userId;

  NegocioListaPage({required this.userId});

  @override
  _NegocioListaPageState createState() => _NegocioListaPageState();
}

class _NegocioListaPageState extends State<NegocioListaPage> {
  String? selectedTipoCocinaId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Negocios'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
   
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar Restaurante o Platos',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            
        
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tipococina').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var tiposCocina = snapshot.data!.docs;

                return Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tiposCocina.length,
                    itemBuilder: (context, index) {
                      var tipoCocina = tiposCocina[index];
                      var tipoData = tipoCocina.data() as Map<String, dynamic>;

                      bool isSelected = selectedTipoCocinaId == tipoCocina.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                           
                            if (isSelected) {
                              selectedTipoCocinaId = null;
                            } else {
                              selectedTipoCocinaId = tipoCocina.id;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: 90,
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.purple.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? Colors.purple : Colors.grey.shade300, 
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                      
                              tipoData['imagen'] != null
                         
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        tipoData['imagen'],
                                        width: 70,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.image_not_supported, size: 50);
                                        },
                                      ),
                                    )
                                  : Icon(Icons.image, size: 50),
                              SizedBox(height: 5), 
                              Text(
                                tipoData['nombre'],
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('negocios').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var negocios = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: negocios.length,
                  itemBuilder: (context, index) {
                    var negocio = negocios[index].data() as Map<String, dynamic>;

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('cartasnegocio')
                          .where('negocioId', isEqualTo: negocios[index].id)
                          .get(),
                      builder: (context, cartaSnapshot) {
                        if (!cartaSnapshot.hasData) return CircularProgressIndicator();

                      
                        if (cartaSnapshot.data!.docs.isEmpty) {
                          return SizedBox.shrink();
                        }

                        var carta = cartaSnapshot.data!.docs.first.data() as Map<String, dynamic>;

                     
                        if (carta['carta'] == null || (carta['carta'] as List).isEmpty) {
                          return SizedBox.shrink();
                        }

                        var productos = carta['carta'] as List;

                        var randomProduct = (productos..shuffle()).first;
                        var productImage = randomProduct['urlImagen'] ?? '';

                        return GestureDetector(
                          onTap: () {
                 
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CartaPage(
                                  negocioId: negocios[index].id,
                                  userId: widget.userId, 
                                ),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                      
                                productImage.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                        child: Image.network(
                                          productImage,
                                          width: double.infinity,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : SizedBox.shrink(),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                  
                                      negocio['logo'] != null
                                          ? Image.network(negocio['logo'], width: 50, height: 50)
                                          : Icon(Icons.store, size: 50),
                                      SizedBox(width: 10),
                                
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              negocio['nombre'],
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              'Dirección: ${negocio['direccion']}',
                                              style: TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

