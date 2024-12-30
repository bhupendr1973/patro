/*
 *  This file is part of Shrayesh-Music (https://bhupendra12345678.github.io/mymusic/).
 *
 * Shrayesh-Music is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Shrayesh_music is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Shrayesh_music.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright (c) 2023-2024, Bhupendra Dahal
 */


import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shrayesh_patro/Download_Music/player_service.dart';

class PlaylistHead extends StatelessWidget {
  final List songsList;
  final bool offline;
  final bool fromDownloads;
  const PlaylistHead({
    super.key,
    required this.songsList,
    required this.fromDownloads,
    required this.offline,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 20.0, right: 10.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${songsList.length} ${AppLocalizations.of(
              context,
            )!.songs}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .colorScheme
                  .secondary,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              PlayerInvoke.init(
                songsList: songsList,
                index: 0,
                isOffline: offline,
                fromDownloads: fromDownloads,
                recommend: false,
                shuffle: true,
              );
            },
            icon: const Icon(Icons.shuffle_rounded,),
            label: Text(
              AppLocalizations.of(context)!.shuffle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .secondary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              PlayerInvoke.init(
                songsList: songsList,
                index: 0,
                isOffline: offline,
                fromDownloads: fromDownloads,
                recommend: false,
              );
            },
            tooltip: AppLocalizations.of(context)!.shuffle,
            icon: const Icon(Icons.play_arrow_rounded),
            iconSize: 30.0,
          ),
        ],
      ),
    );
  }
}
