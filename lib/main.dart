import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:json_annotation/json_annotation.dart';

part 'main.g.dart';

void main() => runApp(EpitrackApp());

class EpitrackApp extends StatelessWidget {
  static List<Show> showsList = List<Show>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Epitrack',
      theme: ThemeData(
        primaryColor: Constants.mainColor,
        canvasColor: Constants.backgroundColor,
        accentColor: Constants.mainColor
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
    return FutureBuilder<bool>(  // FutureBuilder waits for the shows to be loaded from the JSON file
      future: Utils.loadShowsFromJson(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot){
        if(snapshot.hasData){  // Shows properly loaded, show list
          return Scaffold(
            appBar: AppBar(title: Text('Epitrack | Shows', style: TextStyle(fontSize: Constants.appbarFontSize))),
            drawer: Utils.buildEpitrackDrawer(context),
            body: _buildShowsList(),
            floatingActionButton: FloatingActionButton(
              tooltip: 'New show',
              child: Icon(Icons.add),
              backgroundColor: Constants.mainColor,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => NewShowScreen()))
                  .then((_){
                    setState((){
                      //Updates ListView state
                    });
                  });
              },
            )
          );
        }
        else{  // Shows not loaded yet, show temporary  loading screen
          return Scaffold(
            appBar: AppBar(title: Text('Epitrack | Shows')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('Loading saved shows...')
                  )
                ],
              ))
          );
        }
      }
    );
    
  }

  Widget _buildShowsList() {
    return ListView.builder(
      itemBuilder: (BuildContext context, int listIndex) {
        // Adds dividers between items
        if (listIndex.isOdd) {
          return Divider();
        }

        final int showIndex = listIndex ~/ 2; // Adjusts index to take into account the dividers in the list
        
        // Only adds tiles while there are still items in the list
        if(showIndex < EpitrackApp.showsList.length){
          String showName = EpitrackApp.showsList[showIndex].name;
          return ListTile(
            title: Text(showName),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => ShowDetailsScreen(showName)))
              .then((_){
                setState((){
                  // Updates list
                });
              });
            }
          );
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
      body: _buildNewShowForm()
    );
  }

  Widget _buildNewShowForm(){
    return Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Row( children:[
              Text('Name: '),
              Container(width: 300, child: TextFormField(
                validator: Validators.showNameValidator,
                onSaved: (String value) {
                  _newShow.setName(value);
                },
              )),
            ]),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Add'),
              onPressed: () {
                if (_formKey.currentState.validate()) {  //Form is okay, add show
                  _formKey.currentState.save();

                  EpitrackApp.showsList.add(_newShow);
                  Utils.saveShowsToJson();
                  Navigator.pop(context, _newShow);
                } else {  //Form isn't okay
                  print('Error adding show!');
                }
              },
            )
          ]
        )
      );
  }

}

class ShowDetailsScreen extends StatefulWidget{
  final String _showName;

  //Constructor
  ShowDetailsScreen(this._showName);

  @override
  _ShowDetailsScreenState createState() => _ShowDetailsScreenState(this._showName);
}
class _ShowDetailsScreenState extends State<ShowDetailsScreen>{
  Show _show;

  //Constructor
  _ShowDetailsScreenState(String showName){
    _show = Utils.getShowByName(showName);
  }

  @override
  Widget build(BuildContext context){
    return DefaultTabController(
        length: 3,
        child: Scaffold( 
          appBar: AppBar(
            title: Text('Epitrack | ' + _show.getName(), style: TextStyle(fontSize: Constants.appbarFontSize)),
            bottom: TabBar(
              tabs: [
                //Tab headers
                Tab(text: 'Details'),
                Tab(text: 'Seasons'),
                Tab(text: 'Episodes')
              ]
            )
          ),
          body: TabBarView(
            children: [
              //Tab content
              _buildDetailsTab(),
              _buildSeasonsTab(),
              _buildEpisodesTab(),
            ],
          )
        )
    );
  }

