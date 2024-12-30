/*
 *     Copyright (C) 2024 Valeri Gokadze
 *
 *     shrayesh_patro is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     shrayesh_patro is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about shrayesh_patro, including how to contribute,
 *     please visit: https://github.com/bhupendra/shrayesh_patro
 */

import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'package:logging/logging.dart';
import '../Backup/picker.dart';
import '../Backup/seek_bar.dart';

class Mero extends StatelessWidget {
  Mero(
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
          elevation: 1.5,
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(8),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        song['artist'].toString(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
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
  Future<Map> editTags(Map song, BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final tagger = Audiotagger();

        FileImage songImage = FileImage(File(song['highResImage'].toString()));

        final titlecontroller =
        TextEditingController(text: song['title'].toString());
        final albumcontroller =
        TextEditingController(text: song['author'].toString());
        final artistcontroller =
        TextEditingController(text: song['artist'].toString());


        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: SizedBox(
            height: 200,
            width: 300,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final String filePath = await Picker.selectFile(
                        context: context,
                        // ext: ['png', 'jpg', 'jpeg'],
                        message: 'Pick Image',
                      );
                      if (filePath != '') {
                        final imagePath = filePath;
                        File(imagePath).copy(song['image'].toString());

                        songImage = FileImage(File(imagePath));

                        final Tag tag = Tag(
                          artwork: imagePath,
                        );
                        try {
                          await [
                            Permission.manageExternalStorage,
                          ].request();
                          await tagger.writeTags(
                            path: song['tracks'].toString(),
                            tag: tag,
                          );
                        } catch (e) {
                          await tagger.writeTags(
                            path: song['tracks'].toString(),
                            tag: tag,
                          );
                        }
                      }
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).width / 2,
                        width: MediaQuery.sizeOf(context).width / 2,
                        child: Image(
                          fit: BoxFit.cover,
                          image: songImage,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Text(
                        context.l10n!.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    autofocus: true,
                    controller: titlecontroller,
                    onSubmitted: (value) {},
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Text(
                        context.l10n!.artist,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    autofocus: true,
                    controller: artistcontroller,
                    onSubmitted: (value) {},
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Text(
                        context.l10n!.stats,
                        style: TextStyle(
                          fontSize: 0,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),



                ],
              ),


            ),

          ),


          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[700],
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(context.l10n!.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () async {
                Navigator.pop(context);
                song['title'] = titlecontroller.text;
                song['author'] = albumcontroller.text;
                song['artist'] = artistcontroller.text;

                final tag = Tag(
                  title: titlecontroller.text,
                  artist: artistcontroller.text,
                  album: albumcontroller.text,

                );
                try {
                  try {
                    await [
                      Permission.manageExternalStorage,
                    ].request();
                    tagger.writeTags(
                      path: song['tracks'].toString(),
                      tag: tag,
                    );
                  } catch (e) {
                    await tagger.writeTags(
                      path: song['tracks'].toString(),
                      tag: tag,
                    );
                    ShowSnackBar().showSnackBar(
                      context,
                      context.l10n!.successTagEdit,
                    );
                  }
                } catch (e) {
                  Logger.root.severe('Failed to edit tags', e);
                  ShowSnackBar().showSnackBar(
                    context,
                    '${context.l10n!.failedTagEdit}\nError: $e',
                  );
                }
              },
              child: Text(
                context.l10n!.ok,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary == Colors.white
                      ? Colors.black
                      : null,
                ),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
          ],
        );
      },
    );
    return song;
  }
  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    final songLikeStatus =
    ValueNotifier<bool>(isSongAlreadyLiked(song['ytid']));
    return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!offlineMode.value)
            Row(
              children: [
                ValueListenableBuilder<bool>(
                    valueListenable: songLikeStatus,
                    builder: (_, value, __) {
                      return PopupMenuButton(
                        icon: const Icon(
                          size: 25,
                          Icons.more_vert_rounded,

                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(15.0),
                          ),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 0,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Text(
                                  context.l10n!
                                      .edit,
                                ),
                              ],
                            ),
                          ),

                          PopupMenuItem(
                            value: 1,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_rounded,
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Text(
                                  context.l10n!
                                      .delete,
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (int? value) async {
                          if (value == 0) {
                            editTags(
                              song as Map,
                              context,
                            );
                          }
                          if (value == 1) {
                            onRemove!();
                          }
                        },
                      );
                    }
                )
              ],
            )
        ]
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