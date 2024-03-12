import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:firedart/firedart.dart';
import './firestoreHandler.dart';
import './redis.dart';

//Add resolver to a location
final changeResolver=(shelf.Request request)async{
  String requestBody = await request.readAsString();
  var data = jsonDecode(requestBody);
  await updateDocument('locations',data['location'],{'resolverID':data['resolverID']});
  await updateDocument('users',data['resolverID'],{'requestedLocation':null,'assignedLocation':data['resolverID']});
  var jsonResponse = {'Success': true};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};
final requestResolver=(shelf.Request request)async{
  String requestBody = await request.readAsString();
  var data = jsonDecode(requestBody);
  await updateDocument('users',data['resolverID'],{'requestedLocation':data['resolverID']});
  var jsonResponse = {'Success': true};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};