  Widget _buildDetailsTab(){
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Edit show',
        child: Icon(Icons.edit),
        backgroundColor: Constants.mainColor,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => EditShowScreen(this._show)))
            .then((_){
              setState((){
                //Updates details
              });
            });
        },
      ),
      body: Column(
        children: [
          Text('Name: ' + _show.getName()),
          Text('Number of seasons: ' + _show.getNumberOfSeasons().toString()),
          Text('Number of episodes: ' + _show.getNumberOfEpisodes().toString()),
          RaisedButton(
            color: Constants.highlightColor,
            child: Text('Delete show'),
            onPressed: (){
              EpitrackApp.showsList.remove(_show);
              Utils.saveShowsToJson();
              Navigator.pop(context);
            },
          )
        ]
      )
    );
  }

  Widget _buildSeasonsTab(){
    return Scaffold(
      body: _buildSeasonsList(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New season',
        child: Icon(Icons.add),
        backgroundColor: Constants.mainColor,
        onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NewSeasonScreen(_show)))
            .then((_){
              setState((){
                //Updates ListView state
              });
            });
        }
      )
    );
  }

  Widget _buildSeasonsList(){
    return ListView.builder(
      itemBuilder: (BuildContext context, int listIndex){
        // Adds dividers between items
        if(listIndex.isOdd){
          return Divider();
        }

        final int seasonIndex = listIndex ~/ 2; // Adjusts index to take into account the dividers in the list

        if(seasonIndex < _show.getSeasons().length){
          Season _season = _show.getSeasons()[seasonIndex];

          return ListTile(
            title: Text(_season.toString()),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SeasonDetailsScreen(_season, _show)))
              .then((_){
                setState((){
                  // Update list
                });
              });
            }
          );
        }
        else{
          return null;
        }

      }
    );
  }

  Widget _buildEpisodesTab(){
    return Scaffold(
      body: _buildEpisodesList(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New episode',
        child: Icon(Icons.add),
        backgroundColor: Constants.mainColor,
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => NewEpisodeScreen(_show)))
          .then((_){
            setState((){
              //Updates list state
            });
          });
        },
      ),
    );
  }

  Widget _buildEpisodesList(){
    return ListView.builder(
      itemBuilder: (BuildContext context, int listIndex){
        // Adds dividers between items
        if(listIndex.isOdd){
          return Divider();
        }
        
        // Builds a list of ExpansionTiles with all seasons and episodes
        List<ExpansionTile> seasonsList = List<ExpansionTile>();
        // Episodes with no season (if there are any)
        if(_show.getEpisodes().isNotEmpty){
          ExpansionTile noSeasonTile = ExpansionTile(
            title: Text('No season'),
            backgroundColor: Constants.highlightColor,
            children: _show.getEpisodes().map((episode){
              return ListTile(
                title: Text(episode.toString()),
                trailing: IconButton(
                  icon: Icon(episode.getWatched() ? Icons.check_circle : Icons.check_circle_outline),
                  color: episode.getWatched() ? Constants.mainColor : null,
                  onPressed: (){
                    setState((){
                      episode.setWatched(!episode.getWatched());  // Toggles watched
                      Utils.saveShowsToJson();
                    });
                  }
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EpisodeDetailsScreen(episode, null, _show)))
                  .then((_){
                    setState((){
                      // Update list
                    });
                  });
                }
              );
            }).toList().expand((element) => [element, Divider(thickness: 0.75)]).toList()
          );
          seasonsList.add(noSeasonTile);
        }
        // Episodes in each season
        for(Season season in _show.getSeasons()){
          ExpansionTile seasonTile = ExpansionTile(
            title: Text(season.toString()),
            backgroundColor: Constants.highlightColor,
            children: season.getEpisodes().map((episode){
              return ListTile(
                title: Text('S'+season.getNumber().toString()+episode.toString()),
                trailing: IconButton(
                  icon: Icon(episode.getWatched() ? Icons.check_circle : Icons.check_circle_outline),
                  color: episode.getWatched() ? Constants.mainColor : null,
                  onPressed: (){
                    setState((){
                      episode.setWatched(!episode.getWatched());  // Toggles watched
                    });
                  }
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EpisodeDetailsScreen(episode, season, _show)))
                  .then((_){
                    setState((){
                      // Update list
                    });
                  });
                }
              );
            }).toList().expand((element) => [element, Divider(thickness: 0.75)]).toList()
          );
          seasonsList.add(seasonTile);
        }

        final int tileIndex = listIndex ~/ 2; // Adjusts index to take into account the dividers in the list
        if(tileIndex < seasonsList.length){
          return seasonsList[tileIndex];
        }
        else{
          return null;
        }

      },
    );
  }
  
}

class EditShowScreen extends StatefulWidget{
  final Show _show;

  EditShowScreen(this._show);

  @override
  _EditShowScreenState createState() => _EditShowScreenState(this._show);
}
class _EditShowScreenState extends State<EditShowScreen>{
  final Show _show;

  final _formKey = GlobalKey<FormState>();
  String _showName;

  _EditShowScreenState(this._show){
    this._showName = this._show.getName();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Epitrack | Editing $_show', style: TextStyle(fontSize: Constants.appbarFontSize))),
      body: _buildEditShowForm()
    );
  }

  Widget _buildEditShowForm(){
    return Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Row( children:[
              Text('Name: '),
              Container(width: 300, child: TextFormField(
                initialValue: _showName,
                validator: Validators.showNameValidator,
                onSaved: (String value) {
                  this._showName = value;
                },
              )),
            ]),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Save changes'),
              onPressed: () {
                if (_formKey.currentState.validate()) {  //Form is okay, add show
                  _formKey.currentState.save();

                  _show.setName(_showName);

                  Utils.saveShowsToJson();
                  Navigator.pop(context);
                } 
                else {  //Form isn't okay
                  print('Error adding show!');
                }
              },
            )
          ]
        )
      );
  }
}

class NewSeasonScreen extends StatefulWidget {
  final Show _show;

  // Constructor
  NewSeasonScreen(this._show);

  @override
  _NewSeasonScreenState createState() => _NewSeasonScreenState(this._show);
}
class _NewSeasonScreenState extends State<NewSeasonScreen> {
  Show _show;
  final _formKey = GlobalKey<FormState>();
  String _newSeasonName;

  // Constructor
  _NewSeasonScreenState(this._show);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Epitrack | New season', style: TextStyle(fontSize: Constants.appbarFontSize))),
      body: _buildNewSeasonForm()
    );
  }

  Widget _buildNewSeasonForm(){
    return Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'Name'),
              onSaved: (String value) {
                _newSeasonName = value;
              },
            ),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Add'),
              onPressed: () {
                if (_formKey.currentState.validate()) {  // Form is okay, add season
                  _formKey.currentState.save();
                  _show.addSeason(name: _newSeasonName);
                  Utils.saveShowsToJson();
                  Navigator.pop(context);
                } else {  // Form isn't okay
                  print('Error adding season!');
                }
              },
            )
          ]
        )
      );
  }

}

