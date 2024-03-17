import 'firestoreHandler.dart';
final getLocationStats=(String location, String category)async{
  try {
    List<int> hourCounts = List.filled(24 * 7, 0);
    List<int>combinedCounts=List.filled(8*7,0);
    final complaints = await findComplaintsLastWeek(location, category);
    Map<int, int>counts = {};
    complaints.forEach((doc) {
      int milli = doc['time'];
      int past = milli - DateTime
          .now()
          .subtract(Duration(days: 7))
          .millisecondsSinceEpoch;
      past = (past / 1000).toInt();
      past = (past / 60).toInt();
      past = (past / 60).toInt();
      hourCounts[past]++;
      if(doc['resolvedTime']!=null) {
        int timeToResolve = doc['resolvedTime'] - doc['time'];
        timeToResolve = (timeToResolve / 1000).toInt() + 1;
        timeToResolve = (timeToResolve / 60).toInt() + 1;
        timeToResolve = (timeToResolve / 60).toInt() + 1;
        counts[timeToResolve] = (counts[timeToResolve] ?? 0) + 1;
      }
    });
    for(int i=0;i<8*7;i++){
      combinedCounts[i]=hourCounts[i*3]+hourCounts[1+i*3]+hourCounts[2+i*3];
    }
    List<Map<String, dynamic>> countsList = counts.entries.map((entry) {
      return {'key': entry.key, 'value': entry.value};
    }).toList();
    return {'hourCounts': combinedCounts, 'counts':countsList};
  }catch(err){
    print(err);
    return {'hourCounts': [], 'counts': []};
  }
};

final getOverallStats=()async{
  try {
    Map<String,Map<String,dynamic>>data={};
    final complaints = await findComplaintsLastWeekAll();
    complaints.forEach((doc) {
     if(data[doc['place']]==null)data[doc['place']]={};
     data[doc['place']]![doc['category']]=(data[doc['place']]![doc['category']]??0)+1;
    });
    return {'stats':data};
  }catch(err){
    print(err);
    return {'stats':{}};
  }
};