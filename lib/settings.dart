import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatefulWidget {
  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("הגדרות"),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: () async {
          var prefs = await SharedPreferences.getInstance();
          var mobileNo = "";
          var nationalId = "";
          try {
            mobileNo = prefs.getString("mobileNo");
          } catch (_) {}
          try {
            nationalId = prefs.getString("nationalId");
          } catch (_) {}
          return [prefs, mobileNo, nationalId];
        }(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Text("");
          }

          var prefs = snapshot.data[0];
          var mobileNo = snapshot.data[1];
          var nationalId = snapshot.data[2];

          var mobileNoController = TextEditingController(text: mobileNo);
          var nationalIdController = TextEditingController(text: nationalId);

          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "מספר טלפון:",
                  textDirection: TextDirection.rtl,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 42.0),
                  child: TextField(
                    controller: mobileNoController,
                    onChanged: (val) async {
                      await prefs.setString("mobileNo", val);
                    },
                    keyboardType: TextInputType.number,
                  ),
                ),
                Text(
                  "מספר ת.ז.:",
                  textDirection: TextDirection.rtl,
                ),
                TextField(
                  controller: nationalIdController,
                  keyboardType: TextInputType.number,
                  onChanged: (val) async {
                    await prefs.setString("nationalId", val);
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