class SeasonDetailsScreen extends StatefulWidget{
  final Season _season;
  final Show _show;

  SeasonDetailsScreen(this._season, this._show);

  @override
  _SeasonDetailsScreenState createState() => _SeasonDetailsScreenState(this._season, this._show);
}
class _SeasonDetailsScreenState extends State<SeasonDetailsScreen>{
  Season _season;
  Show _show;

  _SeasonDetailsScreenState(this._season, this._show);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Epitrack | S' + _season.getNumber().toString() + ' of $_show', style: TextStyle(fontSize: Constants.appbarFontSize))),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Edit season',
        child: Icon(Icons.edit),
        backgroundColor: Constants.mainColor,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => EditSeasonScreen(this._season, this._show)))
            .then((_){
              setState((){
                //Updates details
              });
            });
        },
      ),
      body: Column(
        children: [
          Text('Season name: ' + _season.getName()),
          Text('Season number: ' + _season.getNumber().toString()),
          Text('Number of episodes: ' + _season.getNumberOfEpisodes().toString()),
          RaisedButton(
            color: Constants.highlightColor,
            child: Text('Delete season'),
            onPressed: (){
              _show.getSeasons().remove(_season);
              Utils.fixListNumbers(_show.getSeasons());

              Utils.saveShowsToJson();
              Navigator.pop(context);
            },
          )
        ]
     )
    );
  }
}

class EditSeasonScreen extends StatefulWidget{
  final Season _season;
  final Show  _show;

  EditSeasonScreen(this._season, this._show);

  @override
  _EditSeasonScreenState createState() => _EditSeasonScreenState(this._season, this._show);
}
class _EditSeasonScreenState extends State<EditSeasonScreen>{
  final Season _season;
  final Show _show;

  final _formKey = GlobalKey<FormState>();
  String _seasonName;

  _EditSeasonScreenState(this._season, this._show){
    this._seasonName = this._season.getName();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Epitrack | Editing S' + _season.getNumber().toString() + ' of $_show', style: TextStyle(fontSize: Constants.appbarFontSize))),
      body: _buildEditSeasonForm()
    );
  }

  Widget _buildEditSeasonForm(){
    return Form(
      key: this._formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            initialValue: this._season.getName(),
            onSaved: (String value) {
              this._seasonName = value;
            },
          ),
          RaisedButton(
            color: Constants.highlightColor,
            child: Text('Save changes'),
            onPressed: () {
              if (this._formKey.currentState.validate()) {  // Form is okay, add season
                this._formKey.currentState.save();
                this._season.setName(this._seasonName);

                Utils.saveShowsToJson();
                Navigator.pop(context);
              } 
              else {  // Form isn't okay
                print('Error adding season!');
              }
            },
          )
        ]
      )
    );
  }
}

class NewEpisodeScreen extends StatefulWidget{
  final Show _show;

  // Constructor
  NewEpisodeScreen(this._show);

  @override
  _NewEpisodeScreenState createState() => _NewEpisodeScreenState(this._show);
}
class _NewEpisodeScreenState extends State<NewEpisodeScreen>{
  Show _show;
  final _formKey = GlobalKey<FormState>();
  List<Season> _seasons = List<Season>();  // All seasons, including "no season"
  
  String _newEpisodeName;
  int _newEpisodeDuration;
  Season _selectedSeason;  // Season currently selected in the dropdown menu
  String _selectedType;  // Episode type currently selected in the dropdown menu
  DateAndTime _selectedDateAndTime = DateAndTime();  //Date and time currently selected

  // Constructor
  _NewEpisodeScreenState(Show show){
    this._show = show;

    this._seasons.add(Season(0, "No season"));
    for (Season season in _show.getSeasons()){
      this._seasons.add(season);
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Epitrack | New episode', style: TextStyle(fontSize: Constants.appbarFontSize))),
      body: _buildNewEpisodeForm()
    );
  }

