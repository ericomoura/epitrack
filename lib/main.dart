import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
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
        canvasColor: Constants.backgroundColor
      ),
      home: ShowsScreen(),
    );
  }

  //Returns a Show object with the given name
  static Show getShowByName(String name){
    return showsList.singleWhere((element){
      return element.name == name;
    });
  }

  static void saveShowsToJson() async {
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
  }

  static Future<bool> loadShowsFromJson() async {
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
    return true;  // Set the future data to true to signal loading complete
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
      future: EpitrackApp.loadShowsFromJson(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot){
        if(snapshot.hasData){  // Shows properly loaded, show list
          return Scaffold(
            appBar: AppBar(title: Text('Epitrack | Shows')),
            body: _buildShowsList(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => NewShowScreen()))
                  .then((_){
                    setState((){
                      //Updates ListView state
                    });
                  });
              },
              tooltip: 'New show',
              child: Icon(Icons.add),
              backgroundColor: Constants.mainColor,
            ),
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
                  EpitrackApp.saveShowsToJson();  // Saves to persistent storage
                  Navigator.pop(context, _newShow); //Returns to previous screen
                } else {
                  //Form isn't okay
                  print('Error adding show!');  //DEBUG PRINT
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
    _show = EpitrackApp.getShowByName(showName);
  }

  @override
  Widget build(BuildContext context){
    return DefaultTabController(
        length: 3,
        child: Scaffold( 
          appBar: AppBar(
            title: Text('Epitrack | ' + _show.getName()),
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
      body: Column(
        children: [
          Text('Name: ' + _show.getName()),
          Text('Number of seasons: ' + _show.getNumberOfSeasons().toString()),
          Text('Number of episodes: ' + _show.getNumberOfEpisodes().toString()),
          RaisedButton(
            child: Text('Delete show'),
            onPressed: (){
              EpitrackApp.showsList.remove(_show);
              EpitrackApp.saveShowsToJson();
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
            title: Text(_season.toString())
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
                    });
                  }
                )
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
                )
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
      appBar: AppBar(title: Text('Epitrack | New season')),
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
              child: Text('Add'),
              onPressed: () {
                if (_formKey.currentState.validate()) {  // Form is okay, add season
                  _formKey.currentState.save();
                  _show.addSeason(name: _newSeasonName);
                  EpitrackApp.saveShowsToJson();  // Saves to persistent storage
                  Navigator.pop(context); // Returns to previous screen
                } else {  // Form isn't okay
                  print('Error adding season!');  // DEBUG PRINT
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
  String _newEpisodeName;

  List<Season> _seasons = List<Season>();  // All seasons, including "no season"
  Season _selectedSeason;  // Season currently selected in the dropdown menu
  String _selectedType;  // Episode type currently selected in the dropdown menu

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
      appBar: AppBar(title: Text('Epitrack | New episode')),
      body: _buildNewEpisodeForm()
    );
  }

  Widget _buildNewEpisodeForm(){
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
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
          TextFormField(  // Episode name text box
            decoration: InputDecoration(labelText: 'Name'),
            onSaved: (String value){
              _newEpisodeName = value;
            },
          ),
          RaisedButton(  // Submit button
            child: Text('Add'),
            onPressed: (){
              if(_formKey.currentState.validate()){  // Form is okay, add episode
                _formKey.currentState.save();

                _show.addEpisode(name: _newEpisodeName, 
                                season: _selectedSeason, 
                                type: _selectedType == null ? Constants.EPISODETYPES['Episode'] : _selectedType);  // Defaults to type 'Episode'
                EpitrackApp.saveShowsToJson();  // Saves to persistent storage
                Navigator.pop(context);
              }
              else{  // Form isn't okay
                print('Error adding episode!');
              }
            },
          )
        ]
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
  void addEpisode({String name="", Season season, String type}){
    if(season == null || season.getName() == "No season"){  // No season selected, use show's base episode list
      int _nextEpisodeNumber;
      Iterable<Episode> _sameTypeEpisodes = this.episodes.where( (episode){return episode.getType() == type;} );

      if(_sameTypeEpisodes.isEmpty){
        _nextEpisodeNumber = 1;
      }
      else{
        _nextEpisodeNumber = _sameTypeEpisodes.last.getNumber() + 1;
      }

      this.episodes.add(Episode(_nextEpisodeNumber, name: name, type: type));
    }
    else{  // Calls the season's addEpisode() function
      season.addEpisode(name: name, type: type);
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
  void addEpisode({String name="", String type='E'}){
    int _nextEpisodeNumber;
    List<Episode> _sameTypeEpisodes = this.episodes.where( (episode){return episode.getType() == type;} ).toList();
    
    if(_sameTypeEpisodes.isEmpty){
      _nextEpisodeNumber = 1;
    }
    else{
      _nextEpisodeNumber = _sameTypeEpisodes.last.getNumber() + 1;
    }

    this.episodes.add(Episode(_nextEpisodeNumber, name: name, type: type));
  }

  // Prints number of season and name if it has one (e.g. S01: Season Name)
  String toString() => this.name.isEmpty ? 'S'+this.number.toString() : 'S'+this.number.toString()+': '+this.name;

  factory Season.fromJson(Map<String, dynamic> json) => _$SeasonFromJson(json);
  Map<String, dynamic> toJson() => _$SeasonToJson(this);

  /*DEBUG json
  // JSON
  Season.fromJson(Map<String, dynamic> json)
    : _number = json['number'],
      _name = json['name'],
      _episodes = json['episodes'];
  Map<String, dynamic> toJson() =>
    {
      'number': _number,
      'name': _name,
      'episodes': _episodes
    };*/

}

@JsonSerializable(explicitToJson: true)
class Episode{
  int number;
  String name;
  String type;
  bool watched;

  Episode(int number, {String name="", String type}){
    this.number = number;
    this.name = name;
    type == null ? this.type = Constants.EPISODETYPES['Episode'] : this.type = type;
    this.watched = false;
  }


  bool getWatched() => this.watched;
  void setWatched(bool newStatus) => this.watched = newStatus;

  String getType() => this.type;
  void setType(String type) => this.type = type;

  int getNumber() => this.number;
  void setNumber(int number) => this.number = number;

  String getName() => this.name;
  void setName(String name) => this.name = name;

  String toString() => this.name.isEmpty ? this.type+this.number.toString() : this.type+this.number.toString()+': '+this.name;


  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
  Map<String, dynamic> toJson() => _$EpisodeToJson(this);
  /*DEBUG json
  // JSON
  Episode.fromJson(Map<String, dynamic> json)
    : _number = json['number'],
      _name = json['name'],
      _type = json['type'],
      _watched = json['watched'];
  Map<String, dynamic> toJson() =>
    {
      'number': _number,
      'name': _name,
      'type': _type,
      'watched': _watched
    };*/
}

class Constants{
  // Episode types
  static const EPISODETYPES = {
    'Episode' : 'E',
    'Movie' : 'M',
    'Special' : 'SP',
    'OVA' : 'OVA'
  };
  
  // Colors
  static const Color mainColor = Colors.green;
  static const Color backgroundColor = Color(4291356361);  // Same as Colors.green[100]
  static const Color highlightColor = Color(4289058471);  // Same as Colors.green[200]
}