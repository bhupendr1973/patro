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


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:shrayesh_patro/extensions/l10n.dart';
import '../API/languagecodes.dart';
import '../API/shrayesh_patro.dart';
import '../Backup/backup_and_restore.dart';
import '../Backup/gradient_containers.dart';
import '../Update/about_screen.dart';
import '../main.dart';
import '../screens/search_page.dart';
import '../services/data_manager.dart';
import '../services/settings_manager.dart';
import '../style/player_gradient.dart';
import '../style/theme.dart';
import '../utilities/flutter_bottom_sheet.dart';
import '../utilities/flutter_toast.dart';
import '../widgets/confirmation_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Box settingsBox = Hive.box('settings');
  final ValueNotifier<bool> includeOrExclude = ValueNotifier<bool>(
    Hive.box('settings').get('includeOrExclude', defaultValue: false) as bool,
  );
  List includedExcludedPaths = Hive.box('settings')
      .get('includedExcludedPaths', defaultValue: []) as List;
  String lang =
  Hive.box('settings').get('lang', defaultValue: 'English') as String;
  bool useProxy =
  Hive.box('settings').get('useProxy', defaultValue: false) as bool;




  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            AppLocalizations.of(
              context,
            )!
                .settings,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(5.0),
          children: [
            ListTile(
              leading: const Icon(Icons.sunny),
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .themeMode,

                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .themeModeSub,
              ),
              dense: true,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (_, __, ___) =>
                    const ThemePage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
            title: Text(
              AppLocalizations.of(
                context,
              )!
                  .language,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
            ),
            ),
            subtitle: Text(
              AppLocalizations.of(
                context,
              )!
                  .languageSub,
            ),
            onTap: () {},
            trailing: DropdownButton(
              value: lang,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(
                        () {
                      lang = newValue;
                      MyApp.of(context).setLocale(
                        Locale.fromSubtags(
                          languageCode:
                          LanguageCodes.languageCodes[newValue] ?? 'en',
                        ),
                      );
                      Hive.box('settings').put('lang', newValue);
                    },
                  );
                }
              },
              items: LanguageCodes.languageCodes.keys
                  .map<DropdownMenuItem<String>>((language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(
                    language,
                  ),
                );
              }).toList(),
            ),
            dense: true,
          ),
            ListTile(
              leading: const Icon(Icons.design_services_rounded),
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .playerScreenBackground,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),

              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .playerScreenBackgroundSub,
              ),
              dense: true,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (_, __, ___) =>
                    const PlayerGradientSelection(),
                  ),
                );
              },
            ),

            ValueListenableBuilder<bool>(
              valueListenable: playNextSongAutomatically,
              builder: (_, value, __) {
                return ListTile(
                  leading: const Icon(Icons.music_note_rounded),
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .automaticSongPicker,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .automaticSongPickerSub,
                  ),
                  trailing: Switch(
                    value: value,
                    onChanged: (value) {
                      audioHandler.changeAutoPlayNextStatus();
                      showToast(
                        context,
                        context.l10n!.settingChangedMsg,

                      );
                    },
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.audio_file_rounded),
              title: Text(

                AppLocalizations.of(
                  context,
                )!
                    .audioQuality,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .audioQualitySub,
              ),
              onTap: () {
                final availableQualities = ['low', 'medium', 'high'];

                showCustomBottomSheet(
                  context,
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: availableQualities.length,
                    itemBuilder: (context, index) {
                      final quality = availableQualities[index];
                      final isCurrentQuality =
                          audioQualitySetting.value == quality;

                      return Card(
                        color: isCurrentQuality
                            ? Theme.of(context).colorScheme.secondary
                            :  Colors.transparent,
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          minTileHeight: 65,
                          title: Text(quality),
                          onTap: () {
                            addOrUpdateData(
                              'settings',
                              'audioQuality',
                              quality,
                            );
                            audioQualitySetting.value = quality;

                            showToast(
                              context,
                              context.l10n!.audioQualityMsg,
                            );
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .clearCache,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .clearCacheSub,
              ),
              onTap: () {
                clearCache();
                showToast(
                  context,
                  '${context.l10n!.cacheMsg}!',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search_off),
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .clearSearchHistory,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .clearSearchHistorySub,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return ConfirmationDialog(
                      submitMessage: context.l10n!.clear,
                      confirmationMessage:
                      context.l10n!.clearSearchHistoryQuestion,
                      onCancel: () => {Navigator.of(context).pop()},
                      onSubmit: () => {
                        Navigator.of(context).pop(),
                        searchHistory = [],
                        deleteData('user', 'searchHistory'),
                        showToast(
                          context,
                          '${context.l10n!.searchHistoryMsg}!',
                        ),
                      },
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle),
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .clearRecentlyPlayed,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .clearRecentlyPlayedSub,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return ConfirmationDialog(
                      submitMessage: context.l10n!.clear,
                      confirmationMessage:
                      context.l10n!.clearRecentlyPlayedQuestion,
                      onCancel: () => {Navigator.of(context).pop()},
                      onSubmit: () => {
                        Navigator.of(context).pop(),
                        userRecentlyPlayed = [],
                        deleteData('user', 'recentlyPlayedSongs'),
                        showToast(
                          context,
                          '${context.l10n!.recentlyPlayedMsg}!',
                        ),
                      },
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore_rounded),
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .backupUserData,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .backupUserDataSub,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const BackupAndRestorePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_rounded),
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .copyLogs,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .copyLogsSub,
              ),
              onTap: () async =>
                  showToast(context, await logger.copyLogs(context)),
            ),
            ListTile(
              leading: const Icon(Icons.info_rounded),
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .about,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .aboutSub,
              ),
              onTap: () =>  Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => const AboutScreen()),
              ),
            )
          ],
        ),
      ),
    );
  }
}
