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

import 'dart:io';

import 'package:shrayesh_patro/Downloads/service.dart';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:shrayesh_patro/Backup/ext_storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

import '../API/shrayesh_patro.dart';
import '../main.dart';
import '../services/data_manager.dart';



final _yt = YoutubeExplode();
class Download with ChangeNotifier {
  static final Map<String, Download> _instances = {};
  final String id;

  factory Download(String id) {
    if (_instances.containsKey(id)) {
      return _instances[id]!;
    } else {
      final instance = Download._internal(id);
      _instances[id] = instance;
      return instance;
    }
  }

  Download._internal(this.id);

  int? rememberOption;
  final ValueNotifier<bool> remember = ValueNotifier<bool>(false);
  String preferredDownloadQuality = Hive.box('settings')
      .get('downloadQuality', defaultValue: '320 kbps') as String;
  String preferredYtDownloadQuality = Hive.box('settings')
      .get('ytDownloadQuality', defaultValue: 'High') as String;
  String downloadFormat = Hive.box('settings')
      .get('downloadFormat', defaultValue: 'm4a')
      .toString();
  bool createDownloadFolder = Hive.box('settings')
      .get('createDownloadFolder', defaultValue: false) as bool;
  bool createYoutubeFolder = Hive.box('settings')
      .get('createYoutubeFolder', defaultValue: false) as bool;
  double? progress = 0.0;
  String lastDownloadId = '';
  bool downloadLyrics =
  Hive.box('settings').get('downloadLyrics', defaultValue: false) as bool;
  bool download = true;

