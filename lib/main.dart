import 'package:flutter/material.dart';

void main() => runApp(EpitrackApp());

class EpitrackApp extends StatelessWidget {
  static final List<Show> showsList = List<Show>();

  @override
  Widget build(BuildContext context) {
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

class ShowsScreen extends StatefulWidget {
  @override
  _ShowsScreenState createState() => _ShowsScreenState();
}
class _ShowsScreenState extends State<ShowsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Epitrack | Shows')),
      body: _buildShowsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => NewShowScreen()))
            .then((value){
              setState((){
                //Updates ListView state
              });
            });
        },
        tooltip: 'New show',
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildShowsList() {
    return ListView.builder(
      itemBuilder: (BuildContext context, int listIndex) {
        //Adds dividers between items
        if (listIndex.isOdd) {
          return Divider();
        }

        final int showIndex = listIndex ~/ 2; //Adjusts index to take into account the dividers in the list
        
        //Only adds tiles while there are still items in the list
        if(showIndex < EpitrackApp.showsList.length){
          return ListTile(title: Text(EpitrackApp.showsList[showIndex]._name));
        }
        else{
          return null;
        }
      }
    );
  }
}

class NewShowScreen extends StatefulWidget {
  @override
  _NewShowScreenState createState() => _NewShowScreenState();
}
class _NewShowScreenState extends State<NewShowScreen> {
  final _formKey = GlobalKey<FormState>();
  Show _newShow = Show("");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Epitrack | New show')),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'Name'),
              validator: (String value) {
                if (value.isEmpty) {
                  return "Name can't be empty";
                }
                return null;
              },
              onSaved: (String value) {
                _newShow.setName(value);
              },
            ),
            RaisedButton(
              child: Text('Add'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  //Form is okay, add show
                  _formKey.currentState.save();
                  EpitrackApp.showsList.add(_newShow);
                  print("Added $_newShow!");  //DEBUG PRINT
                  Navigator.pop(context, _newShow); //Returns to previous screen
                } else {
                  //Form isn't okay
                  print('Error adding show!');  //DEBUG PRINT
                }
              },
            )
          ]
        )
      )
    );
  }

}

class Show {
  String _name;

  //Constructor
  Show(this._name);

  //Name getters/setters
  String getName() => this._name;
  void setName(String newName) => this._name = newName;

  @override
  String toString() => this._name;
}
