
import 'package:aws402_flutter/screens/alert_screen.dart';
import 'package:aws402_flutter/widgets/main_widget.dart';
import 'package:aws402_flutter/widgets/topbar_widget.dart';
import 'package:aws402_flutter/widgets/work_widget.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool _isWork = false;

  void _changeWidget (){
    setState(() {
      _isWork = !_isWork;
    });
  }

  void _testAlert(String type){
    Navigator.push(context, MaterialPageRoute(builder: (context) => AlertScreen(type: type)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child:
          TopbarWidget()
      ),
      body: Container(
          padding: EdgeInsets.all(10.0),
          child: _isWork ?
          WorkWidget(onButtonPressed: _changeWidget, showAlert: _testAlert)
          :MainWidget(onButtonPressed: _changeWidget)
      ),
    );
  }
}