  Widget _buildNewEpisodeForm(){
    return Form(
      key: _formKey,
      child: SingleChildScrollView(child: Column(
        children: <Widget>[
          Row(children: [  // Episode name
            Text('Name: '),
            Container(width: 300, child: TextFormField(  // Episode name text box
              decoration: InputDecoration(labelText: 'Name'),   
              onSaved: (String value){
                _newEpisodeName = value;
              },
            ))
          ]), 
          Row(children: [  // Season
            Text('Season: '),
            DropdownButton(  // Season dropdown
              hint: Text('Select a season'),
              value: _selectedSeason,
              onChanged: (newValue){
                setState((){
                  _selectedSeason = newValue;
                });
              },
              items: _seasons.map((season){
                return DropdownMenuItem(
                  child: new Text(season.getNumber() == 0 ? season.getName() : season.toString()),  // Returns only name for season 0 (no season)
                  value: season
                );
              }).toList()
            ),
          ]),
          Row(children: [  // Episode type
            Text('Type: '),
            DropdownButton(  // Episode type dropdown
              hint: Text('Select an episode type'),
              value: _selectedType,
              onChanged: (newValue){
                setState((){
                  _selectedType = newValue;
                });
              },
              items: Constants.EPISODETYPES.keys.map((type){
                return DropdownMenuItem(
                  child: new Text(type),
                  value: Constants.EPISODETYPES[type]
                );
              }).toList()
            ),
          ]),       
          Row(children: [  // Airing date
            Text(_selectedDateAndTime.getYear() == null ? 'Airing date: - ' : 'Airing date: ${_selectedDateAndTime.getDateString()}'),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Select date'),
              onPressed: () async{
                DateTime _date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(-5000), lastDate: DateTime(5000));
                setState((){
                  if(_date != null){  // If a date was selected
                    _selectedDateAndTime.setYear(_date.year);
                    _selectedDateAndTime.setMonth(_date.month);
                    _selectedDateAndTime.setDay(_date.day);
                  }
                });
              },
            )
          ],),
          Row(children: [  // Airing time
            Text(_selectedDateAndTime.getHour() == null ? 'Airing time: - ' : 'Airing time: ${_selectedDateAndTime.getTimeString()}'),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Select time'),
              onPressed: () async{
                TimeOfDay _time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 0, minute: 0));
                setState((){
                  if(_time != null){  // If a time was selected
                    _selectedDateAndTime.setHour(_time.hour);
                    _selectedDateAndTime.setMinute(_time.minute);
                  }
                });
              },
            )
          ],),
          Row(children: [  // Duration
            Text('Duration: '),
            Container(width: 100, child: TextFormField(
              decoration: InputDecoration(labelText: 'Duration'),
              keyboardType: TextInputType.number,
              inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
              onSaved: (String value){
                if(value != ''){
                  _newEpisodeDuration = int.parse(value);
                }
              }
            )),
            Text('seconds')
          ]),
          RaisedButton(  // Submit button
            color: Constants.highlightColor,
            child: Text('Add episode'),
            onPressed: (){
              if(_formKey.currentState.validate()){  // Form is okay, add episode
                _formKey.currentState.save();

                _show.addEpisode(name: _newEpisodeName, 
                                season: _selectedSeason, 
                                type: _selectedType == null ? Constants.EPISODETYPES['Episode'] : _selectedType,  // Defaults to type 'Episode'
                                airingDateAndTime: _selectedDateAndTime,
                                durationMinutes: _newEpisodeDuration
                                );
                Utils.saveShowsToJson();  // Saves to persistent storage
                Navigator.pop(context);
              }
              else{  // Form isn't okay
                print('Error adding episode!');
              }
            },
          )
        ]
      )
    ));
  }

}

class EpisodeDetailsScreen extends StatefulWidget{
  final Episode _episode;
  final Season _season;
  final Show _show;

  // Constructor
  EpisodeDetailsScreen(this._episode, this._season, this._show);

  @override
  _EpisodeDetailsScreenState createState() => _EpisodeDetailsScreenState(this._episode, this._season, this._show);
}
class _EpisodeDetailsScreenState extends State<EpisodeDetailsScreen>{
  Episode _episode;
  Season _season;
  Show _show;

  _EpisodeDetailsScreenState(this._episode, this._season, this._show);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: _season == null ?   // Remove season number from appbar if there is no season
          Text('Epitrack | E' + _episode.getNumber().toString() + ' $_show', style: TextStyle(fontSize: Constants.appbarFontSize))
        : Text('Epitrack | S' + _season.getNumber().toString() + 'E' + _episode.getNumber().toString() + ' $_show', style: TextStyle(fontSize: Constants.appbarFontSize))),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Edit episode',
        child: Icon(Icons.edit),
        backgroundColor: Constants.mainColor,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => EditEpisodeScreen(this._episode, this._season, this._show)))
            .then((_){
              setState((){
                //Updates details
              });
            });
        },
      ),
      body: Column(
        children: [
          Text('Name: ' + _episode.getName()),
          Text('Number: ' + _episode.getNumber().toString()),
          Text('Type: ' + Constants.EPISODETYPES.keys.singleWhere((key) => Constants.EPISODETYPES[key] == _episode.getType()) ),
          Text('Watched: ' + _episode.watched.toString()),
          Text('Aired on: '
              + (_episode.getAiringDateAndTime().getYear() == null ? ' - ' : _episode.getAiringDateAndTime().getDateString())
              + (_episode.getAiringDateAndTime().getHour()== null ? '' : ' at ' + _episode.getAiringDateAndTime().getTimeString())),
          Text('Duration: ' + (_episode.getDuration() == null ? ' - ' : '${_episode.getDuration()} minutes')),
          RaisedButton(
            color: Constants.highlightColor,
            child: Text('Delete episode'),
            onPressed: (){
              if(_season == null){  // Episode has no season, remove from show's list
                _show.getEpisodes().remove(_episode);
                Utils.fixListNumbers(_show.getEpisodes());
              }
              else{  // Episode has a season, remove from season's list
                _season.getEpisodes().remove(_episode);
                Utils.fixListNumbers(_season.getEpisodes());
              }

              Utils.saveShowsToJson();
              Navigator.pop(context);
            },
          )
        ],
      )
    );
  }
}

class EditEpisodeScreen extends StatefulWidget{
  final Episode _episode;
  final Season _season;
  final Show _show;

  EditEpisodeScreen(this._episode, this._season, this._show);

  @override
  _EditEpisodeScreenState createState() => _EditEpisodeScreenState(this._episode, this._season, this._show);
}
class _EditEpisodeScreenState extends State<EditEpisodeScreen>{
  final Episode _episode;
  final Season _season;
  final Show _show;

  final _formKey = GlobalKey<FormState>();
  List<Season> _seasons = List<Season>();  // All seasons, including "no season"
  
  String _episodeName;
  int _episodeDuration;
  Season _selectedSeason;  // Season currently selected in the dropdown menu
  String _selectedType;  // Episode type currently selected in the dropdown menu
  DateAndTime _selectedDateAndTime = DateAndTime();  //Date and time currently selected