  Future<void> prepareDownload(
      BuildContext context,
      Map data, {
        bool createFolder = false,
        String? folderName,
      }) async {
    Logger.root.info('Preparing download for ${data['title']}');
    download = true;
    if (Platform.isAndroid || Platform.isIOS) {
      Logger.root.info('Requesting storage permission');
      PermissionStatus status = await Permission.storage.status;
      if (status.isDenied) {
        Logger.root.info('Request denied');
        await [
          Permission.storage,
          Permission.accessMediaLocation,
          Permission.mediaLibrary,
        ].request();
      }
      status = await Permission.storage.status;
      if (status.isPermanentlyDenied) {
        Logger.root.info('Request permanently denied');
        await openAppSettings();
      }
    }
    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    data['title'] = data['title'].toString().split('(From')[0].trim();
    final audioDirPath = await ExtStorageProvider.getExtStorage(dirName: 'Music', writeAccess: true);

    final artworkDirPath = '$audioDirPath/Pictures';
    final String ytid = data['ytid'];
    final audioFile = File('$audioDirPath/$ytid.m4a');
    final artworkFile0 = File('$artworkDirPath/$ytid.jpg');

    await Directory(audioDirPath!).create(recursive: true);
    await Directory(artworkDirPath).create(recursive: true);

    final audioManifest = await getSongManifest(ytid);
    final stream = _yt.videos.streamsClient.get(audioManifest);
    final fileStream = audioFile.openWrite();
    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    final artworkFile = await _downloadAndSaveArtworkFile(
      data['highResImage'],
      artworkFile0.path,
    );

    if (artworkFile != null) {
      data['artworkPath'] = artworkFile.path;
      data['highResImage'] = artworkFile.path;
      data['lowResImage'] = artworkFile.path;
    }
    data['audioPath'] = audioFile.path;
    userOfflineSongs.add(data);
    addOrUpdateData('userNoBackup', 'offlineSongs', userOfflineSongs);

    String filename = '';
    final int downFilename =
    Hive.box('settings').get('downFilename', defaultValue: 0) as int;
    if (downFilename == 0) {
      filename = '${data["title"]} - ${data["artist"]}';
    } else if (downFilename == 1) {
      filename = '${data["artist"]} - ${data["title"]}';
    } else {
      filename = '${data["title"]}';
    }

    String dlPath =
    Hive.box('settings').get('downloadPath', defaultValue: '') as String;
    Logger.root.info('Cached Download path: $dlPath');
    if (filename.length > 200) {
      final String temp = filename.substring(0, 200);
      final List tempList = temp.split(', ');
      tempList.removeLast();
      filename = tempList.join(', ');
    }

    filename = '${filename.replaceAll(avoid, "").replaceAll("  ", " ")}.m4a';
    if (dlPath == '') {
      Logger.root.info('Cached Download path is empty, getting new path');
      final String? temp = await ExtStorageProvider.getExtStorage(
        dirName: 'Music',
        writeAccess: true,
      );
      dlPath = temp!;
    }
    Logger.root.info('New Download path: $dlPath');
    if (data['url'].toString().contains('google') && createYoutubeFolder) {
      Logger.root.info('Youtube audio detected, creating Youtube folder');
      dlPath = '$dlPath/YouTube';
      if (!await Directory(dlPath).exists()) {
        Logger.root.info('Creating Youtube folder');
        await Directory(dlPath).create();
      }
    }

    if (createFolder && createDownloadFolder && folderName != null) {
      final String foldername = folderName.replaceAll(avoid, '');
      dlPath = '$dlPath/$foldername';
      if (!await Directory(dlPath).exists()) {
        Logger.root.info('Creating folder $foldername');
        await Directory(dlPath).create();
      }
    }

    final bool exists = await File('$dlPath/$filename').exists();
    if (exists) {
      Logger.root.info('File already exists');
      if (remember.value == true && rememberOption != null) {
        switch (rememberOption) {
          case 0:
            lastDownloadId = data['ytid'].toString();
          case 1:
            downloadSong(dlPath, filename, data);
          case 2:
            while (await File('$dlPath/$filename').exists()) {
              filename = filename.replaceAll('.m4a', ' (1).m4a');
            }
          default:
            lastDownloadId = data['ytid'].toString();
            break;
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              title: Text(
                AppLocalizations.of(context)!.alreadyExists,
                style:
                TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '"${data['title']}" ${AppLocalizations.of(context)!.downAgain}',
                    softWrap: true,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
              actions: [
                Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: remember,
                      builder: (
                          BuildContext context,
                          bool rememberValue,
                          Widget? child,
                          ) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor:
                                Theme.of(context).colorScheme.secondary,
                                value: rememberValue,
                                onChanged: (bool? value) {
                                  remember.value = value ?? false;
                                },
                              ),
                              Text(
                                AppLocalizations.of(context)!.rememberChoice,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                  Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () {
                              lastDownloadId = data['ytid'].toString();
                              Navigator.pop(context);
                              rememberOption = 0;
                            },
                            child: Text(
                              AppLocalizations.of(context)!.no,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                  Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              Hive.box('downloads').delete(data['ytid']);
                              downloadSong(dlPath, filename, data);
                              rememberOption = 1;
                            },
                            child:
                            Text(AppLocalizations.of(context)!.yesReplace),
                          ),
                          const SizedBox(width: 5.0),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              while (await File('$dlPath/$filename').exists()) {
                                filename =
                                    filename.replaceAll('.m4a', ' (1).m4a');
                              }
                              rememberOption = 2;
                              downloadSong(dlPath, filename, data);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.yes,
                              style: TextStyle(
                                color:
                                Theme.of(context).colorScheme.secondary ==
                                    Colors.white
                                    ? Colors.black
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    } else {
      downloadSong(dlPath, filename, data);
    }
  }

  Future<void> downloadSong(
      String? dlPath,
      String fileName,
      Map data,
      ) async {
    Logger.root.info('processing download');
    progress = null;
    notifyListeners();
    String? filepath;
    late String filepath2;
    String? appPath;
    final List<int> bytes = [];
    final artname = fileName.replaceAll('.m4a', '.jpg');
    if (!Platform.isWindows) {
      Logger.root.info('Getting App Path for storing image');
      appPath = Hive.box('settings').get('tempDirPath')?.toString();
      appPath ??= (await getTemporaryDirectory()).path;
    } else {
      final Directory? temp = await getDownloadsDirectory();
      appPath = temp!.path;
    }

    try {
      Logger.root.info('Creating audio file $dlPath/$fileName');
      await File('$dlPath/$fileName')
          .create(recursive: true)
          .then((value) => filepath = value.path);
      Logger.root.info('Creating image file $appPath/$artname');
      await File('$appPath/$artname')
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
    } catch (e) {
      Logger.root
          .info('Error creating files, requesting additional permission');
      if (Platform.isAndroid) {
        PermissionStatus status = await Permission.manageExternalStorage.status;
        if (status.isDenied) {
          Logger.root.info(
            'ManageExternalStorage permission is denied, requesting permission',
          );
          await [
            Permission.manageExternalStorage,
          ].request();
        }
        status = await Permission.manageExternalStorage.status;
        if (status.isPermanentlyDenied) {
          Logger.root.info(
            'ManageExternalStorage Request is permanently denied, opening settings',
          );
          await openAppSettings();
        }
      }

      Logger.root.info('Retrying to create audio file');
      await File('$dlPath/$fileName')
          .create(recursive: true)
          .then((value) => filepath = value.path);

      Logger.root.info('Retrying to create image file');
      await File('$appPath/$artname')
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
    }
    String kUrl = data['url'].toString();

    if (!data['url'].toString().contains('google')) {
      Logger.root.info('Fetching jiosaavn download url with preferred quality');
      kUrl = kUrl.replaceAll(
        '_96.',
        "_${preferredDownloadQuality.replaceAll(' kbps', '')}.",
      );
    }

    int total = 0;
    int recieved = 0;
    Client? client;
    Stream<List<int>> stream;

    if (data['url'].toString().contains('google')) {
      final AudioOnlyStreamInfo streamInfo =
          (await Services.instance.getStreamInfo(data['ytid'].toString()))
              .last;
      total = streamInfo.size.totalBytes;
      stream = Services.instance.getStreamClient(streamInfo);
    } else {
      Logger.root.info('Connecting to Client');
      client = Client();
      final response = await client.send(Request('GET', Uri.parse(kUrl)));
      total = response.contentLength ?? 0;
      stream = response.stream.asBroadcastStream();
    }
    Logger.root.info('Client connected, Starting download');
    stream.listen((value) {
      bytes.addAll(value);
      try {
        recieved += value.length;
        progress = recieved / total;
        notifyListeners();
        if (!download && client != null) {
          client.close();

        }
      } catch (e) {
        Logger.root.severe('Error in download: $e');
      }
    }).onDone(() async {
      if (download) {
        Logger.root.info('Download complete, modifying file');
        final file = File(filepath!);
        await file.writeAsBytes(bytes);
        final client = HttpClient();
        try {
          Logger.root.info('Download complete, modifying file');
          if (downloadLyrics) {
            Logger.root.info('download');
          }
        } catch (e) {
          Logger.root.severe('Error fetching lyrics: $e');
        }

        Logger.root.info('Getting audio tags');
        if (Platform.isAndroid) {
          try {
            final Tag tag = Tag(
              title: data['title'].toString(),
              artist: data['artist'].toString(),
              artwork: filepath2,
              album: data['album'].toString(),
              comment: 'Shrayesh-Music',
            );
            Logger.root.info('Started tag editing');
            final tagger = Audiotagger();
            await tagger.writeTags(
              path: filepath!,
              tag: tag,
            );
          } catch (e) {
            Logger.root.severe('Error editing tags: $e');
          }
        } else {
          if (data['language'].toString() == 'YouTube') {
            Logger.root.info('Started tag editing');
            await MetadataGod.writeMetadata(
              file: filepath!,
              metadata: Metadata(
                title: data['title'].toString(),
                artist: data['artist'].toString(),
                album: data['album'].toString(),
                durationMs: int.parse(data['duration'].toString()) * 1000,
                fileSize: file.lengthSync(),


              ),
            );
          }
        }
        Logger.root.info('Closing connection & notifying listeners');
        client.close();
        lastDownloadId = data['id'].toString();
        progress = 0.0;
        notifyListeners();

        Logger.root.info('Putting data to downloads database');
        final songData = {
          'id': data['id'].toString(),
          'title': data['title'].toString(),
          'ytid': data['ytid'].toString(),
          'artist': data['artist'].toString(),
          'album': data['album'].toString(),
          'highResImage': data['highResImage'].toString(),
          'lowResImage': data['lowResImage'].toString(),
          'duration': data['duration'],
          'url': data['url'].toString(),
          'isLive': data['isLive'].toString(),
          'quality': preferredDownloadQuality,
          'path': filepath,
          'image': filepath2,
          'image_url': data['image'].toString(),

        };
        Hive.box('downloads').put(songData['id'].toString(), songData);

        Logger.root.info('Everything Done!');

      } else {
        download = true;
        progress = 0.0;
        File(filepath!).delete();
        File(filepath2).delete();
      }
    });
  }
}
Future<File?> _downloadAndSaveArtworkFile(String url, String filePath) async {
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      logger.log(
        'Failed to download file. Status code: ${response.statusCode}',
        null,
        null,
      );
    }
  } catch (e, stackTrace) {
    logger.log('Error downloading and saving file', e, stackTrace);
  }

  return null;
}