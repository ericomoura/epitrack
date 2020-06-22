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
      home: LoadingScreen(),
    );
  }

}

class LoadingScreen extends StatefulWidget{
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}
class _LoadingScreenState extends State<LoadingScreen>{
  @override
  Widget build(BuildContext context){
    return FutureBuilder<bool>(  // FutureBuilder waits for the shows to be loaded from the JSON file
      future: Utils.loadShowsFromJson(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot){
        // Switches to ShowsScreen as soon as possible
        Future.delayed(Duration.zero, () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context)=>ShowsScreen()));
        });
        
        // Temporary screen until it switches to ShowsScreen
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${Constants.appbarPrefix}Loading...',
              style: TextStyle(fontSize: Constants.appbarFontSize)
            )
          ),
          drawer: Utils.buildEpitrackDrawer(context),
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
    );
  }

}

class ShowsScreen extends StatefulWidget{
  @override
  _ShowsScreenState createState() => _ShowsScreenState();
}
class _ShowsScreenState extends State<ShowsScreen>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${Constants.appbarPrefix}Shows', 
          style: TextStyle(fontSize: Constants.appbarFontSize)
        )
      ),
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

  Widget _buildShowsList() {
    return ListView.builder(
      itemCount: 2 * EpitrackApp.showsList.length,  // Accounts for dividers in the list
      itemBuilder: (BuildContext context, int listIndex) {
        // Adds dividers between items
        if (listIndex.isOdd) {
          return Divider();
        }

        final int showIndex = listIndex ~/ 2; // Adjusts index to take into account the dividers in the list
        
        Show currentShow = EpitrackApp.showsList[showIndex];
        return ListTile(
          title: Text(currentShow.getName()),
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => ShowDetailsScreen(currentShow)))
            .then((_){
              setState((){
                // Updates list
              });
            });
          }
        );
      }
    );
  }

}