  _EditEpisodeScreenState(this._episode, this._season, this._show){
    this._seasons.add(Season(0, "No season"));
    for (Season season in this._show.getSeasons()){
      this._seasons.add(season);
    }

    _episodeName = _episode.getName();
    _episodeDuration = _episode.getDuration();
    _selectedSeason = this._season == null ? this._seasons[0] : this._season;
    _selectedType = this._episode.getType();
    _selectedDateAndTime = this._episode.getAiringDateAndTime();

  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: _season == null ?   // Remove season number from appbar if there is no season
                        Text('Epitrack | Editing E' + _episode.getNumber().toString() + ' of $_show', style: TextStyle(fontSize: Constants.appbarFontSize))
                      : Text('Epitrack | Editing S' + _season.getNumber().toString() + 'E' + _episode.getNumber().toString() + ' of $_show', style: TextStyle(fontSize: Constants.appbarFontSize))),
      body: _buildEditEpisodeForm()
    );
  }

  Widget _buildEditEpisodeForm(){
    return Form(
      key: _formKey,
      child: SingleChildScrollView(child: Column(
        children: <Widget>[
          Row(children: [  // Episode name
            Text('Name: '),
            Container(width: 300, child: TextFormField(  // Episode name text box
              initialValue: _episodeName,  
              onSaved: (String value){
                _episodeName = value;
              },
            ))
          ]), 
          Row(children: [  // Season
            Text('Season: '),
            DropdownButton(  // Season dropdown
              hint: Text('Select a season'),
              value: _selectedSeason,
              onChanged: (newValue){
                setState((){
                  _selectedSeason = newValue;
                });
              },
              items: _seasons.map((season){
                return DropdownMenuItem(
                  child: new Text(season.getNumber() == 0 ? season.getName() : season.toString()),  // Returns only name for season 0 (no season)
                  value: season
                );
              }).toList()
            ),
          ]),
          Row(children: [  // Episode type
            Text('Type: '),
            DropdownButton(  // Episode type dropdown
              hint: Text('Select an episode type'),
              value: _selectedType,
              onChanged: (newValue){
                setState((){
                  _selectedType = newValue;
                });
              },
              items: Constants.EPISODETYPES.keys.map((type){
                return DropdownMenuItem(
                  child: new Text(type),
                  value: Constants.EPISODETYPES[type]
                );
              }).toList()
            ),
          ]),       
          Row(children: [  // Airing date
            Text(_selectedDateAndTime.getYear() == null ? 'Airing date: - ' : 'Airing date: ${_selectedDateAndTime.getDateString()}'),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Select date'),
              onPressed: () async{
                DateTime _date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(-5000), lastDate: DateTime(5000));
                setState((){
                  if(_date != null){  // If a date was selected
                    _selectedDateAndTime.setYear(_date.year);
                    _selectedDateAndTime.setMonth(_date.month);
                    _selectedDateAndTime.setDay(_date.day);
                  }
                });
              },
            )
          ],),
          Row(children: [  // Airing time
            Text(_selectedDateAndTime.getHour() == null ? 'Airing time: - ' : 'Airing time: ${_selectedDateAndTime.getTimeString()}'),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Select time'),
              onPressed: () async{
                TimeOfDay _time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 0, minute: 0));
                setState((){
                  if(_time != null){  // If a time was selected
                    _selectedDateAndTime.setHour(_time.hour);
                    _selectedDateAndTime.setMinute(_time.minute);
                  }
                });
              },
            )
          ],),
          Row(children: [  // Duration
            Text('Duration: '),
            Container(width: 100, child: TextFormField(
              initialValue: _episodeDuration == null ? '' : _episodeDuration.toString(),
              keyboardType: TextInputType.number,
              inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
              onSaved: (String value){
                if(value != ''){
                  _episodeDuration = int.parse(value);
                }
              }
            )),
            Text('seconds')
          ]),
          RaisedButton(  // Submit button
            color: Constants.highlightColor,
            child: Text('Save changes'),
            onPressed: (){
              if(_formKey.currentState.validate()){  // Form is okay, add episode
                _formKey.currentState.save();

                if(_selectedSeason == this._season || (_selectedSeason.getName() == 'No season' && this._season == null)){  // Same season, just update values
                  _episode.setName(_episodeName);
                  _episode.setType(_selectedType);
                  _episode.setAiringDateAndTime(_selectedDateAndTime);
                  _episode.setDuration(_episodeDuration);

                  Utils.saveShowsToJson();
                  Navigator.pop(context);
                }
                else{   // Different season, remove from the current one and readd to the new one
                  
                  // Removes the episode from the appropriate list
                  if(this._season == null){
                    _show.getEpisodes().remove(this._episode);
                  }
                  else{
                    _season.getEpisodes().remove(this._episode);
                  }

                  // Readds the episode with the new changes
                  _show.addEpisode(
                    name: _episodeName, 
                    season: _selectedSeason, 
                    type: _selectedType == null ? Constants.EPISODETYPES['Episode'] : _selectedType,  // Defaults to type 'Episode'
                    watched: this._episode.getWatched(),
                    airingDateAndTime: _selectedDateAndTime,
                    durationMinutes: _episodeDuration
                  );

                  Utils.saveShowsToJson();
                  Navigator.pop(context);
                  Navigator.pop(context);  // Closes the episode details screen too since it now refers to a removed Episode object
                }
              }
              else{  // Form isn't okay
                print('Error adding episode!');
              }
            },
          )
        ]
      )
    ));
  }
}

