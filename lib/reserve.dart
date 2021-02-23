import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

import 'package:sms/sms.dart';

import 'trainlib.dart' as trainlib;

const reserve_destination = Destination('הזמנה', Icons.train);

class Stations {
  static var _stations;
  static dynamic getStations(BuildContext context) async {
    if (_stations == null) {
      String data = await DefaultAssetBundle.of(context).loadString("assets/stations.json");
      final jsonResult = json.decode(data);
      _stations = jsonResult;
      trainlib.loadStations(_stations);
    }
    return _stations;
  }
}

// class ExampleRes {
//   static var _exampleRes;
//   static dynamic getExampleRes(BuildContext context) async {
//     if (_exampleRes == null) {
//       String data = await DefaultAssetBundle.of(context).loadString("assets/example_res.json");
//       // await Future.delayed(Duration(seconds: 1));
//       final jsonResult = json.decode(data);
//       _exampleRes = jsonResult;
//     }
//     return _exampleRes;
//   }
// }

class ReserveView extends StatefulWidget {
  const ReserveView({Key key, this.ticketReservedCb}) : super(key: key);
  final ticketReservedCb;

  @override
  _ReserveViewState createState() => _ReserveViewState();
}

String _formatDateRaw(DateTime time) {
  return "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}";
}

String _formatDate(DateTime time) {
  String target = _formatDateRaw(time);
  String today = _formatDateRaw(DateTime.now());
  String tomorrow = _formatDateRaw(DateTime.now().add(Duration(days: 1)));
  if (target == today) {
    return "היום";
  } else if (target == tomorrow) {
    return "מחר";
  } else {
    return target;
  }
}

String _formatTime(TimeOfDay time) {
  return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
}

class ReserveConfigurator extends StatefulWidget {
  @override
  _ReserveConfiguratorState createState() => _ReserveConfiguratorState();
}

