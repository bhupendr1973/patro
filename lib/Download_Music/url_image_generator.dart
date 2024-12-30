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


import 'package:hive_flutter/hive_flutter.dart';

import 'image_quality.dart';

class UrlImageGetter {
  final List<String?> _imageUrls;
  final _enableImageOptimization = Hive.box('settings').get(
    'enableImageOptimization',
    defaultValue: false,
  ) as bool;

  UrlImageGetter(this._imageUrls);

  String get lowQuality => getImageUrl(
    quality: ImageQuality.low,
  );
  String get mediumQuality => getImageUrl(
    quality: ImageQuality.medium,
  );
  String get highQuality => getImageUrl();

  String getImageUrl({
    ImageQuality? quality = ImageQuality.high,
  }) {
    if (_imageUrls.isEmpty) return '';
    final length = _imageUrls.length;

    ImageQuality? imageQuality = quality;

    if (_enableImageOptimization == false) {
      switch (imageQuality) {
        case ImageQuality.low:
          imageQuality = ImageQuality.medium;
        case ImageQuality.medium:
          imageQuality = ImageQuality.high;
        default:
          imageQuality = ImageQuality.high;
      }
    }

    switch (imageQuality) {
      case ImageQuality.high:
        return length == 1
            ? (_imageUrls.first
            ?.trim()
            .replaceAll('http:', 'https:')
            .replaceAll('50x50', '500x500')
            .replaceAll('150x150', '500x500') ??
            '')
            : _imageUrls.last ?? '';
      case ImageQuality.medium:
        return length == 1
            ? _imageUrls.first
            ?.trim()
            .replaceAll('http:', 'https:')
            .replaceAll('50x50', '150x150')
            .replaceAll('500x500', '150x150') ??
            ''
            : _imageUrls[length ~/ 2] ?? '';
      case ImageQuality.low:
        return length == 1
            ? _imageUrls.first
            ?.trim()
            .replaceAll('http:', 'https:')
            .replaceAll('150x150', '50x50')
            .replaceAll('500x500', '50x50') ??
            ''
            : _imageUrls.first!;
      default:
        return length == 1
            ? _imageUrls.first
            ?.trim()
            .replaceAll('http:', 'https:')
            .replaceAll('50x50', '500x500')
            .replaceAll('150x150', '500x500') ??
            ''
            : _imageUrls.last!;
    }
  }
}