class UpcomingEpisodesScreen extends StatefulWidget{
  @override
  _UpcomingEpisodesScreenState createState() => _UpcomingEpisodesScreenState();
}
class _UpcomingEpisodesScreenState extends State<UpcomingEpisodesScreen>{
  List<Episode> _allEpisodes = List<Episode>();

  _UpcomingEpisodesScreenState(){
    for(Show show in EpitrackApp.showsList){  // Goes through every show
      for(Episode episode in show.getEpisodes()){  // Adds all the episodes without a season
        _allEpisodes.add(episode);
      }
      for(Season season in show.getSeasons()){  // Adds all the episodes in every season
        for(Episode episode in season.getEpisodes()){
          _allEpisodes.add(episode);
        }
      }
    }
    _allEpisodes.sort(Comparators.compareEpisodesAiringDateAndTime);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Epitrack | Upcoming episodes', style: TextStyle(fontSize: Constants.appbarFontSize))),
      drawer: Utils.buildEpitrackDrawer(context),
      body: ListView.builder(
        itemCount: 2 * _allEpisodes.length,  // Accounts for dividers
        itemBuilder: (BuildContext context, int listIndex){
          // Adds dividers between items
          if(listIndex.isOdd){
            return Divider();
          }

          final int episodeIndex = listIndex ~/ 2; // Adjusts index to take into account the dividers in the list
          final Episode currentEpisode = _allEpisodes[episodeIndex];
          final DateAndTime currentEpisodeDateTime = currentEpisode.getAiringDateAndTime();

          return ListTile(
            title: Text(currentEpisode.toString()),
            trailing: Text(currentEpisodeDateTime.hasDate() == false ? '-' :   // Has no date
                            currentEpisodeDateTime.hasTime() ? '${currentEpisodeDateTime.getDateString()} @ ${currentEpisodeDateTime.getTimeString()}' :  // Has date and time
                            currentEpisodeDateTime.getDateString()),  // Has date, but no time
          );
        },
      )
    );
  }
}


@JsonSerializable(explicitToJson: true)
class Show {
  String name;
  List<Season> seasons = List<Season>();
  List<Episode> episodes = List<Episode>();  // Episodes that don't have a season (e.g. specials, OVAs, etc.)

  // Constructor
  Show(this.name);

  // Name getters/setters
  String getName() => this.name;
  void setName(String newName) => this.name = newName;

  // Returns list of episodes
  List<Episode> getEpisodes() => this.episodes;
  // Adds a new episode using the appropriate episode number
  void addEpisode({String name="", Season season, String type, bool watched, DateAndTime airingDateAndTime, int durationMinutes}){
    if(season == null || season.getName() == "No season"){  // No season selected, use show's base episode list
      int _nextEpisodeNumber;
      Iterable<Episode> _sameTypeEpisodes = this.episodes.where( (episode){return episode.getType() == type;} );

      if(_sameTypeEpisodes.isEmpty){
        _nextEpisodeNumber = 1;
      }
      else{
        _nextEpisodeNumber = _sameTypeEpisodes.last.getNumber() + 1;
      }

      this.episodes.add(Episode(_nextEpisodeNumber, name: name, type: type, watched: watched, airingDateAndTime: airingDateAndTime, durationMinutes: durationMinutes));
    }
    else{  // Calls the season's addEpisode() function
      season.addEpisode(name: name, type: type, watched: watched, airingDateAndTime: airingDateAndTime, durationMinutes: durationMinutes);
    }

    
  }

  // Returns list of seasons
  List<Season> getSeasons() => this.seasons;
  // Adds a new season using the appropriate season number
  void addSeason({String name=""}){
    int _nextSeasonNumber;
    
    if(this.seasons.isEmpty){
      _nextSeasonNumber = 1;
    }
    else{
      _nextSeasonNumber = this.seasons.last.getNumber() + 1;
    }

    this.seasons.add(Season(_nextSeasonNumber, name));
  }
  // Returns the season with the given name
  Season getSeasonByName(String name){
    return seasons.singleWhere((element){
      return element.name == name;
    });
  }

  // Returns the number of seasons the show has
  int getNumberOfSeasons(){
    return this.seasons.length;
  }
  // Returns the total number of episodes (show itself and each season)
  int getNumberOfEpisodes(){
    int totalNumber = this.episodes.length;
    for(Season season in this.seasons){
      totalNumber += season.getEpisodes().length;
    }

    return totalNumber;
  }

  @override
  String toString() => this.name;

  factory Show.fromJson(Map<String, dynamic> json) => _$ShowFromJson(json);
  Map<String, dynamic> toJson() => _$ShowToJson(this);

}

@JsonSerializable(explicitToJson: true)
class Season{
  int number;
  String name;
  List<Episode> episodes = List<Episode>();

  Season(this.number, this.name);

  int getNumber() => this.number;
  void setNumber(int number) => this.number = number;

  String getName() => this.name;
  void setName(String name) => this.name = name;

