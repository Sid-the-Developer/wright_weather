import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            'Settings',
            style: GoogleFonts.questrial(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor:
              dark ? Color(0xff24A4FE) : Theme.of(context).primaryColorLight,
        ),
        body: ListView(
          physics: BouncingScrollPhysics(),
          children: ListTile.divideTiles(context: context, tiles: [
            SwitchListTile(
              title: Text(
                'Units',
                style: GoogleFonts.lato(fontSize: 18),
              ),
              subtitle: Text('Show temperatures in '
                  '${celsius ? 'Celsius' : 'Fahrenheit'}'),
              value: celsius,
              onChanged: (value) {
                setState(() => celsius = value);
                prefs.setBool('celsius', value);
              },
            ),
            SwitchListTile(
                title: Text('Dark Mode', style: GoogleFonts.lato(fontSize: 18)),
                value: dark,
                onChanged: (value) {
                  setState(() => dark = value);
                  prefs.setBool('dark', value);
                }),
            SwitchListTile(
              title: Text(
                'Open to detailed view',
                style: GoogleFonts.lato(fontSize: 18),
              ),
              value: detailedView,
              onChanged: (value) {
                setState(() => detailedView = value);
                prefs.setBool('detailedView', value);
              },
            )
          ]).toList(),
        ));
  }
}
