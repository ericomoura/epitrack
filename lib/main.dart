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

  //Returns a Show object with the given name
  static Show getShowByName(String name){
    return showsList.singleWhere((element){
      return element._name == name;
    });
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
            .then((_){
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
        // Adds dividers between items
        if (listIndex.isOdd) {
          return Divider();
        }

        final int showIndex = listIndex ~/ 2; // Adjusts index to take into account the dividers in the list
        
        // Only adds tiles while there are still items in the list
        if(showIndex < EpitrackApp.showsList.length){
          String showName = EpitrackApp.showsList[showIndex]._name;
          return ListTile(
            title: Text(showName),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => ShowDetailsScreen(showName)));
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
                  print("Added '$_newShow!'\n   " + _newShow.toJson().toString());  //DEBUG PRINT
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
      body: Text(_show.getName())
    );
  }

  Widget _buildSeasonsTab(){
    return Scaffold(
      body: _buildSeasonsList(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New season',
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
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
            title: Text('S' + _season.getNumber().toString() + '   ' + _season.getName())
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
        backgroundColor: Colors.green,
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
            children: _show.getEpisodes().map((episode){
              return ListTile(
                title: Text(episode.toString()),
              );
            }).toList(),
          );
          seasonsList.add(noSeasonTile);
        }
        // Episodes in each season
        for(Season season in _show.getSeasons()){
          ExpansionTile seasonTile = ExpansionTile(
            title: Text(season.toString()),
            children: season.getEpisodes().map((episode){
              return ListTile(
                title: Text('S'+season.getNumber().toString()+episode.toString())
              );
            }).toList()
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
                  print("Added season '$_newSeasonName' to '$_show'");  // DEBUG PRINT
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
          DropdownButton(
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
          DropdownButton(
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
          TextFormField(
            decoration: InputDecoration(labelText: 'Name'),
            onSaved: (String value){
              _newEpisodeName = value;
            },
          ),
          RaisedButton(
            child: Text('Add'),
            onPressed: (){
              if(_formKey.currentState.validate()){  // Form is okay, add episode
                _formKey.currentState.save();
                _show.addEpisode(name: _newEpisodeName, season: _selectedSeason, type: _selectedType);
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

class Show {
  String _name;
  List<Season> _seasons = List<Season>();
  List<Episode> _episodes = List<Episode>();  // Episodes that don't have a season (e.g. specials, OVAs, etc.)

  // Constructor
  Show(this._name);

  // Name getters/setters
  String getName() => this._name;
  void setName(String newName) => this._name = newName;

  // Returns list of episodes
  List<Episode> getEpisodes() => this._episodes;
  // Adds a new episode using the appropriate episode number
  void addEpisode({String name="", Season season, String type}){
    if(season == null || season.getName() == "No season"){  // No season selected, use show's base episode list
      int _nextEpisodeNumber;
      Iterable<Episode> _sameTypeEpisodes = this._episodes.where( (episode){return episode.getType() == type;} );

      if(_sameTypeEpisodes.isEmpty){
        _nextEpisodeNumber = 1;
      }
      else{
        _nextEpisodeNumber = _sameTypeEpisodes.last.getNumber() + 1;
      }

      this._episodes.add(Episode(_nextEpisodeNumber, name: name, type: type));
    }
    else{  // Calls the season's addEpisode() function
      season.addEpisode(name: name, type: type);
    }

    
  }

  // Returns list of seasons
  List<Season> getSeasons() => this._seasons;
  // Adds a new season using the appropriate season number
  void addSeason({String name=""}){
    int _nextSeasonNumber;
    
    if(this._seasons.isEmpty){
      _nextSeasonNumber = 1;
    }
    else{
      _nextSeasonNumber = this._seasons.last.getNumber() + 1;
    }

    this._seasons.add(Season(_nextSeasonNumber, name));
  }
  // Returns the season with the given name
  Season getSeasonByName(String name){
    return _seasons.singleWhere((element){
      return element._name == name;
    });
  }


  @override
  String toString() => this._name;

  // JSON
  Show.fromJson (Map<String, dynamic> json)
    : _name = json['name'];

  Map<String, dynamic> toJson() =>
    {
      'name': _name
    };
}

class Season{
  int _number;
  String _name;
  List<Episode> _episodes = List<Episode>();

  Season(this._number, this._name);

  int getNumber() => this._number;
  void setNumber(int number) => this._number = number;

  String getName() => this._name;
  void setName(String name) => this._name = name;

  // Returns list of episodes
  List<Episode> getEpisodes() => this._episodes;
  // Adds a new episode using the appropriate season number
  void addEpisode({String name="", String type='E'}){
    int _nextEpisodeNumber;
    List<Episode> _sameTypeEpisodes = this._episodes.where( (episode){return episode.getType() == type;} ).toList();
    
    if(_sameTypeEpisodes.isEmpty){
      _nextEpisodeNumber = 1;
    }
    else{
      _nextEpisodeNumber = _sameTypeEpisodes.last.getNumber() + 1;
    }

    this._episodes.add(Episode(_nextEpisodeNumber, name: name, type: type));
  }

  // Prints number of season and name if it has one (e.g. S01: Season Name)
  String toString() => this._name.isEmpty ? 'S'+this._number.toString() : 'S'+this._number.toString()+': '+this._name;

  // JSON
  Season.fromJson(Map<String, dynamic> json)
    : _number = json['number'],
      _name = json['name'];
  Map<String, dynamic> toJson() =>
    {
      'number': _number,
      'name': _name
    };

}

class Episode{
  int _number;
  String _name;
  String _type;

  Episode(int number, {String name="", String type}){
    this._number = number;
    this._name = name;
    type == null ? this._type = Constants.EPISODETYPES['Episode'] : this._type = type;
  }

  String getType() => this._type;
  void setType(String type) => this._type = type;

  int getNumber() => this._number;
  void setNumber(int number) => this._number = number;

  String getName() => this._name;
  void setName(String name) => this._name = name;

  String toString() => this._name.isEmpty ? this._type+this._number.toString() : this._type+this._number.toString()+': '+this._name;

  // JSON
  Episode.fromJson(Map<String, dynamic> json)
    : _number = json['number'],
      _name = json['name'];
  Map<String, dynamic> toJson() =>
    {
      'number': _number,
      'name': _name
    };
}

class Constants{
  static const EPISODETYPES = {
    'Episode' : 'E',
    'Movie' : 'M',
    'Special' : 'SP',
    'OVA' : 'OVA'
  };
}