  // Returns list of episodes
  List<Episode> getEpisodes() => this.episodes;
  // Adds a new episode using the appropriate season number
  void addEpisode({String name="", String type='E', bool watched, DateAndTime airingDateAndTime, int durationMinutes}){
    int _nextEpisodeNumber;
    List<Episode> _sameTypeEpisodes = this.episodes.where( (episode){return episode.getType() == type;} ).toList();
    
    if(_sameTypeEpisodes.isEmpty){
      _nextEpisodeNumber = 1;
    }
    else{
      _nextEpisodeNumber = _sameTypeEpisodes.last.getNumber() + 1;
    }

    this.episodes.add(Episode(_nextEpisodeNumber, name: name, type: type, watched: watched, airingDateAndTime: airingDateAndTime, durationMinutes: durationMinutes));
  }

  // Returns the total number of episodes in the season
  int getNumberOfEpisodes(){
    return this.episodes.length;
  }

  // Prints number of season and name if it has one (e.g. S01: Season Name)
  String toString() => this.name.isEmpty ? 'S'+this.number.toString() : 'S'+this.number.toString()+': '+this.name;

  factory Season.fromJson(Map<String, dynamic> json) => _$SeasonFromJson(json);
  Map<String, dynamic> toJson() => _$SeasonToJson(this);

}

@JsonSerializable(explicitToJson: true)
class Episode{
  int number;
  String name;
  String type;
  bool watched;
  DateAndTime airingDateAndTime;  // Date and time when the episode aired
  int durationMinutes;  // Duration of the episode in minutes

  Episode(int number, {String name="", String type, bool watched=false, DateAndTime airingDateAndTime, int durationMinutes}){
    this.number = number;
    this.name = name;
    type == null ? this.type = Constants.EPISODETYPES['Episode'] : this.type = type;
    this.watched = false;
    this.airingDateAndTime = airingDateAndTime;
    this.durationMinutes = durationMinutes;
  }


  bool getWatched() => this.watched;
  void setWatched(bool newStatus) => this.watched = newStatus;

  String getType() => this.type;
  void setType(String type) => this.type = type;

  int getNumber() => this.number;
  void setNumber(int number) => this.number = number;

  String getName() => this.name;
  void setName(String name) => this.name = name;

  DateAndTime getAiringDateAndTime() => this.airingDateAndTime;
  void setAiringDateAndTime(DateAndTime newDateAndTime) => this.airingDateAndTime = newDateAndTime;

  int getDuration() => this.durationMinutes;
  void setDuration(int newDuration) => this.durationMinutes = newDuration;

  String toString() => this.name.isEmpty ? this.type+this.number.toString() : this.type+this.number.toString()+': '+this.name;


  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
  Map<String, dynamic> toJson() => _$EpisodeToJson(this);

}

// Custom class for time and date that supports JSON encoding/decoding
@JsonSerializable(explicitToJson: true)
class DateAndTime {
  int year, month, day;
  int hour, minute;

  DateAndTime({this.year, this.month, this.day, this.hour, this.minute});

  int getYear() => this.year;
  void setYear(int newYear) => this.year = newYear;

  int getMonth() => this.month;
  void setMonth(int newMonth) => this.month = newMonth;

  int getDay() => this.day;
  void setDay(int newDay) => this.day = newDay;

  int getHour() => this.hour;
  void setHour(int newHour) => this.hour = newHour;

  int getMinute() => this.minute;
  void setMinute(int newMinute) => this.minute = newMinute;

  bool hasDate() => this.year != null;
  bool hasTime() => this.hour != null;

  String getDateString() => '${Utils.padLeadingZeros(this.year, 4)}-${Utils.padLeadingZeros(this.month, 2)}-${Utils.padLeadingZeros(this.day, 2)}';
  String getTimeString() => '${Utils.padLeadingZeros(this.hour, 2)}:${Utils.padLeadingZeros(this.minute, 2)}';

  DateTime getDateTimeObject(){
    if(this.year != null){  // Has a date
      if(this.hour != null){  // Has a date and a time
        return DateTime(this.year, this.month, this.day, this.hour, this.minute);
      }
      else{  // Has a date, but doesn't have a time. Defaults time to 00:00.
        return DateTime(this.year, this.month, this.day, 0, 0);
      }
    }
    else{ // Doesn't have a date
      return null;
    }
  }
  TimeOfDay getTimeOfDayObject(){
    if(this.hour != null){  // Has a time
      return TimeOfDay(hour: this.hour, minute: this.minute);
    }
    else{  // Doesn't have a time
      return null;
    }
  }

  String toString(){
    return '${Utils.padLeadingZeros(this.year, 4)}-${Utils.padLeadingZeros(this.month, 2)}-${Utils.padLeadingZeros(this.day, 2)}, ${Utils.padLeadingZeros(this.hour, 2)}:${Utils.padLeadingZeros(this.minute, 2)}';
  }

  factory DateAndTime.fromJson(Map<String, dynamic> json) => _$DateAndTimeFromJson(json);
  Map<String, dynamic> toJson() => _$DateAndTimeToJson(this);
}

class Constants{
  // Possible types of episodes
  static const EPISODETYPES = {
    'Episode' : 'E',
    'Movie' : 'M',
    'Special' : 'SP',
    'OVA' : 'OVA',
    'Extra' : 'EX',
    'Trailer' : 'T',
    'Miscellaneous' : 'MISC'
  };
  
  // Fonts
  static double appbarFontSize = 17;

  // Theme
  static const Color mainColor = bluegrey;
  static const Color backgroundColor = bluegreyBackground;
  static const Color highlightColor = bluegreyHighlight;

