import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railreserve/active.dart';
import 'package:railreserve/reserve.dart';
import 'package:railreserve/settings.dart';

void main() {
  // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  //   // systemNavigationBarColor: Colors.blue, // navigation bar color
  //   statusBarColor: Colors.black.withAlpha(140), // status bar color
  // ));
  runApp(MyApp());
}

class Destination {
  const Destination(this.title, this.icon);
  final String title;
  final IconData icon;
}

const List<Destination> allDestinations = <Destination>[
  Destination('הגדרות', Icons.settings),
  Destination('שובר פעיל', Icons.qr_code),
  reserve_destination,
];

class DestinationView extends StatefulWidget {
  const DestinationView({Key key, this.destination}) : super(key: key);

  final Destination destination;

  @override
  _DestinationViewState createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rail Reserve',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // brightness: Brightness.dark,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey();

  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;

  Future<bool> didPopRoute() async {
    final NavigatorState navigator = widget.navigatorKey.currentState;
    assert(navigator != null);
    return await navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SettingsView(),
          ActiveVoucherView(),
          ReserveView(
            ticketReservedCb: () {
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
          // WillPopScope(
          //   child: ReserveView(),
          //   onWillPop: () async {
          //     return await didPopRoute();
          //   },
          // ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: allDestinations.map((Destination dest) {
          return BottomNavigationBarItem(
            icon: Icon(dest.icon),
            label: dest.title,
          );
        }).toList(),
      ),
    );
  }
}
