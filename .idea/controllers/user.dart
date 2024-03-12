import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:firedart/firedart.dart';
import './firestoreHandler.dart';
import './redis.dart';

//Add this complaint to the database
final addComplaint=(shelf.Request req) async {
  try {
    String requestBody = await req.readAsString();
    var data = jsonDecode(requestBody);
    var location = await fetchClosestLocation(
        {'latitude': data['latitude'], 'longitude': data['longitude']});
    if (location['found'] == false) {
      return shelf.Response.badRequest();
    }
    DateTime now = DateTime.now().toUtc();
    int unixTimestampSeconds = now.millisecondsSinceEpoch ~/ 1000;
    //Add a complaint document
    var documentID = await addDocument('complaints', {
      'user': data['user'],
      'description': data['description'],
      'place': location['result'][0],
      'latitude': data['latitude'],
      'longitude': data['longitude'],
      'date': unixTimestampSeconds,
      'urgency': data['urgency'],
      'resolved': false
    });
    var jsonResponse = {'Success': true, 'complaintID': documentID};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

//Resolve an individual complaint
final resolveComplaint=(shelf.Request req) async {
  try {
    String requestBody = await req.readAsString();
    var data = jsonDecode(requestBody);
    await updateDocument('complaints', data['complaintID'],{'resolved': true});
    var jsonResponse = {'Success': true};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

final getLocation=(shelf.Request req) async {
  try {
    final locations=['Jhalwa','Rajruppur'];
    var jsonResponse = {'Success': true, 'locations': locations};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};


//Resolve all complaints which are within the radius of a particular location
final resolveComplaintAll=(shelf.Request req) async {
  try {
    String requestBody = await req.readAsString();
    var data = jsonDecode(requestBody);
    final complaints = await findDocumentsTwo(
        'complaints', 'place', data['location'], 'resolved', false);
    final tasks2 = complaints.map((element) =>
        updateDocument('complaints', element.id, {'resolved': true})).toList();
    print(await Future.wait(tasks2));
    var jsonResponse = {'Success': true};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

//Retrieve all complaints from one user
final viewComplaintsByUser=(shelf.Request req) async {
  try {
    var queryParams = req.url.queryParameters;
    var complaints = await findDocuments(
        'complaints', 'user', queryParams['user']);
    return shelf.Response.ok(jsonEncode(
        complaints.map((element) => {...element.map, 'queryID': element.id})
            .toList()),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

//Find all complaints which have been resolved
final viewComplaintsByUserResolved=(shelf.Request req) async {
  try {
    var queryParams = req.url.queryParameters;
    var complaints = await findDocumentsTwo(
        'complaints', 'user', queryParams['user'], 'resolved', true);
    return shelf.Response.ok(jsonEncode(
        complaints.map((element) => {...element.map, 'queryID': element.id})
            .toList()),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

//Find all complaints which have not been resolved
final viewComplaintsByUserUnResolved=(shelf.Request req) async {
  try {
    var queryParams = req.url.queryParameters;
    var complaints = await findDocumentsTwo(
        'complaints', 'user', queryParams['user'], 'resolved', false);
    return shelf.Response.ok(jsonEncode(
        complaints.map((element) => {...element.map, 'queryID': element.id})
            .toList()),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

//Find all complaints which have been resolved
final viewComplaintsForResolverResolved=(shelf.Request req) async {
  try {
    var queryParams = req.url.queryParameters;
    var resolver = await findDocument('users', queryParams['user']!);
    print(resolver);
    var location = resolver!.map['assignedLocation'];
    print(location);
    if (location == null) {
      return shelf.Response.badRequest();
    }
    var complaints = await findDocumentsTwo(
        'complaints', 'place', location, 'resolved', true);
    return shelf.Response.ok(jsonEncode(
        complaints.map((element) => {...element.map, 'queryID': element.id})
            .toList()),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

//Find all complaints which have not been resolved
final viewComplaintsForResolverUnResolved=(shelf.Request req) async {
  try {
    var queryParams = req.url.queryParameters;
    var resolver = await findDocument('users', queryParams['user']!);
    var location = resolver!.map['assignedLocation'];
    if (location == null) {
      return shelf.Response.badRequest();
    }
    var complaints = await findDocumentsTwo(
        'complaints', 'place', location, 'resolved', false);
    print(complaints);
    return shelf.Response.ok(jsonEncode(
        complaints.map((element) => {...element.map, 'queryID': element.id})
            .toList()),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

final getUserDetails=(shelf.Request req) async {
  try {
    var queryParams = req.url.queryParameters;
    var user = await findDocument('users', queryParams['user']!);
    if (user == null) {
      return shelf.Response.badRequest();
    }
    return shelf.Response.ok(jsonEncode(user.map),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

//[TODO]
final sos=(shelf.Request request)async{
  try {
    String requestBody = await request.readAsString();
    var data = jsonDecode(requestBody);
    var jsonResponse = {'Success': true};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

//Handle SMS Requests
shelf.Middleware checkRequestBodyFormatMiddleware() {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      String requestBody = await request.readAsString();

      // Define the regex patterns for SOS and Add formats
      RegExp sosPattern = RegExp(r'KumbhSight SOS ([\d.-]+) ([\d.-]+)');
      RegExp addPattern = RegExp(r'KumbhSight Add (\w+) ([\d.-]+) ([\d.-]+) (\w+) (.*)');

      if (sosPattern.hasMatch(requestBody)) {
        var match = sosPattern.firstMatch(requestBody)!;
        var latitude = double.parse(match.group(1)!);
        var longitude = double.parse(match.group(2)!);
        request = request.change(body: '$requestBody\nLatitude: $latitude, Longitude: $longitude');
        return sos(request);
      } else if (addPattern.hasMatch(requestBody)) {
        var match = addPattern.firstMatch(requestBody)!;
        var userId = match.group(1)!;
        var latitude = double.parse(match.group(2)!);
        var longitude = double.parse(match.group(3)!);
        var urgency = match.group(4)!;
        var description = match.group(5)!;
        request = request.change(body: '$requestBody\nUserId: $userId, Latitude: $latitude, Longitude: $longitude, Urgency: $urgency, Description: $description');
        return addComplaint(request);
      }
      return innerHandler(request);
    };
  };
}
shelf.Response defaultHandler(shelf.Request request) {
  return shelf.Response.notFound('Invalid Request');
}
final inbound = checkRequestBodyFormatMiddleware()(defaultHandler);


//Retrieve all complaints mapped to one location
final viewComplaintsByLocation=(shelf.Request request)async{
  try{
  var queryParams = request.url.queryParameters;
  var complaints = await findDocuments('complaints','location',queryParams['location']);
  return shelf.Response.ok(jsonEncode(complaints.map((element)=> {...element.map,'queryID':element.id}).toList()),
      headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }

};

//Retrieve all complaints mapped to one location, and resolved
final viewComplaintsByLocationUnresolved=(shelf.Request request)async{
  try {
    var queryParams = request.url.queryParameters;
    var complaints = await findDocumentsTwo(
        'complaints', 'location', queryParams['location'], 'resolved', true);
    return shelf.Response.ok(jsonEncode(
        complaints.map((element) => {...element.map, 'queryID': element.id})
            .toList()),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

//Delete complaint from database
final deleteComplaint=(shelf.Request request)async{
  try {
    String requestBody = await request.readAsString();
    var data = jsonDecode(requestBody);
    delDocument('complaints', data['complaintID']);
    var jsonResponse = {'Success': true};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

final locationPing=(shelf.Request request)async{
  try {
    String requestBody = await request.readAsString();
    var data = jsonDecode(requestBody);
    print(data);
    var location = await fetchClosestLocation(
        {'latitude': data['latitude'], 'longitude': data['longitude']});
    if (location['found'] == false) {
      return shelf.Response.badRequest();
    }
    await addToSetWithExpiry(location['result'][0],data['user']);
    var jsonResponse = {'Success': true};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    print(err);
    return shelf.Response.internalServerError();
  }
};