class _ReserveConfiguratorState extends State<ReserveConfigurator> {
  String _fromStationId = "2200";
  String _toStationId = "3700";
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _timeChanged = false;
  bool _isArrival = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/reserve_bg.jpeg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Material search box
                Material(
                  elevation: 12.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 14.0, left: 18.0, right: 18.0),
                    child: FittedBox(
                      child: Column(
                        children: [
                          // Station pickers
                          Column(
                            children: [
                              StationSelector(
                                value: this._fromStationId,
                                onChanged: (String newValue) {
                                  setState(() {
                                    this._fromStationId = newValue;
                                    print("from = $_fromStationId");
                                  });
                                },
                              ),
                              IconButton(
                                  tooltip: "החלף תחנות",
                                  onPressed: () {
                                    setState(() {
                                      String temp = this._toStationId;
                                      this._toStationId = this._fromStationId;
                                      this._fromStationId = temp;
                                    });
                                  },
                                  icon: Icon(Icons.swap_vert)),
                              StationSelector(
                                value: this._toStationId,
                                onChanged: (String newValue) {
                                  setState(() {
                                    this._toStationId = newValue;
                                    print("to = $_toStationId");
                                  });
                                },
                              ),
                            ],
                          ),

                          // Time & Date pickers
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Tooltip(
                                    message: "תאריך",
                                    child: OutlinedButton.icon(
                                      icon: Icon(Icons.date_range),
                                      label: Text(_formatDate(this._date)),
                                      onPressed: () {
                                        showDatePicker(
                                          context: context,
                                          initialDate: this._date,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(Duration(days: 14)),
                                        ).then((date) {
                                          if (date != null) {
                                            setState(() {
                                              if (_formatDateRaw(this._date) != _formatDateRaw(date)) {
                                                this._timeChanged = true;
                                              }
                                              this._date = date;
                                            });
                                          }
                                        });
                                      },
                                      autofocus: false,
                                      clipBehavior: Clip.none,
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: "זמן",
                                  child: OutlinedButton.icon(
                                    icon: Icon(Icons.access_time),
                                    label: Text(this._timeChanged ? _formatTime(this._time) : "עכשיו"),
                                    onPressed: () {
                                      showTimePicker(
                                        context: context,
                                        initialTime: this._timeChanged ? this._time : TimeOfDay.now(),
                                      ).then((time) {
                                        if (time != null) {
                                          setState(() {
                                            this._time = time;
                                            this._timeChanged = true;
                                          });
                                        }
                                      });
                                    },
                                    autofocus: false,
                                    clipBehavior: Clip.none,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Time exit/arrival picker
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ToggleButtons(
                              isSelected: [this._isArrival, !this._isArrival],
                              borderRadius: BorderRadius.circular(4),
                              renderBorder: false,
                              children: [
                                "זמן הגעה",
                                "זמן יציאה",
                              ]
                                  .map((label) => Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: Text(label),
                                      ))
                                  .toList(),
                              onPressed: (idx) {
                                setState(() {
                                  this._isArrival = idx == 0;
                                });
                              },
                            ),
                          ),

                          // Search button
                          Padding(
                            padding: const EdgeInsets.only(top: 22.0),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (!this._timeChanged) {
                                  this._time = TimeOfDay.now();
                                }
                                Navigator.pushNamed(
                                  context,
                                  "/trainSearch",
                                  arguments: SearchResultsArgs(
                                    srcStationId: this._fromStationId,
                                    dstStationId: this._toStationId,
                                    trainTime:
                                        this._date.add(Duration(hours: this._time.hour, minutes: this._time.minute)),
                                    isArrivalTime: this._isArrival,
                                  ),
                                );
                              },
                              icon: Icon(Icons.search),
                              label: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  "חיפוש",
                                  textScaleFactor: 1.25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchResults extends StatefulWidget {
  const SearchResults(this.args, {Key key, this.ticketReservedCb}) : super(key: key);

  final SearchResultsArgs args;
  final ticketReservedCb;

  @override
  _SearchResultsState createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  ScrollController controller = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("תוצאות"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder(
            future: trainlib.search(
              widget.args.srcStationId,
              widget.args.dstStationId,
              widget.args.trainTime,
              isArrivalTime: widget.args.isArrivalTime,
            ),
            builder: (context, data) {
              var inner;
              if (data.hasData) {
                inner = ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: data.data.routes.length,
                    separatorBuilder: (context, idx) => Divider(
                          color: Colors.black.withAlpha(64),
                        ),
                    itemBuilder: (BuildContext context, int index) {
                      final route = data.data.routes[index];
                      final train = route["Train"][0];
                      final departTime = train["DepartureTime"].split(" ")[1].split(":").sublist(0, 2).join(":");
                      final arriveTime = train["ArrivalTime"].split(" ")[1].split(":").sublist(0, 2).join(":");
                      final estTime = route["EstTime"].split(":").sublist(0, 2).join(":");
                      final seats = data.data.getChairs(index);
                      return ListTile(
                        title: Text(
                          '(~$estTime)  $arriveTime ← $departTime',
                          textAlign: TextAlign.right,
                        ),
                        subtitle: FutureBuilder(
                            future: seats,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  '${snapshot.data} מקומות',
                                  textDirection: TextDirection.rtl,
                                );
                              } else if (snapshot.hasError) {
                                return Text("${snapshot.error}");
                              } else {
                                return Container(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                            }),
                        trailing: Icon(Icons.train),
                        visualDensity: VisualDensity.compact,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => ReserveModal(
                              train: train,
                              estTime: estTime,
                              departTime: departTime,
                              arriveTime: arriveTime,
                              seats: seats,
                              route: route,
                              ticketReservedCb: widget.ticketReservedCb,
                            ),
                          );
                        },
                      );
                    });
              } else {
                inner = Text(".");
              }
              return AnimatedCrossFade(
                duration: Duration(milliseconds: 200),
                crossFadeState: data.hasData ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Center(child: CircularProgressIndicator()),
                secondChild: inner,
              );
            }),
      ),
    );
  }
}

class ReserveModal extends StatefulWidget {
  const ReserveModal({
    Key key,
    @required this.train,
    @required this.estTime,
    @required this.departTime,
    @required this.arriveTime,
    @required this.seats,
    @required this.route,
    this.ticketReservedCb,
  }) : super(key: key);

  final train;
  final estTime;
  final departTime;
  final arriveTime;
  final seats;
  final route;
  final ticketReservedCb;

  @override
  _ReserveModalState createState() => _ReserveModalState();
}

