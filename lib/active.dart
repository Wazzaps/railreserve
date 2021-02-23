import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class ActiveVoucherView extends StatefulWidget {
  @override
  _ActiveVoucherViewState createState() => _ActiveVoucherViewState();
}

class _ActiveVoucherViewState extends State<ActiveVoucherView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: () async {
        var prefs = await SharedPreferences.getInstance();
        return [jsonDecode(prefs.getString("activeVoucher")), prefs.getString("activeQR")];
      }(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                "אין שובר פעיל",
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        var voucher = snapshot.data[0];
        var qrData = snapshot.data[1];
        var date = (voucher["TrainDate"] as String).split("T")[0];
        var time = (voucher["TrainDate"] as String).split("T")[1].substring(0, 5);
        return Scaffold(
          appBar: AppBar(
            title: Text("אישור הזמנת שובר"),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.open_in_new),
                tooltip: 'אתר הרכבת',
                onPressed: () {
                  url_launcher.launch(
                      "https://www.rail.co.il/taarif/Pages/QRCode.aspx?GEneratedref=${voucher['GeneretedReferenceValue']}");
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "רכבת: ${voucher['TrainNumber']}",
                    textScaleFactor: 1.3,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                Row(children: [
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.date_range),
                  ),
                  Text(date, textScaleFactor: 1.7),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.timer),
                  ),
                  Text(time, textScaleFactor: 1.7),
                  Spacer(),
                ]),
                Spacer(),
                QrImage(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 320.0,
                  backgroundColor: Colors.white,
                ),
                Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}
