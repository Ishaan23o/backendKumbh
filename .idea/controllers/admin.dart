import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:googleapis/pubsub/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'stats.dart';
import 'package:dio/dio.dart';

Future<void> publishMessage(String _message) async {
  const _projectId = 'prime-mechanic-413516';
  const _topicId = 'createNotifications';
  final credentialsFile = File('./.idea/cred.json');
  final credentialsJson = json.decode(credentialsFile.readAsStringSync());
  final credentials = ServiceAccountCredentials.fromJson(credentialsJson);

  final client = await clientViaServiceAccount(credentials, [PubsubApi.pubsubScope]);

  final pubsub = PubsubApi(client);
  final topicName = 'projects/$_projectId/topics/$_topicId';

  final messageData = base64.encode(utf8.encode(_message)); // Encode message as base64

  final message = PubsubMessage()..data = messageData;

  await pubsub.projects.topics.publish(
    PublishRequest()..messages = [message],
    topicName,
  );

  client.close();
}

//Send notification to all users
final sendNotification=(shelf.Request request)async{
  try {
    String requestBody = await request.readAsString();
    var data = jsonDecode(requestBody);
    await publishMessage(data['message']);
    var jsonResponse = {'Success': true};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    return shelf.Response.internalServerError();
  }
};

final getStats=(shelf.Request request)async{
  try {
    String requestBody = await request.readAsString();
    var data = jsonDecode(requestBody);
    var jsonResponse = {'Success': true,... (await getLocationStats(data['location'],data['category']))};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    print(err);
    return shelf.Response.internalServerError();
  }
};

final getTotalStats=(shelf.Request request)async{
  try {
    var jsonResponse = {'Success': true,... (await getOverallStats())};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    print(err);
    return shelf.Response.internalServerError();
  }
};

final predictionsML=(shelf.Request request)async{
  try {
    final dio=Dio();
    final posts=await dio.post('https://kumbhmelaml-rbti7rywha-et.a.run.app/predictCrowdAfterHalfHour');
    print(posts.data);
    Map<String,int> jsonResponse = {... (posts.data)};
    return shelf.Response.ok(jsonEncode(jsonResponse),
        headers: {'Content-Type': 'application/json'});
  }catch(err){
    print(err);
    return shelf.Response.internalServerError();
  }
};