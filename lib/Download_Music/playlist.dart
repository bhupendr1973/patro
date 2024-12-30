/*
 *  This file is part of Shrayesh-Music (https://bhupendra12345678.github.io/mymusic/).
 *
 * Shrayesh-Music is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Shrayesh-Music is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Shrayesh_music.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright (c) 2023-2024, Bhupendra Dahal
 */

import 'package:audio_service/audio_service.dart';
import 'package:shrayesh_patro/Download_Music/songs_count.dart' as songs_count;
import 'package:hive/hive.dart';

import '../utilities/mediaitem.dart';

bool checkPlaylist(String name, String key) {
  if (name != 'Favorite Songs') {
    Hive.openBox(name).then((value) {
      return Hive.box(name).containsKey(key);
    });
  }
  return Hive.box(name).containsKey(key);
}

Future<void> removeLiked(String key) async {
  final Box likedBox = Hive.box('Favorite Songs');
  likedBox.delete(key);
  // setState(() {});
}

Future<void> addMapToPlaylist(String name, Map info) async {
  if (name != 'Favorite Songs') await Hive.openBox(name);
  final Box playlistBox = Hive.box(name);
  final List songs = playlistBox.values.toList();
  info.addEntries([MapEntry('dateAdded', DateTime.now().toString())]);
  songs_count.addSongsCount(
    name,
    playlistBox.values.length + 1,
    songs.length >= 4 ? songs.sublist(0, 4) : songs.sublist(0, songs.length),
  );
  playlistBox.put(info['id'].toString(), info);
}

Future<void> addItemToPlaylist(String name, MediaItem mediaItem) async {
  if (name != 'Favorite Songs') await Hive.openBox(name);
  final Box playlistBox = Hive.box(name);
  final Map info = mediaItemToMap(mediaItem);
  info.addEntries([MapEntry('dateAdded', DateTime.now().toString())]);
  final List songs = playlistBox.values.toList();
  songs_count.addSongsCount(
    name,
    playlistBox.values.length + 1,
    songs.length >= 4 ? songs.sublist(0, 4) : songs.sublist(0, songs.length),
  );
  playlistBox.put(mediaItem.id, info);
}

Future<void> addPlaylist(String inputName, List data) async {
  final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
  String name = inputName.replaceAll(avoid, '').replaceAll('  ', ' ');

  final List playlistNames =
  Hive.box('settings').get('playlistNames', defaultValue: []) as List;

  if (name.trim() == '') {
    name = 'Playlist ${playlistNames.length}';
  }
  while (playlistNames.contains(name)) {
    // ignore: use_string_buffers
    name += ' (1)';
  }

  await Hive.openBox(name);
  final Box playlistBox = Hive.box(name);

  songs_count.addSongsCount(
    name,
    data.length,
    data.length >= 4 ? data.sublist(0, 4) : data.sublist(0, data.length),
  );
  final Map result = {for (final v in data) v['id'].toString(): v};
  playlistBox.putAll(result);

  playlistNames.add(name);
  Hive.box('settings').put('playlistNames', playlistNames);
}