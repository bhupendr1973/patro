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

import 'package:shrayesh_patro/extensions/l10n.dart';
import 'package:shrayesh_patro/main.dart';
import 'package:shrayesh_patro/services/settings_manager.dart';
import 'package:shrayesh_patro/widgets/mini_player.dart';
import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../API/languagecodes.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({
    super.key,
    required this.child,
  });

  final StatefulNavigationShell child;

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  final _selectedIndex = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    // can be wrapped in the SafeArea:
    // body: SafeArea(
    //   child: widget.child,
    // ),

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StreamBuilder<MediaItem?>(
            stream: audioHandler.mediaItem,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                logger.log(
                  'Error in mini player bar',
                  snapshot.error,
                  snapshot.stackTrace,
                );
              }
              final metadata = snapshot.data;
              if (metadata == null) {
                return const SizedBox.shrink();
              } else {
                return MiniPlayer(metadata: metadata);
              }
            },
          ),
          NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: _selectedIndex.value,
            labelBehavior: LanguageCodes == const Locale('en', '')
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysHide,
            onDestinationSelected: (index) {
              widget.child.goBranch(
                index,
                initialLocation: index == widget.child.currentIndex,
              );
              setState(() {
                _selectedIndex.value = index;
              });
            },
            destinations: !offlineMode.value
                ? [
              NavigationDestination(
                icon: const Icon(FluentIcons.home_24_filled, color: Colors.grey),
                selectedIcon: const Icon(FluentIcons.home_24_filled,color: Colors.deepOrangeAccent),
                label: context.l10n?.home ?? 'Home',
              ),
              NavigationDestination(
                icon: const Icon(FluentIcons.news_16_filled, color: Colors.grey),
                selectedIcon: const Icon(FluentIcons.news_16_filled),
                label: context.l10n?.news ?? 'News',
              ),
              NavigationDestination(
                icon: const Icon(FluentIcons.music_note_2_play_20_filled, color: Colors.grey),
                selectedIcon: const Icon(FluentIcons.music_note_2_play_20_filled),
                label: context.l10n?.songs ?? 'Songs',
              ),
              NavigationDestination(
                icon: const Icon(FluentIcons.music_note_1_24_filled, color: Colors.grey),
                selectedIcon: const Icon(FluentIcons.music_note_1_24_filled),
                label: context.l10n?.library ?? 'Library',
              ),
              NavigationDestination(
                icon: const Icon(
                  FluentIcons.settings_20_filled, color: Colors.grey,
                ),
                selectedIcon: const Icon(
                  FluentIcons.settings_20_filled, color: Colors.grey,
                ),
                label: context.l10n?.settings ?? 'Settings',
              ),
            ]
                : [
              NavigationDestination(
                icon: const Icon(FluentIcons.home_24_regular, color: Colors.grey,),
                selectedIcon: const Icon(FluentIcons.home_24_filled),
                label: context.l10n?.home ?? 'Home',
              ),
              NavigationDestination(
                icon: const Icon(
                  FluentIcons.settings_24_regular,
                ),
                selectedIcon: const Icon(
                  FluentIcons.settings_24_filled,
                ),
                label: context.l10n?.settings ?? 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
