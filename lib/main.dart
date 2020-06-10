import 'package:flutter/material.dart';


void main() => runApp(EpitrackApp());

class EpitrackApp extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Epitrack',
      theme: ThemeData(
        primaryColor: Colors.green,
        canvasColor: Colors.green[100],
      ),
      home: ShowsScreen(),
    );
  }
}

class ShowsScreen extends StatefulWidget{
  @override
  _ShowsScreenState createState() => _ShowsScreenState();
}

class _ShowsScreenState extends State<ShowsScreen>{

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Epitrack | Shows'),
      ),
      body: _buildShowsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addShow(),
        tooltip: 'New show',
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  //TODO
  Widget _buildShowsList(){}

  //TODO 
  _addShow(){}


}