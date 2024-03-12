import 'dart:convert';
import 'dart:io';
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_multipart/multipart.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:cached/cached.dart';
import 'package:cached_annotation/cached_annotation.dart';
import 'package:firedart/firedart.dart';
import 'package:dio/dio.dart';
import './controllers/user.dart';
import './controllers/redis.dart';
import 'dart:typed_data';
import './controllers/firestoreHandler.dart';
import './controllers/resolver.dart';
import './controllers/admin.dart';

shelf.Handler _corsHandler(shelf.Handler handler) {
  return (shelf.Request request) async {
    if (request.method == 'OPTIONS') {
      return shelf.Response.ok('', headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      });
    }
    final response = await handler(request);
    return response.change(headers: {
      'Access-Control-Allow-Origin': '*',
    });
  };
}

@Cached(
    ttl: 250
)
final func=()async{
  final locations=['Jhalwa','Rajruppur'];
  final sizes=locations.map((element)=>getSetSize(element)).toList();
  final result=await Future.wait(sizes);
  final result2=result.asMap().entries.map((entry)=>{
    'location':locations[entry.key],
    'crown':entry.value
  }).toList();
  print(result2);
  return result2;
};

final accumulateData=()async{
  List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  while(true){
    //[TODO] Send result2 to the python server
    final data=await func();
    DateTime now = DateTime.now();
    String time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    String day = daysOfWeek[now.weekday - 1];
    final dio=Dio();
    calls=data.map((element)=>{...element,'day':day,'time':time});
    posts=calls.map((element)=>dio.post('http://localhost:5000/userData',data:element));
    await Future.wait(posts);
    await Future.delayed(Duration(minutes:5));
  }
};

final locationDensity=(shelf.Request request) async {
  try {
    var jsonResponse = {'Success': true,'result':await func()};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};


void main() async {
  var app = Router();
  Firestore.initialize("kumbh-mela-2de50");
  app.post('/addComplaint',addComplaint);
  app.post('/locationDensity',locationDensity);
  app.post('/inbound',inbound);
  app.post('/notification',sendNotification);
  app.post('/resolveComplaint', resolveComplaint);
  app.get('/viewComplaintsUser', viewComplaintsByUser);
  app.get('/viewComplaintsLocation',viewComplaintsByLocation);
  app.get('/viewComplaintsResolved',viewComplaintsForResolverResolved);
  app.get('/viewComplaintsUnresolved',viewComplaintsForResolverUnResolved);
  app.post('/resolveComplaint',resolveComplaint);
  app.post('/resolveComplaints',resolveComplaintAll);
  app.get('/getUserDetails',getUserDetails);
  app.delete('/deleteComplaint',deleteComplaint);
  app.get('/getLocations',getLocation);
  app.post('/changeResolver',changeResolver);//[TODO] change resolver to another location (or deallocate)
  app.post('/requestResolver',requestResolver); //[TODO]  change resolver's requested location
  app.post('/locationupdate',locationPing);
  accumulateData();
  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addMiddleware(_corsHandler)
      .addHandler(app);
  var server = await io.serve(handler, '0.0.0.0', 8080);
  print('Server running on localhost:${server.port}');
}