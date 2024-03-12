import 'package:firedart/firedart.dart';

//
final addDocument = (String col, Map<String, dynamic> data) async {
  var documentReference = await Firestore.instance.collection(col).add(data);
  return documentReference.id;
};

//Delete a document from database
final delDocument = (String col, String documentId) async {
  var documentReference = Firestore.instance.collection(col).document(documentId);
  await documentReference.delete();
};

//Retrieve a document from database
final findDocument = (String col, String documentId) async {
  var documentReference = Firestore.instance.collection(col).document(documentId);
  if (await documentReference.exists) {
    var documentSnapshot = await documentReference.get();
    return documentSnapshot;
  } else {
    print('Document not found');
    return null;
  }
};

//Update a document's fields
final updateDocument=(String col,String documentId,data) async{
  var documentReference = Firestore.instance.collection(col).document(documentId);
  await documentReference.update(data);
};

//Find document using one property
final findDocuments=(String col,String property,dynamic value)async{
  var query = await Firestore.instance.collection(col).where(property,isEqualTo: value)
      .get();
  return query;
};

//Find document using one property
final findAllDocuments=(String col)async{
  var query = await Firestore.instance.collection(col).get();
  return query.toList();
};

//Find document using multiple properties
final findDocumentsTwo=(String col,String property1,dynamic value1,String property2,dynamic value2)async{
  var query = await Firestore.instance.collection(col).where(property1,isEqualTo: value1).where(property2,isEqualTo: value2)
      .get();
  return query;
};