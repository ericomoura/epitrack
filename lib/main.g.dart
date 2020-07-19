// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Show _$ShowFromJson(Map<String, dynamic> json) {
  return Show(
    json['name'] as String,
    nickname: json['nickname'] as String,
    notes: json['notes'] as String,
    rating: (json['rating'] as num)?.toDouble(),
    author: json['author'] as String,
    source: json['source'] as String,
  )
    ..seasons = (json['seasons'] as List)
        ?.map((e) =>
            e == null ? null : Season.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..episodes = (json['episodes'] as List)
        ?.map((e) =>
            e == null ? null : Episode.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..genres = (json['genres'] as List)?.map((e) => e as String)?.toList();
}

Map<String, dynamic> _$ShowToJson(Show instance) => <String, dynamic>{
      'name': instance.name,
      'nickname': instance.nickname,
      'seasons': instance.seasons?.map((e) => e?.toJson())?.toList(),
      'episodes': instance.episodes?.map((e) => e?.toJson())?.toList(),
      'notes': instance.notes,
      'rating': instance.rating,
      'author': instance.author,
      'source': instance.source,
      'genres': instance.genres,
    };

Season _$SeasonFromJson(Map<String, dynamic> json) {
  return Season(
    json['number'] as int,
    json['name'] as String,
    json['parentShow'] == null
        ? null
        : Show.fromJson(json['parentShow'] as Map<String, dynamic>),
    notes: json['notes'] as String,
    rating: (json['rating'] as num)?.toDouble(),
    production: json['production'] as String,
  )..episodes = (json['episodes'] as List)
      ?.map(
          (e) => e == null ? null : Episode.fromJson(e as Map<String, dynamic>))
      ?.toList();
}

Map<String, dynamic> _$SeasonToJson(Season instance) => <String, dynamic>{
      'number': instance.number,
      'name': instance.name,
      'episodes': instance.episodes?.map((e) => e?.toJson())?.toList(),
      'parentShow': Utils.parentShowToJson(instance.parentShow),
      'notes': instance.notes,
      'rating': instance.rating,
      'production': instance.production,
    };

Episode _$EpisodeFromJson(Map<String, dynamic> json) {
  return Episode(
    json['number'] as int,
    json['parentShow'] == null
        ? null
        : Show.fromJson(json['parentShow'] as Map<String, dynamic>),
    json['parentSeason'] == null
        ? null
        : Season.fromJson(json['parentSeason'] as Map<String, dynamic>),
    name: json['name'] as String,
    type: json['type'] as String,
    watched: json['watched'] as bool,
    airingDateAndTime: json['airingDateAndTime'] == null
        ? null
        : DateAndTime.fromJson(
            json['airingDateAndTime'] as Map<String, dynamic>),
    durationMinutes: json['durationMinutes'] as int,
    notes: json['notes'] as String,
    rating: (json['rating'] as num)?.toDouble(),
    production: json['production'] as String,
  );
}

Map<String, dynamic> _$EpisodeToJson(Episode instance) => <String, dynamic>{
      'number': instance.number,
      'name': instance.name,
      'type': instance.type,
      'watched': instance.watched,
      'airingDateAndTime': instance.airingDateAndTime?.toJson(),
      'durationMinutes': instance.durationMinutes,
      'parentShow': Utils.parentShowToJson(instance.parentShow),
      'parentSeason': Utils.parentSeasonToJson(instance.parentSeason),
      'notes': instance.notes,
      'rating': instance.rating,
      'production': instance.production,
    };

DateAndTime _$DateAndTimeFromJson(Map<String, dynamic> json) {
  return DateAndTime(
    year: json['year'] as int,
    month: json['month'] as int,
    day: json['day'] as int,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
  );
}

Map<String, dynamic> _$DateAndTimeToJson(DateAndTime instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'day': instance.day,
      'hour': instance.hour,
      'minute': instance.minute,
    };
