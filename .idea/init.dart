import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firedart/firedart.dart';
import 'package:dio/dio.dart';
import './controllers/redis.dart';
import './controllers/firestoreHandler.dart';

final random=Random();

final generateString=(int length){
  return String.fromCharCodes(
  List.generate(length, (index) => random.nextInt(26) + 65));
};

final fillData=()async{
  try {
    Firestore.initialize("kumbh-mela-2de50");
    var locations = ['Jhalwa', 'Rajruppur'];
    var category = ['Healthcare', 'LostAndFoundService', 'Hygiene', 'LawEnforcement'];
    for(int j=0;j<100;j++) {
      List<Future<String>> d = [];
      for (int i = 0; i < 100; i++) {
        int time=DateTime
            .now()
            .millisecondsSinceEpoch - random.nextInt(604800000);
        d.add(addDocument('complaints', {
          'user': generateString(10),
          'description': generateString(100),
          'place': locations[random.nextInt(2)],
          'latitude': 25.443920+random.nextDouble()/100000,
          'longitude': 81.825027+random.nextDouble()/100000,
          'urgency': random.nextInt(10),
          'resolved': true,
          'category': category[random.nextInt(4)],
          'time': time,
          'resolvedTime':min(DateTime.now().millisecondsSinceEpoch,time+random.nextInt(10*60*60*1000))
        }));
      }
      print(await Future.wait(d));
    }
  }catch(err){
    print(err);
  }
};

void main()async{
  try {
    await fillData();
  }catch(err){
    print(err);
  }
}