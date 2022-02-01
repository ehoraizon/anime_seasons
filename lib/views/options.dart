import 'dart:io';

import 'package:anime_seasons/database/api.dart';
import 'package:anime_seasons/models/models.dart';
import 'package:flutter/material.dart';

class OptionsWidget extends StatefulWidget {
  final ApiDB apiDB;

  const OptionsWidget(this.apiDB, {Key? key}) : super(key: key);

  @override
  _OptionsWidgetState createState() => _OptionsWidgetState();
}

class _OptionsWidgetState extends State<OptionsWidget> {
  late Language _language;

  @override
  void initState() {
    super.initState();
    _language = widget.apiDB.options.language;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LayoutBuilder(builder: (context, constrains) {
      if (Platform.isWindows) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 20.0, left: 15, bottom: 10),
              child: Text(
                "Sub language :",
                textAlign: TextAlign.left,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 15.0, right: 30),
              child: Divider(
                height: 20,
                thickness: 1.0,
              ),
            ),
            ...Language.values.map((value) => ListTile(
                  title: Text(value.name),
                  leading: Radio<Language>(
                    value: value,
                    groupValue: _language,
                    onChanged: (Language? value) {
                      setState(() {
                        _language = value!;
                        widget.apiDB.options.language = value;
                        widget.apiDB.updateOption();
                      });
                    },
                  ),
                )),
          ],
        );
      } else {
        return Container(
            margin: const EdgeInsets.only(top: 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 20.0, left: 15, bottom: 10),
                  child: Text(
                    "Sub language :",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 15.0, right: 30),
                  child: Divider(
                    height: 20,
                    thickness: 1.0,
                  ),
                ),
                ...Language.values.map((value) => ListTile(
                      title: Text(value.name),
                      leading: Radio<Language>(
                        value: value,
                        groupValue: _language,
                        onChanged: (Language? value) {
                          setState(() {
                            _language = value!;
                            widget.apiDB.options.language = value;
                            widget.apiDB.updateOption();
                          });
                        },
                      ),
                    )),
              ],
            ));
      }
    }));
  }
}
