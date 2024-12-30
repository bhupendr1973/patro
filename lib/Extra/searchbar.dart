/*
 *     Copyright (C) 2024 Valeri Gokadze
 *
 *     Shrayesh-Music is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Shrayesh-Music is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Shrayesh-Music, including how to contribute,
 *     please visit: https://github.com/bhupendra/Shrayesh-Music
 */

import 'dart:io';

import 'package:shrayesh_patro/API/shrayesh_patro.dart';
import 'package:shrayesh_patro/extensions/l10n.dart';
import 'package:shrayesh_patro/main.dart';
import 'package:shrayesh_patro/services/settings_manager.dart';
import 'package:shrayesh_patro/utilities/common_variables.dart';
import 'package:shrayesh_patro/utilities/flutter_toast.dart';
import 'package:shrayesh_patro/utilities/formatter.dart';
import 'package:shrayesh_patro/widgets/no_artwork_cube.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class SearchDemo extends StatelessWidget {
  SearchDemo(
      this.song,
      this.clearPlaylist, {
        this.backgroundColor,
        this.showMusicDuration = false,
        this.onPlay,
        this.onRemove,
        super.key,
      });

  final dynamic song;
  final bool clearPlaylist;
  final Color? backgroundColor;
  final VoidCallback? onRemove;
  final VoidCallback? onPlay;
  final bool showMusicDuration;

  static const likeStatusToIconMapper = {

  };

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: commonBarPadding,
      child: GestureDetector(
        onTap: onPlay ??
                () {
              audioHandler.playSong(song);
              if (activePlaylist.isNotEmpty && clearPlaylist) {
                activePlaylist = {
                  'ytid': '',
                  'title': 'No Playlist',
                  'image': '',
                  'list': [],
                };
                activeSongId = 0;
              }
            },
        child: Card(
          elevation: 0,
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                _buildAlbumArt(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        song['title'],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 0),
                      if (song['author'] != null)
                      Text(
                        song['author'].toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,

                        ),
                      ),
                      const SizedBox(height: 0),
                      if (song['uploadDateRaw'] != null)
                      Text(
                        song['uploadDateRaw'].toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,

                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButtons(context, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    const size = 60.0;
    const radius = 12.0;

    final bool isOffline = song['isOffline'] ?? false;
    final String? artworkPath = song['artworkPath'];
    if (isOffline && artworkPath != null) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            File(artworkPath),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return CachedNetworkImage(
        key: Key(song['ytid'].toString()),
        width: size,
        height: size,
        imageUrl: song['lowResImage'].toString(),
        imageBuilder: (context, imageProvider) => SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image(
              image: imageProvider,
              centerSlice: const Rect.fromLTRB(1, 1, 1, 1),
            ),
          ),
        ),
        errorWidget: (context, url, error) => const NullArtworkWidget(
          iconSize: 30,
        ),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    final songOfflineStatus =
    ValueNotifier<bool>(isSongAlreadyOffline(song['ytid']));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!offlineMode.value)
          const Row(
          ),
        ValueListenableBuilder<bool>(
          valueListenable: songOfflineStatus,
          builder: (_, value, __) {
            return IconButton(
              color: primaryColor,
              icon: Icon(
                value ? Icons.download_done_rounded : Icons.download_rounded,
                color: value ? Theme.of(context).colorScheme.secondary : Theme.of(context).iconTheme.color,
              ),
              onPressed: () {
                if (value) {
                  removeSongFromOffline(song['ytid']);
                } else {
                  makeSongOffline(song);
                }

                songOfflineStatus.value = !songOfflineStatus.value;
              },
            );
          },
        ),

        if (showMusicDuration && song['duration'] != null)
          Text(formatDuration(song['duration'])),
      ],
    );
  }
}


void showAddToPlaylistDialog(BuildContext context, dynamic song) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        icon: const Icon(FluentIcons.text_bullet_list_add_24_filled),
        title: Text(context.l10n!.addToPlaylist),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: userCustomPlaylists.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            itemCount: userCustomPlaylists.length,
            itemBuilder: (context, index) {
              final playlist = userCustomPlaylists[index];
              return Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                elevation: 0,
                child: ListTile(
                  title: Text(playlist['title']),
                  onTap: () {
                    addSongInCustomPlaylist(playlist['title'], song);
                    showToast(context, context.l10n!.songAdded);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          )
              : Text(
            context.l10n!.noCustomPlaylists,
            textAlign: TextAlign.center,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.l10n!.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
