import 'package:shelf/shelf.dart' as shelf;
import 'package:redis/redis.dart' as red;
import 'dart:convert';
import 'dart:io';
final fetchClosestLocation=(Map<String,dynamic>data)async{
  //Set up redis connection
  final conn = red.RedisConnection();
  var response=await conn.connect('redis-18608.c299.asia-northeast1-1.gce.cloud.redislabs.com', 18608);
  await response
      .send_object(["AUTH", "default", 'ZbeBCAUOznqjLFmldQFLO9wtcbqBHjXn']);

  //Find closest 10 locations within 10 km.
  var results=await response.send_object([
    'GEOSEARCH',
    'locations',
    'FROMLONLAT',
    data['latitude'].toString(),
    data['longitude'].toString(),
    'BYRADIUS',
    '1',
    'km',
    'ASC',
    'COUNT',
    '10',
    'WITHCOORD',
    'WITHDIST'
  ]);
  conn.close();
  if(results.isEmpty)return {'found':false};
  return {'found':true,'result':results[0]};
};
final addToSetWithExpiry = (String key, String member) async {
  final conn = red.RedisConnection();
  var response = await conn.connect('redis-18608.c299.asia-northeast1-1.gce.cloud.redislabs.com', 18608);
  await response.send_object(["AUTH", "default", 'ZbeBCAUOznqjLFmldQFLO9wtcbqBHjXn']);
  var timestamp = DateTime.now().add(Duration(seconds: 300)).millisecondsSinceEpoch.toString();
  await response.send_object(["ZADD", key, timestamp, member]);
  conn.close();
};

final getSetSize = (String key) async {
  try {
    final conn = red.RedisConnection();
    var response = await conn.connect(
        'redis-18608.c299.asia-northeast1-1.gce.cloud.redislabs.com', 18608);
    await response.send_object(
        ["AUTH", "default", 'ZbeBCAUOznqjLFmldQFLO9wtcbqBHjXn']);
    var futureTimestamp1 = DateTime
        .now()
        .add(Duration(seconds: 1))
        .millisecondsSinceEpoch
        .toString();
    var futureTimestamp2 = DateTime
        .now()
        .add(Duration(seconds: 450))
        .millisecondsSinceEpoch
        .toString();
    // Count the number of elements in the sorted set with scores from +5 seconds to infinity
    var result = await response.send_object(
        ["ZCOUNT", key, futureTimestamp1, futureTimestamp2]);
    response.send_object(["ZREMRANGEBYSCORE", key, DateTime
        .now()
        .subtract(Duration(seconds: 50000000))
        .millisecondsSinceEpoch
        .toString(), DateTime
        .now()
        .millisecondsSinceEpoch
        .toString()
    ]);
    conn.close();
    return result;
  }catch(err){
    print(err);
  }
};

