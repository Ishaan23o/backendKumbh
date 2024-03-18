import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';

// Functions for generating random data
String generateRandomTime() {
  final hour = Random().nextInt(24);
  final minute = Random().nextInt(60);
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

int generateRandomCrowd() {
  return Random().nextInt(501) + 1000; // Generates a random number between 500 and 1000
}

final String apiUrl = 'https://kumbhmelaml-rbti7rywha-et.a.run.app/userData';
final dio = Dio();

Future<void> sendRequests() async {
  for(int j=0;j<1;j++) {
    List<Future<dynamic>>d = [];
    for (var i = 0; i < 100; i++) {
      final locations = [ 'Rajruppur'];
      final location = locations[Random().nextInt(locations.length)];
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final day = days[Random().nextInt(days.length)];
      final time = generateRandomTime();
      final crowd = generateRandomCrowd();

      final data = {
        'location': location,
        'day': day,
        'time': time,
        'crowd': crowd
      };
      d.add(dio.post(apiUrl, data: data));
    }
    print(await Future.wait(d));
  }
}

void main() {
  sendRequests();
}
