import 'dart:async';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:sms/sms.dart';
import 'package:async/async.dart';

void _printWrapped(String text) {
  final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

Future<dynamic> httpGetJson(String url) async {
  var res = await http.get(url);
  if (res.statusCode == 200) {
    return convert.jsonDecode(res.body);
  } else {
    return null;
  }
}

Future<dynamic> httpPostJson(String url, String body) async {
  var res = await http.post(url, body: body);
  if (res.statusCode == 200) {
    return convert.jsonDecode(res.body);
  } else {
    return null;
  }
}

class _ChairsFuture {
  final int startIdx;
  final int count;
  final dynamic routes;
  final DateTime trainTime;
  AsyncMemoizer<List<int>> _cache = AsyncMemoizer<List<int>>();

  _ChairsFuture(this.startIdx, this.count, this.routes, this.trainTime) {
    assert(this.count <= 8);
  }

  Future<dynamic> _createChairsReq(searchRes, trainTime) {
    var obj = {
      "lstTrainAvailableChairsQuery": searchRes
          .skip(this.startIdx)
          .take(this.count)
          .expand((route) => route['Train']
              .map((train) => {
                    "trainNumber": train['Trainno'],
                    "trainDate": "${trainTime.year.toString().padLeft(4, "0")}-"
                        "${trainTime.month.toString().padLeft(2, "0")}-"
                        "${trainTime.day.toString().padLeft(2, "0")}",
                    "fromStation": train['OrignStation'],
                    "destStation": train['DestinationStation']
                  })
              .toList() as List<dynamic>)
          .toList()
    };

    var query = "?method=TrainAvailableChairs&jsonObj=" + Uri.encodeQueryComponent(convert.jsonEncode(obj));
    return httpGetJson("https://www.rail.co.il//_layouts/15/SolBox/TrainAvailableChairsHandler.ashx" + query);
  }

  Future<List<int>> get future {
    return this._cache.runOnce(() async {
      print("Fetching chairs $startIdx..${startIdx + count}");
      var chairs = await this._createChairsReq(this.routes, this.trainTime);
      return chairs['ListTrainAvailableChairs'].map<int>((trainChairs) {
        return trainChairs['SeatsAvailable'] as int;
      }).toList();
    });
  }

  bool contains(int idx) {
    return (idx >= this.startIdx) && (idx < (this.startIdx + this.count));
  }
}

class TrainSearchResult {
  TrainSearchResult(this.routes, this.trainTime);
  final dynamic routes;
  final DateTime trainTime;
  List<_ChairsFuture> _requests = [];

  Future<int> getChairs(int idx) async {
    for (var request in this._requests) {
      if (request.contains(idx)) {
        return (await request.future)[idx - request.startIdx];
      }
    }

    var request = _ChairsFuture(idx - (idx % 8), 8, this.routes, this.trainTime);
    _requests.add(request);
    return (await request.future)[idx - request.startIdx];
  }
}

Future<TrainSearchResult> search(String srcStationId, String dstStationId, DateTime trainTime,
    {bool isArrivalTime = false}) async {
  print("Fetching trains...");
  var searchUrl = 'https://www.rail.co.il/apiinfo/api/Plan/GetRoutes'
      '?OId=$srcStationId&TId=$dstStationId'
      '&Date=${trainTime.year.toString().padLeft(4, "0")}'
      '${trainTime.month.toString().padLeft(2, "0")}'
      '${trainTime.day.toString().padLeft(2, "0")}'
      '&Hour=${trainTime.hour.toString().padLeft(2, "0")}'
      '${trainTime.minute.toString().padLeft(2, "0")}'
      '&isGoing=${!isArrivalTime}'
      '&c=${DateTime.now().millisecondsSinceEpoch}';

  var trains = await httpGetJson(searchUrl);
  return TrainSearchResult(trains['Data']['Routes'], trainTime);
  // File.fromUri(Uri.parse("file:///tmp/search.json")).writeAsStringSync(convert.jsonEncode(trains));
  // var trains = convert.jsonDecode(
  //     await File.fromUri(Uri.parse("file:///home/david/code/pyrailreserve/cached/trainlib_trains.json"))
  //         .readAsString());

  // var chairs = await _createChairsReq(trains, trainTime);
  // var chairs = convert.jsonDecode(
  //     await File.fromUri(Uri.parse("file:///home/david/code/pyrailreserve/cached/trainlib_chairs.json"))
  //         .readAsString());
  // File.fromUri(Uri.parse("file:///tmp/search_chairs.json")).writeAsStringSync(convert.jsonEncode(chairs));

  // Combine chairs and trains
  // var len = min(chairs['ListTrainAvailableChairs'].length as int, trains['Data']['Routes'].length as int);
  // for (var i = 0; i < len; i++) {
  //   var trainChairs = chairs['ListTrainAvailableChairs'][i];
  //   var route = trains['Data']['Routes'][i];
  //   assert(trainChairs['TrainNumber'].toString() == route['Train'][0]['Trainno']);
  //   route['Train'][0]['SeatsAvailable'] = trainChairs['SeatsAvailable'];
  // }

  // return trains['Data']['Routes'];
}

List<dynamic> _stations;

void loadStations(List<dynamic> stations) {
  _stations = stations;
}

int _getStationIdx(String stationId) {
  for (var i = 0; i < _stations.length; i++) {
    if (_stations[i]['Id'] == stationId) {
      return i + 1;
    }
  }
  return -1;
}

String getStationNameById(String stationId) {
  for (var i = 0; i < _stations.length; i++) {
    if (_stations[i]['Id'] == stationId) {
      return _stations[i]['Heb'];
    }
  }
  return "N/A";
}

dynamic _createReservedTrain(dynamic train) {
  return {
    "TrainDate": train['DepartureTime'].substring(0, "00/00/0000".length) + " 00:00:00",
    "destinationStationId": _getStationIdx(train['DestinationStation']).toString(),
    "destinationStationHe": getStationNameById(train['DestinationStation']),
    "orignStationId": _getStationIdx(train['OrignStation']).toString(),
    "orignStationHe": getStationNameById(train['OrignStation']),
    "trainNumber": int.parse(train['Trainno']),
    "departureTime": train['DepartureTime'],
    "arrivalTime": train['ArrivalTime'],
    "orignStation": getStationNameById(train['OrignStation']),
    "destinationStation": getStationNameById(train['DestinationStation']),
    "orignStationNum": int.parse(train['OrignStation']),
    "destinationStationNum": int.parse(train['DestinationStation']),
    "DestPlatform": int.parse(train['DestPlatform']),
    "TrainOrder": 1 // FIXME?
  };
}

Future<dynamic> reserve(dynamic route, String mobileNo, String nationalId) async {
  // Request SMS token
  await http.post(
      'https://www.rail.co.il/taarif//_layouts/15/SolBox.Rail.FastSale/ReservedPlaceHandler.ashx?mobile=$mobileNo&userId=$nationalId&method=getToken&type=sms');
  // print("enter code: ");
  // var token = stdin.readLineSync();
  // var token = "";
  var tokenStream = StreamController();

  SmsReceiver receiver = new SmsReceiver();
  receiver.onSmsReceived.listen((SmsMessage msg) {
    if (msg.sender == "Israel Rail") {
      print("Message from Israel Rail:");
      print(msg.body);
      if (msg.body.length < 8) {
        tokenStream.add(msg.body);
      }
    }
  });

  String token = await tokenStream.stream.first;

  tokenStream.close();
  print("token = $token");

  // Reserve a seat
  var reserveData = {
    "smartcard": nationalId,
    "mobile": mobileNo,
    "email": "",
    "trainsResult": route['Train'].map(_createReservedTrain).toList()
  };
  // File.fromUri(Uri.parse("file:///tmp/reserveData.json")).writeAsStringSync(convert.jsonEncode(reserveData));
  var voucher = await httpPostJson(
      'https://www.rail.co.il/taarif//_layouts/15/SolBox.Rail.FastSale/ReservedPlaceHandler.ashx?numSeats=1&method=MakeVoucherSeatsReservation&IsSendEmail=true&source=1&typeId=1&token=$token',
      convert.jsonEncode(reserveData));
  // File.fromUri(Uri.parse("file:///tmp/voucher.json")).writeAsStringSync(convert.jsonEncode(voucher));
  _printWrapped(convert.jsonEncode(voucher["voutcher"]));

  // Send confirmation SMS
  reserveData['\$\$hashKey'] = 'object:44';
  await http.post(
      'https://www.rail.co.il/taarif//_layouts/15/SolBox.Rail.FastSale/ReservedPlaceHandler.ashx?GEneratedref=${voucher["voutcher"]["GeneretedReferenceValue"]}&typeId=1&method=SendSms',
      body: convert.jsonEncode(reserveData));

  return voucher;
}
