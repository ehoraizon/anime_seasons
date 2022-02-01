import 'dart:io';
import 'package:anime_seasons/views/search.dart';
import 'package:flutter/scheduler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:side_navigation/side_navigation.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_update/auto_update.dart';

import 'package:anime_seasons/views/favorite.dart';
import 'package:anime_seasons/views/options.dart';
import 'package:flutter/material.dart';
import './database/api.dart';
import './views/seasons.dart';

Future main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
    DartVLC.initialize();
  }
  // ApiDB apiDB =
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Navigation(),
    );
  }
}

class Navigation extends StatefulWidget {
  final ApiDB apiDB = ApiDB();

  Navigation({Key? key}) : super(key: key);

  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;
  final TextStyle optionStyle =
      const TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.apiDB.initAsync();
    AutoUpdate.fetchGithubApk("ehoraizon", "test").then((value) {
      SchedulerBinding.instance?.addPostFrameCallback((_) {
        showUpdateDialog(context, value);
      });
    });
  }

  void showUpdateDialog(BuildContext context, Map<dynamic, dynamic> map) {
    if ((map["assetUrl"] as String).isNotEmpty &&
        (map["assetUrl"] as String) != "up-to-date") {
      showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Install App Update ${map["tag"]} ?'),
          content: Text(map["body"] as String),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await AutoUpdate.downloadAndUpdate(map["assetUrl"] as String);
                Navigator.pop(context, 'OK');
              },
              child: const Text('Install'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      SeasonView(widget.apiDB),
      Search(widget.apiDB),
      Favorite(widget.apiDB),
      OptionsWidget(widget.apiDB),
    ];

    Widget appWidget;

    if (Platform.isAndroid) {
      appWidget = Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
              // backgroundColor: Colors.red,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              label: 'Explore',
              // backgroundColor: Colors.green,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorite',
              // backgroundColor: Colors.purple,
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.calendar_today),
            //   label: 'Today',
            //   // backgroundColor: Colors.pink,
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
              // backgroundColor: Colors.pink,
            )
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          unselectedItemColor: Colors.grey[600],
          unselectedLabelStyle:
              TextStyle(color: Colors.grey[600], fontSize: 10),
          onTap: _onItemTapped,
        ),
      );
    } else {
      appWidget = Scaffold(
        body: Row(
          children: [
            /// Pretty similar to the BottomNavigationBar!
            SideNavigationBar(
              expandable: false,
              initiallyExpanded: false,
              selectedIndex: _selectedIndex,
              items: const [
                SideNavigationBarItem(
                  icon: Icons.home,
                  label: 'Home',
                  // backgroundColor: Colors.red,
                ),
                SideNavigationBarItem(
                  icon: Icons.explore_outlined,
                  label: 'Explore',
                  // backgroundColor: Colors.green,
                ),
                SideNavigationBarItem(
                  icon: Icons.favorite,
                  label: 'Favorite',
                  // backgroundColor: Colors.purple,
                ),
                // SideNavigationBarItem(
                //   icon: Icon(Icons.calendar_today),
                //   label: 'Today',
                //   // backgroundColor: Colors.pink,
                // ),
                SideNavigationBarItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  // backgroundColor: Colors.pink,
                ),
              ],
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),

            /// Make it take the rest of the available width
            Expanded(
              child: _widgetOptions.elementAt(_selectedIndex),
            )
          ],
        ),
      );
    }

    return FutureBuilder<bool>(
        future: widget.apiDB.initAsync(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            // showUpdateDialog(context);
            return appWidget;
          } else if (snapshot.hasError) {
            return Scaffold(
                body: Center(
              child: Column(
                children: [
                  SvgPicture.asset(
                    "assets/icons/main_icon.svg",
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: MediaQuery.of(context).size.height / 1.3,
                  ),
                  const Text(
                    "ERROR UNABLE TO OPEN DB",
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  )
                ],
              ),
            ));
          } else {
            return Scaffold(
                body: Container(
              margin: EdgeInsets.only(top: Platform.isAndroid ? 35 : 0),
              child: Center(
                child: SvgPicture.asset(
                  "assets/icons/main_icon.svg",
                  width: MediaQuery.of(context).size.width / 1.2,
                  height: MediaQuery.of(context).size.height / 1.2,
                ),
              ),
            ));
          }
        });
  }
}