  // Colors
  static const Color red = Colors.red;  // red
  static const Color redBackground = Color(4294954450);  // red[100]
  static const Color redHighlight = Color(4293892762);  // red[200]
  static const Color green = Colors.green;  // green
  static const Color greenBackground = Color(4291356361);  // green[100]
  static const Color greenHighlight = Color(4289058471);  // green[200]
  static const Color blue = Colors.blue;  // blue
  static const Color blueBackground = Color(4290502395);  // blue[100]
  static const Color blueHighlight = Color(4287679225);  // blue[200]
  static const Color grey = Colors.grey;  // grey
  static const Color greyBackground = Color(4294309365);  // grey[100]
  static const Color greyHighlight = Color(4293848814);  // grey[200]
  static const Color bluegrey = Colors.blueGrey;  // bluegrey
  static const Color bluegreyBackground = Color(4291811548);  // bluegrey[100]
  static const Color bluegreyHighlight = Color(4289773253);  // bluegrey[200]
  static const Color orange = Colors.orange;  // orange
  static const Color orangeBackground = Color(4294959282);  // orange[100]
  static const Color orangeHighlight = Color(4294954112);  // orange[200]

}

class Utils{
  // Builds the app's standard drawer
  static Drawer buildEpitrackDrawer(BuildContext context){
    return Drawer(
      child: ListView(
        children:[
          DrawerHeader(
            child: Text('Epitrack')
          ),
          ListTile(  // Shows
            title: Text('Shows'),
            onTap: (){
              Navigator.pop(context);  // Closes drawer

              Navigator.push(context, MaterialPageRoute(builder: (context) => ShowsScreen()));
            },
          ),
          Divider(),
          ListTile(  // Upcoming episodes
            title: Text('Upcoming episodes'),
            onTap: (){
              Navigator.pop(context);  // Closes drawer

              Navigator.push(context, MaterialPageRoute(builder: (context) => UpcomingEpisodesScreen()));
            },
          )
        ]
      )
    );
  }

  // Saves current list of shows to a JSON file for persistent storage
  static void saveShowsToJson() async {
    print('Saving JSON...');
    final dir = await getApplicationDocumentsDirectory();
    final path = dir.path;
    final fileName = 'shows.json';
    File file = File('$path/$fileName');

    // Encodes each show individually and separates them with \n
    String  jsonOutput = "";
    for(Show show in EpitrackApp.showsList){
      jsonOutput += json.encode(show.toJson()) + '\n';
    }

    file.writeAsStringSync(jsonOutput);
    print('JSON saved!');
  }

  // Loads shows from JSON file, replaces current list of shows
  static Future<bool> loadShowsFromJson() async {
    print('Loading JSON...');
    final dir = await getApplicationDocumentsDirectory();
    final path = dir.path;
    final fileName = 'shows.json';
    File file = File('$path/$fileName');

    String jsonInput = file.readAsStringSync();
    List<String> jsonStrings = jsonInput.split('\n');
    List<Show> shows = List<Show>();
    //Decodes each line individually and adds it to the list
    for(String jsonString in jsonStrings){
      if(jsonString.isNotEmpty){
        shows.add(Show.fromJson(json.decode(jsonString)));
      }
    }

    EpitrackApp.showsList = shows;
    print('JSON loaded!');
    return true;  // Set the future data to true to signal loading complete
  }
  
  // Returns a Show object with the given name
  static Show getShowByName(String name){
    return EpitrackApp.showsList.singleWhere((element){
      return element.name == name;
    });
  }

  // Adds zeros to the left of a number until it reaches 'numberOfDigits'. Doesn't add anything if it already has at least 'numberOfDigits' digits.
  static String padLeadingZeros(var input, int numberOfDigits){
    var num = input;
    int inputDigits = 0;
    int zerosToAdd = 0;

    // Special case for numbers with zero before the decimal separator
    if(input >= 0 && input < 1){
      return '0' + input.toString();
    }

    // Counts number of digits on the input number
    while(num >= 1){
      inputDigits += 1;
      num ~/= 10;
    }

    zerosToAdd = numberOfDigits - inputDigits;
    return '0'*zerosToAdd + input.toString();
  }

  // Sets the number for every item in a list in order starting from 'initialNumber'
  static void fixListNumbers(List<dynamic> list, {int initialNumber=1}){
    int currentNumber = initialNumber;

    for(var item in list){
      item.setNumber(currentNumber++);
    }
  }
}

class Validators{
  static String showNameValidator(String value){
    // Tests if name is empty
    if (value.isEmpty) {
      return "Name can't be empty";
    }

    // Tests if there's already a show with the same name
    for(Show show in EpitrackApp.showsList){
      if(show.getName() == value){
        return "There's already a show with that name";
      }
    }

    return null;  // Name is okay
  }
}

class Comparators{

  // Compares two episodes' 'airingDateAndTime'. Returns -1 if a < b, 0 if a = b, 1 if a > b. Pushes episodes with no date to the end.
  static int compareEpisodesAiringDateAndTime(Episode a, Episode b){
    DateTime aDateTime = a.getAiringDateAndTime().getDateTimeObject();
    DateTime bDateTime = b.getAiringDateAndTime().getDateTimeObject();

    // Handles null times
    if(aDateTime == null && bDateTime == null){
      return 0;
    }
    if(bDateTime == null){
      return -1;
    }
    if(aDateTime == null){
      return 1;
    }

    if(aDateTime.isBefore(bDateTime)){
      return -1;
    }
    else if(aDateTime.isAtSameMomentAs(bDateTime)){
      return 0;
    }
    else if(aDateTime.isAfter(bDateTime)){
      return 1;
    }
    else{  // Error
      return null;
    }
  }
}