class _ReserveModalState extends State<ReserveModal> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: Duration(milliseconds: 200),
      crossFadeState: _isLoading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Center(
          child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: CircularProgressIndicator(),
      )),
      secondChild: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'רכבת #${widget.train["Trainno"]}  (${widget.estTime}~)',
                textDirection: TextDirection.rtl,
                textScaleFactor: 1.25,
              ),
            ),
            Row(
              children: [
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${trainlib.getStationNameById(widget.train["OrignStation"])}',
                      style: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold),
                    ),
                    for (var item in widget.train["StopStations"])
                      Text('${trainlib.getStationNameById(item["StationId"])}'),
                    Text(
                      '${trainlib.getStationNameById(widget.train["DestinationStation"])}',
                      style: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ]
                      .map((w) => Container(
                            child: w,
                            height: 20,
                          ))
                      .toList(),
                ),
                Container(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@ ${widget.departTime}',
                        style: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold)),
                    for (var item in widget.train["StopStations"])
                      Text('@ ${item["ArrivalTime"].split(" ")[1].split(":").sublist(0, 2).join(":")}'),
                    Text('@ ${widget.arriveTime}',
                        style: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold)),
                  ]
                      .map((w) => Container(
                            child: w,
                            height: 20,
                          ))
                      .toList(),
                ),
                Container(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('[${widget.train["Platform"]} רציף]',
                        style: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold)),
                    for (var item in widget.train["StopStations"]) Text('[${item["Platform"]} רציף]'),
                    Text('[${widget.train["DestPlatform"]} רציף]',
                        style: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold)),
                  ]
                      .map((w) => Container(
                            child: w,
                            height: 20,
                          ))
                      .toList(),
                ),
                Spacer(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: FutureBuilder(
                  future: widget.seats,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        '${snapshot.data} מקומות',
                        textDirection: TextDirection.rtl,
                        textScaleFactor: 1.1,
                      );
                    } else {
                      return SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 3,
                        ),
                      );
                    }
                  }),
            ),
            Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      var prefs = await SharedPreferences.getInstance();
                      var voucher = await trainlib.reserve(
                          widget.route, prefs.getString("mobileNo"), prefs.getString("nationalId"));
                      prefs.setString("activeVoucher", jsonEncode(voucher["voutcher"]));
                      prefs.setString("activeQR", voucher["BarcodeString"]);
                      if (widget.ticketReservedCb != null) {
                        widget.ticketReservedCb();
                      }
                    } catch (ex) {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: Text("Error"),
                                actions: [
                                  TextButton(
                                    child: Text("Dismiss"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  )
                                ],
                                content: Text(ex.toString()),
                              ));
                    }
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  icon: Icon(Icons.train),
                  label: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text(
                      "הזמנת מקום",
                      textScaleFactor: 1.25,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SearchResultsArgs {
  const SearchResultsArgs({
    @required this.srcStationId,
    @required this.dstStationId,
    @required this.trainTime,
    @required this.isArrivalTime,
  });

  final String srcStationId;
  final String dstStationId;
  final DateTime trainTime;
  final bool isArrivalTime;
}

class _ReserveViewState extends State<ReserveView> {
  Key _navigatorKey;
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/':
            builder = (BuildContext context) => ReserveConfigurator();
            break;
          case '/trainSearch':
            builder = (BuildContext context) =>
                SearchResults(settings.arguments as SearchResultsArgs, ticketReservedCb: widget.ticketReservedCb);
            break;
          // case '/settings':
          //   builder = (BuildContext context) => ReservePage();
          //   break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }
        return MaterialPageRoute(
            builder: (BuildContext context) {
              return WillPopScope(
                child: builder(context),
                onWillPop: () async {
                  Future.delayed(Duration.zero, () {
                    Navigator.pop(context);
                  });
                  return false;
                },
              );
            },
            settings: settings);
      },
    );
  }
}

class StationSelector extends StatelessWidget {
  const StationSelector({
    Key key,
    this.value,
    this.onChanged,
  }) : super(key: key);

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Stations.getStations(context),
      builder: (BuildContext context, AsyncSnapshot<dynamic> stations) {
        if (stations.hasData) {
          return DropdownButton(
            value: this.value,
            onChanged: this.onChanged,
            items: stations.data.map<DropdownMenuItem<String>>((station) {
              return DropdownMenuItem<String>(
                value: station["Id"],
                child: Text(
                  station["Heb"],
                ),
              );
            }).toList(),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