class NewShowScreen extends StatefulWidget{
  @override
  _NewShowScreenState createState() => _NewShowScreenState();
}
class _NewShowScreenState extends State<NewShowScreen>{
  final _formKey = GlobalKey<FormState>();
  String _newShowName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${Constants.appbarPrefix}New show',
          style: TextStyle(fontSize: Constants.appbarFontSize)
        )
      ),
      body: _buildNewShowForm()
    );
  }

  Widget _buildNewShowForm(){
    return Form(
      key: this._formKey,
      child: Column(
        children: <Widget>[
          Row( children:[
            Text('Name: '),
            Container(width: 300, child: TextFormField(
              validator: Validators.showNameValidator,
              onSaved: (String value) {
                this._newShowName = value;
              },
            )),
          ]),
          RaisedButton(
            color: Constants.highlightColor,
            child: Text('Add show'),
            onPressed: () {
              if (_formKey.currentState.validate()) {  //Form is okay, add show
                _formKey.currentState.save();

                EpitrackApp.showsList.add(Show(this._newShowName));
                Utils.saveShowsToJson();
                Navigator.pop(context);
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
  final Show _show;

  ShowDetailsScreen(this._show);

  @override
  _ShowDetailsScreenState createState() => _ShowDetailsScreenState(this._show);
}
class _ShowDetailsScreenState extends State<ShowDetailsScreen>{
  final Show _show;

  _ShowDetailsScreenState(this._show);

  @override
  Widget build(BuildContext context){
    return DefaultTabController(
      length: 3,
      child: Scaffold( 
        appBar: AppBar(
          title: Text(
            '${Constants.appbarPrefix}${this._show.getName()}',
            style: TextStyle(fontSize: Constants.appbarFontSize)
          ),
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
          Text('Name: ${this._show.getName()}'),
          Text('Number of seasons: ${this._show.getNumberOfSeasons()}'),
          Text('Number of episodes: ${this._show.getNumberOfEpisodes()}'),
          RaisedButton(
            color: Constants.highlightColor,
            child: Text('Remove show'),
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
      itemCount: 2 * this._show.getSeasons().length,  // Accounts for dividers in the list
      itemBuilder: (BuildContext context, int listIndex){
        // Adds dividers between items
        if(listIndex.isOdd){
          return Divider();
        }

        final int seasonIndex = listIndex ~/ 2; // Adjusts index to take into account the dividers in the list
        Season season = _show.getSeasons()[seasonIndex];

        return ListTile(
          title: Text('$season'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SeasonDetailsScreen(season)))
            .then((_){
              setState((){
                // Update list
              });
            });
          }
        );

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
                title: Text('$episode'),
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EpisodeDetailsScreen(episode)))
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
        for(Season season in this._show.getSeasons()){
          ExpansionTile seasonTile = ExpansionTile(
            title: Text('$season'),
            backgroundColor: Constants.highlightColor,
            children: season.getEpisodes().map((episode){
              return ListTile(
                title: Text('$episode'),
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EpisodeDetailsScreen(episode)))
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
        
        if(tileIndex < seasonsList.length){  // Only adds items while there are seasons to add
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
      appBar: AppBar(
        title: Text(
          '${Constants.appbarPrefix}Editing $this._show',
          style: TextStyle(fontSize: Constants.appbarFontSize)
        )
      ),
      body: _buildEditShowForm()
    );
  }

  Widget _buildEditShowForm(){
    return Form(
      key: this._formKey,
      child: Column(
        children: <Widget>[
          Row(children:[
            Text('Name: '),
            Container(width: 300, child: TextFormField(
              initialValue: this._showName,
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
              if (this._formKey.currentState.validate()) {  //Form is okay, add show
                this._formKey.currentState.save();

                this._show.setName(this._showName);

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

  NewSeasonScreen(this._show);

  @override
  _NewSeasonScreenState createState() => _NewSeasonScreenState(this._show);
}
class _NewSeasonScreenState extends State<NewSeasonScreen> {
  final Show _show;
  final _formKey = GlobalKey<FormState>();
  String _newSeasonName = '';

  _NewSeasonScreenState(this._show);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Epitrack | New season',
          style: TextStyle(fontSize: Constants.appbarFontSize)
        )
      ),
      body: _buildNewSeasonForm()
    );
  }

  Widget _buildNewSeasonForm(){
    return Form(
      key: this._formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(labelText: 'Name'),
            onSaved: (String value) {
              this._newSeasonName = value;
            },
          ),
          RaisedButton(
            color: Constants.highlightColor,
            child: Text('Add season'),
            onPressed: () {
              if (this._formKey.currentState.validate()) {  // Form is okay, add season
                this._formKey.currentState.save();
                
                this._show.addSeason(name: this._newSeasonName);

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

  SeasonDetailsScreen(this._season);

  @override
  _SeasonDetailsScreenState createState() => _SeasonDetailsScreenState(this._season);
}
class _SeasonDetailsScreenState extends State<SeasonDetailsScreen>{
  final Season _season;

  _SeasonDetailsScreenState(this._season);

  @override
  Widget build(BuildContext context){
    print(_season.getParentShow());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${Constants.appbarPrefix}S${this._season.getNumber()} of ${this._season.getParentShow()}', 
          style: TextStyle(fontSize: Constants.appbarFontSize)
        )
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Edit season',
        child: Icon(Icons.edit),
        backgroundColor: Constants.mainColor,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => EditSeasonScreen(this._season)))
            .then((_){
              setState((){
                //Updates details
              });
            });
        },
      ),
      body: Column(
        children: [
          Text('Season name: ${this._season.getName()}'),
          Text('Season number: ${this._season.getNumber()}'),
          Text('Number of episodes: ${this._season.getNumberOfEpisodes()}'),
          RaisedButton(
            color: Constants.highlightColor,
            child: Text('Remove season'),
            onPressed: (){
              this._season.getParentShow().getSeasons().remove(_season);
              Utils.fixListNumbers(this._season.getParentShow().getSeasons());

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

  EditSeasonScreen(this._season);

  @override
  _EditSeasonScreenState createState() => _EditSeasonScreenState(this._season);
}
class _EditSeasonScreenState extends State<EditSeasonScreen>{
  final Season _season;

  final _formKey = GlobalKey<FormState>();
  String _seasonName;

  _EditSeasonScreenState(this._season){
    this._seasonName = this._season.getName();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${Constants.appbarPrefix}Editing S${this._season.getNumber()} of ${this._season.getParentShow()}',
          style: TextStyle(fontSize: Constants.appbarFontSize)
        )
      ),
      body: _buildEditSeasonForm()
    );
  }

  Widget _buildEditSeasonForm(){
    return Form(
      key: this._formKey,
      child: Column(
        children: <Widget>[
          Row(children:[
            Text('Name: '),
            Container(width: 300, child: TextFormField(
              initialValue: this._season.getName(),
              onSaved: (String value) {
                this._seasonName = value;
              },
            ))
          ]),
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

  NewEpisodeScreen(this._show);

  @override
  _NewEpisodeScreenState createState() => _NewEpisodeScreenState(this._show);
}
class _NewEpisodeScreenState extends State<NewEpisodeScreen>{
  final Show _show;
  final _formKey = GlobalKey<FormState>();

  List<Season> _seasons = List<Season>();  // All seasons, including "no season"
  String _newEpisodeName;
  int _newEpisodeDuration;
  Season _selectedSeason;  // Season currently selected in the dropdown menu
  String _selectedType;  // Episode type currently selected in the dropdown menu
  DateAndTime _selectedDateAndTime = DateAndTime();  //Date and time currently selected

  _NewEpisodeScreenState(this._show){
    // Builds list of seasons
    this._seasons.add(Season(0, "No season", this._show));
    for (Season season in _show.getSeasons()){
      this._seasons.add(season);
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${Constants.appbarPrefix}New episode',
          style: TextStyle(fontSize: Constants.appbarFontSize)
        )
      ),
      body: _buildNewEpisodeForm()
    );
  }

  Widget _buildNewEpisodeForm(){
    return Form(
      key: this._formKey,
      child: SingleChildScrollView(child: Column(
        children: <Widget>[
          Row(children: [  // Episode name
            Text('Name: '),
            Container(width: 300, child: TextFormField(  // Episode name text box
              decoration: InputDecoration(labelText: 'Name'),   
              onSaved: (String value){
                this._newEpisodeName = value;
              },
            ))
          ]), 
          Row(children: [  // Season
            Text('Season: '),
            DropdownButton(  // Season dropdown
              hint: Text('Select a season'),
              value: this._selectedSeason,
              onChanged: (newValue){
                setState((){
                  this._selectedSeason = newValue;
                });
              },
              items: this._seasons.map((season){
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
              value: this._selectedType,
              onChanged: (newValue){
                setState((){
                  this._selectedType = newValue;
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
            Text(this._selectedDateAndTime.hasDate() == false ? 'Airing date: - ' : 'Airing date: ${this._selectedDateAndTime.getDateString()}'),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Select date'),
              onPressed: () async{
                DateTime date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(Constants.minYear),
                  lastDate: DateTime(Constants.maxYear)
                );
                setState((){
                  if(date != null){  // If a date was selected
                    this._selectedDateAndTime.setYear(date.year);
                    this._selectedDateAndTime.setMonth(date.month);
                    this._selectedDateAndTime.setDay(date.day);
                  }
                });
              },
            )
          ],),
          Row(children: [  // Airing time
            Text(this._selectedDateAndTime.hasTime() == false ? 'Airing time: - ' : 'Airing time: ${this._selectedDateAndTime.getTimeString()}'),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Select time'),
              onPressed: () async{
                TimeOfDay time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: 0, minute: 0)
                );
                setState((){
                  if(time != null){  // If a time was selected
                    this._selectedDateAndTime.setHour(time.hour);
                    this._selectedDateAndTime.setMinute(time.minute);
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
                  this._newEpisodeDuration = int.parse(value);
                }
              }
            )),
            Text('seconds')
          ]),
          RaisedButton(  // Submit button
            color: Constants.highlightColor,
            child: Text('Add episode'),
            onPressed: (){
              if(this._formKey.currentState.validate()){  // Form is okay, add episode
                this._formKey.currentState.save();

                this._show.addEpisode(
                  name: this._newEpisodeName, 
                  season: this._selectedSeason, 
                  type: this._selectedType == null ? Constants.EPISODETYPES['Episode'] : this._selectedType,  // Defaults to type 'Episode'
                  airingDateAndTime: this._selectedDateAndTime,
                  durationMinutes: this._newEpisodeDuration
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

  EpisodeDetailsScreen(this._episode);

  @override
  _EpisodeDetailsScreenState createState() => _EpisodeDetailsScreenState(this._episode);
}
class _EpisodeDetailsScreenState extends State<EpisodeDetailsScreen>{
  final Episode _episode;

  _EpisodeDetailsScreenState(this._episode);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: this._episode.getParentSeason() == null ?   // Remove season number from appbar if there is no season
          Text('${Constants.appbarPrefix}E${this._episode.getNumber()} ${this._episode.getParentShow()}',
            style: TextStyle(fontSize: Constants.appbarFontSize)
          )
          : 
          Text('${Constants.appbarPrefix}S${this._episode.getParentSeason().getNumber()}E${this._episode.getNumber()} ${this._episode.getParentShow()}',
            style: TextStyle(fontSize: Constants.appbarFontSize)
          )
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Edit episode',
        child: Icon(Icons.edit),
        backgroundColor: Constants.mainColor,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => EditEpisodeScreen(this._episode)))
            .then((_){
              setState((){
                //Updates details
              });
            });
        },
      ),
      body: Column(
        children: [
          Text('Name: ${this._episode.getName()}'),
          Text('Number: ${this._episode.getNumber()}'),
          Text('Type: ' + Constants.EPISODETYPES.keys.singleWhere((key) => Constants.EPISODETYPES[key] == this._episode.getType()) ),
          Text('Watched: ${this._episode.watched}'),
          Text('Aired on: ${this._episode.getAiringDateAndTime().getDateAndTimeString()}'),
          Text('Duration: ' + (this._episode.getDuration() == null ? '-' : '${this._episode.getDuration()} minutes')),
          RaisedButton(
            color: Constants.highlightColor,
            child: Text('Remove episode'),
            onPressed: (){
              if(this._episode.getParentSeason() == null){  // Episode has no season, remove from show's list
                this._episode.getParentShow().getEpisodes().remove(_episode);
                Utils.fixListNumbers(this._episode.getParentShow().getEpisodes());
              }
              else{  // Episode has a season, remove from season's list
                this._episode.getParentSeason().getEpisodes().remove(_episode);
                Utils.fixListNumbers(this._episode.getParentSeason().getEpisodes());
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

  EditEpisodeScreen(this._episode);

  @override
  _EditEpisodeScreenState createState() => _EditEpisodeScreenState(this._episode);
}
class _EditEpisodeScreenState extends State<EditEpisodeScreen>{
  final Episode _episode;
  final _formKey = GlobalKey<FormState>();

  List<Season> _seasons = List<Season>();  // All seasons, including "no season"
  String _episodeName;
  int _episodeDuration;
  Season _selectedSeason;  // Season currently selected in the dropdown menu
  String _selectedType;  // Episode type currently selected in the dropdown menu
  DateAndTime _selectedDateAndTime = DateAndTime();  //Date and time currently selected

  _EditEpisodeScreenState(this._episode){
    // Builds list of all seasons
    this._seasons.add(Season(0, "No season", this._episode.getParentShow()));
    for (Season season in this._episode.getParentShow().getSeasons()){
      this._seasons.add(season);
    }

    // Initializes form values
    this._episodeName = this._episode.getName();
    this._episodeDuration = this._episode.getDuration();
    this._selectedSeason = this._episode.getParentSeason() == null ? this._seasons[0] : this._episode.getParentSeason();
    this._selectedType = this._episode.getType();
    this._selectedDateAndTime = this._episode.getAiringDateAndTime();

  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: this._episode.getParentSeason() == null ?   // Remove season number from appbar if there is no season
          Text(
            '${Constants.appbarPrefix}Editing E${this._episode.getNumber()} of ${_episode.getParentShow()}',
            style: TextStyle(fontSize: Constants.appbarFontSize)
          )
          :
          Text(
            '${Constants.appbarPrefix}Editing S${this._episode.getParentSeason().getNumber()}E${this._episode.getNumber()} of ${this._episode.getParentShow()}',
            style: TextStyle(fontSize: Constants.appbarFontSize)
          )
      ),
      body: _buildEditEpisodeForm()
    );
  }

  Widget _buildEditEpisodeForm(){
    return Form(
      key: this._formKey,
      child: SingleChildScrollView(child: Column(
        children: <Widget>[
          Row(children: [  // Episode name
            Text('Name: '),
            Container(width: 300, child: TextFormField(  // Episode name text box
              initialValue: this._episodeName,  
              onSaved: (String value){
                this._episodeName = value;
              },
            ))
          ]), 
          Row(children: [  // Season
            Text('Season: '),
            DropdownButton(  // Season dropdown
              hint: Text('Select a season'),
              value: this._selectedSeason,
              onChanged: (newValue){
                setState((){
                  this._selectedSeason = newValue;
                });
              },
              items: this._seasons.map((season){
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
              value: this._selectedType,
              onChanged: (newValue){
                setState((){
                  this._selectedType = newValue;
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
            Text(this._selectedDateAndTime.hasDate() == false ? 'Airing date: - ' : 'Airing date: ${_selectedDateAndTime.getDateString()}'),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Select date'),
              onPressed: () async{
                DateTime date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(Constants.minYear),
                  lastDate: DateTime(Constants.maxYear)
                );
                setState((){
                  if(date != null){  // If a date was selected
                    this._selectedDateAndTime.setYear(date.year);
                    this._selectedDateAndTime.setMonth(date.month);
                    this._selectedDateAndTime.setDay(date.day);
                  }
                });
              },
            )
          ],),
          Row(children: [  // Airing time
            Text(_selectedDateAndTime.hasTime() == false ? 'Airing time: - ' : 'Airing time: ${_selectedDateAndTime.getTimeString()}'),
            RaisedButton(
              color: Constants.highlightColor,
              child: Text('Select time'),
              onPressed: () async{
                TimeOfDay time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: 0, minute: 0)
                );
                setState((){
                  if(time != null){  // If a time was selected
                    this._selectedDateAndTime.setHour(time.hour);
                    this._selectedDateAndTime.setMinute(time.minute);
                  }
                });
              },
            )
          ],),
          Row(children: [  // Duration
            Text('Duration: '),
            Container(width: 100, child: TextFormField(
              initialValue: this._episodeDuration == null ? '' : this._episodeDuration.toString(),
              keyboardType: TextInputType.number,
              inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
              onSaved: (String value){
                if(value != ''){
                  this._episodeDuration = int.parse(value);
                }
              }
            )),
            Text('seconds')
          ]),
          RaisedButton(  // Submit button
            color: Constants.highlightColor,
            child: Text('Save changes'),
            onPressed: (){
              if(this._formKey.currentState.validate()){  // Form is okay, add episode
                this._formKey.currentState.save();

                if(this._selectedSeason == this._episode.getParentSeason()    // Same season, just update values
                    || (this._selectedSeason.getName() == 'No season' && this._episode.getParentSeason() == null)){
                  this._episode.setName(this._episodeName);
                  this._episode.setType(this._selectedType);
                  this._episode.setAiringDateAndTime(this._selectedDateAndTime);
                  this._episode.setDuration(this._episodeDuration);

                  Utils.saveShowsToJson();
                  Navigator.pop(context);
                }
                else{   // Different season, remove from the current one and readd to the new one
                  
                  // Removes the episode from the appropriate list
                  if(this._episode.getParentSeason() == null){
                    this._episode.getParentShow().getEpisodes().remove(this._episode);
                  }
                  else{
                    this._episode.getParentSeason().getEpisodes().remove(this._episode);
                  }

                  // Readds the episode with the new changes
                  this._episode.getParentShow().addEpisode(
                    name: this._episodeName, 
                    season: this._selectedSeason, 
                    type: this._selectedType == null ? Constants.EPISODETYPES['Episode'] : this._selectedType,  // Defaults to type 'Episode'
                    watched: this._episode.getWatched(),
                    airingDateAndTime: this._selectedDateAndTime,
                    durationMinutes: this._episodeDuration
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
  final List<Episode> _allEpisodes = List<Episode>();

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
    _allEpisodes.sort(Comparators.compareEpisodesAiringDateAndTime);  // Sorts by airing date
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${Constants.appbarPrefix}Upcoming episodes',
          style: TextStyle(fontSize: Constants.appbarFontSize)
        )
      ),
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

          return ListTile(
            title: Text(currentEpisode.toString()),
            subtitle: Text(currentEpisode.getAiringDateAndTime().getDateAndTimeString(), textAlign: TextAlign.right),
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

  Show(this.name);

  String getName() => this.name;
  void setName(String newName) => this.name = newName;

  List<Episode> getEpisodes() => this.episodes;
  // Adds a new episode using the appropriate episode number
  void addEpisode({String name, Season season, String type, bool watched, DateAndTime airingDateAndTime, int durationMinutes}){
    if(season == null || season.getName() == "No season"){  // No season selected, use show's base episode list
      int nextEpisodeNumber;
      Iterable<Episode> sameTypeEpisodes = this.episodes.where( (episode){return episode.getType() == type;} );

      if(sameTypeEpisodes.isEmpty){
        nextEpisodeNumber = 1;
      }
      else{
        nextEpisodeNumber = sameTypeEpisodes.last.getNumber() + 1;
      }

      this.episodes.add(Episode(nextEpisodeNumber, this, null,
        name: name, 
        type: type, 
        watched: watched, 
        airingDateAndTime: airingDateAndTime, 
        durationMinutes: durationMinutes,
      ));
    }
    else{  // Calls the season's addEpisode() function
      season.addEpisode(
        name: name,
        type: type,
        watched: watched,
        airingDateAndTime: airingDateAndTime,
        durationMinutes: durationMinutes
      );
    }
  }

  List<Season> getSeasons() => this.seasons;
  // Adds a new season using the appropriate season number
  void addSeason({String name=""}){
    int nextSeasonNumber;
    
    if(this.seasons.isEmpty){
      nextSeasonNumber = 1;
    }
    else{
      nextSeasonNumber = this.seasons.last.getNumber() + 1;
    }

    this.seasons.add(Season(nextSeasonNumber, name, this));
  }
  // Returns the season with the given name
  Season getSeasonByName(String name){
    return seasons.singleWhere((element){
      return element.name == name;
    });
  }

  int getNumberOfSeasons() => this.seasons.length;
  // Returns the total number of episodes (show itself and each season)
  int getNumberOfEpisodes(){
    int totalNumber = this.episodes.length;
    for(Season season in this.seasons){
      totalNumber += season.getNumberOfEpisodes();
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
  @JsonKey(toJson: Utils.parentShowToJson)
  Show parentShow;  // Reference to the show which contains this season

  Season(this.number, this.name, this.parentShow);

  int getNumber() => this.number;
  void setNumber(int number) => this.number = number;

  String getName() => this.name;
  void setName(String name) => this.name = name;

  Show getParentShow() => this.parentShow;
  void setParentShow(Show show) => this.parentShow = show;

  List<Episode> getEpisodes() => this.episodes;
  // Adds a new episode using the appropriate season number
  void addEpisode({String name, String type='E', bool watched, DateAndTime airingDateAndTime, int durationMinutes}){
    int nextEpisodeNumber;
    List<Episode> sameTypeEpisodes = this.episodes.where( (episode){return episode.getType() == type;} ).toList();
    
    if(sameTypeEpisodes.isEmpty){
      nextEpisodeNumber = 1;
    }
    else{
      nextEpisodeNumber = sameTypeEpisodes.last.getNumber() + 1;
    }

    this.episodes.add(Episode(nextEpisodeNumber, this.getParentShow(), this,
      name: name, 
      type: type, 
      watched: watched, 
      airingDateAndTime: airingDateAndTime, 
      durationMinutes: durationMinutes
    ));
  }

  // Returns the total number of episodes in the season
  int getNumberOfEpisodes() => this.episodes.length;

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
  @JsonKey(toJson: Utils.parentShowToJson)
  Show parentShow;  // Reference to the show which contains this episode
  @JsonKey(toJson: Utils.parentSeasonToJson)
  Season parentSeason;  // Reference to the season which contains this episode. If null, episode has no season.


  Episode(this.number, Show parentShow, Season parentSeason, {this.name="", this.type, this.watched=false, this.airingDateAndTime, this.durationMinutes}){
    this.setParentShow(parentShow);
    this.setParentSeason(parentSeason);
    this.type = this.type == null ? Constants.EPISODETYPES['Episode'] : this.type;
    this.watched = this.watched == null ? false : this.watched;
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

  Show getParentShow() => this.parentShow;
  void setParentShow(Show show) => this.parentShow = show;

  Season getParentSeason() => this.parentSeason;
  void setParentSeason(Season season) => this.parentSeason = season;

  String toString() => (this.getParentSeason() == null ? '': 'S${this.getParentSeason().getNumber()}') 
    + 'E${this.getNumber()}' 
    + (this.getName().isEmpty ? '' : ': ${this.getName()}');


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
  String getDateAndTimeString({bool allowJustTime=false}){  // Won't return time without a date unless 'allowJustTime' is true
    if(this.hasDate()){
      if(this.hasTime()){
        return '${this.getDateString()} @ ${this.getTimeString()}';  // Date and time
      }
      else{
        return '${this.getDateString()}';  // Just date
      }
    }
    else{
      if(this.hasTime() && allowJustTime){  // Just time
        return '@ ${this.getTimeString()}';
      }
      else{  // No date and no time
        return '-';
      }
    }
  }

  DateTime getDateTimeObject(){
    if(this.hasDate()){  // Has a date
      if(this.hasTime()){  // Has a date and a time
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
    if(this.hasTime()){  // Has a time
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

  static int minYear = -5000;
  static int maxYear = -5000;

  static String appbarPrefix = 'Epitrack | ';
  
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

  // Functions used to save Season and Episode to JSON. Parents can't be ignored so are set to null to avoid infinite loops in the JSON.
  static String parentShowToJson(Show parentShow){
    return null;
  }
  static String parentSeasonToJson(Season parentSeason){
    return null;
  }


  // Goes through all episodes, seasons (and their own episodes) and updates all 'parentShow' and 'parentSeason' attributes.
  static void updateParents(Show parentShow){
    for(Episode episode in parentShow.getEpisodes()){
      episode.setParentShow(parentShow);
      episode.setParentSeason(null);
    }
    for(Season season in parentShow.getSeasons()){
      season.setParentShow(parentShow);
      for(Episode episode in season.getEpisodes()){
        episode.setParentShow(parentShow);
        episode.setParentSeason(season);
      }
    }
  }

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

              Navigator.pop(context);  // Closes previous screen to avoid keeping outdade states
              Navigator.push(context, MaterialPageRoute(builder: (context) => ShowsScreen()));
            },
          ),
          Divider(),
          ListTile(  // Upcoming episodes
            title: Text('Upcoming episodes'),
            onTap: (){
              Navigator.pop(context);  // Closes drawer

              Navigator.pop(context);  // Closes previous screen to avoid keeping outdade states
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

    print(jsonOutput);
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

    // Updates parent shows and seasons
    for(Show show in shows){
      Utils.updateParents(show);
    }

    EpitrackApp.showsList = shows;
    print('JSON loaded!');
    return true;  // Set the future data to true to signal loading complete
  }
  
  // Returns a Show object with the given name
  static Show getShowByName(String name){
    return EpitrackApp.showsList.singleWhere((element) => element.getName() == name);
  }

  static Season getSeasonByNumber(Show show, int number){
    return show.getSeasons().singleWhere((element) => element.getNumber() == number);
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