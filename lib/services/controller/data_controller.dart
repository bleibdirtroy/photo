import 'dart:collection';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobileprism/services/controller/data_controller_exceptions.dart';
import 'package:mobileprism/services/database/photo_data_entry.dart';
import 'package:mobileprism/services/encoder/album_encoder.dart';
import 'package:mobileprism/services/encoder/photo_encoder.dart';
import 'package:mobileprism/services/rest_api/album_type.dart';
import 'package:mobileprism/services/rest_api/photo_format.dart';
import 'package:mobileprism/services/rest_api/rest_api_service.dart';

const allImages = 9999999;

class DataController {
  final albumEncoder = AlbumEncoder();
  final photoEncoder = PhotoEncoder();
  late final restApiService = RestApiService();

  DataController();

  Future<List<Map<String, dynamic>>> getAlbums() async {
    final albumsString = await restApiService.getAlbums(
      albumType: AlbumType.album,
      count: allImages,
    );
    return albumEncoder.stringToAlbumsMap(albumsString);
  }

  Future<List<PhotoDataEntry>> getPhotosOfAlbum(
    String albumUid,
  ) async {
    final photosString = await restApiService.getPhotos(
      count: allImages,
      albumUid: albumUid,
    );
    return photoEncoder.stringToPhotoData(photosString);
  }

  Future<Map<int, SplayTreeSet<int>>> getOccupiedDates() async {
    final Map<int, SplayTreeSet<int>> yearsAndMonths = {};
    if (await _hasDeviceConnection()) {
      final albumsString = await restApiService.getAlbums(
        albumType: AlbumType.month,
        count: allImages,
      );
      final albums = albumEncoder.stringToAlbumsMap(albumsString);
      for (var i = 0; i < albums.length; i++) {
        final year = int.parse(albums[i]["Year"].toString());
        final month = int.parse(albums[i]["Month"].toString());
        yearsAndMonths.containsKey(year)
            ? yearsAndMonths[year]!.add(month)
            : yearsAndMonths.addAll({
                year: SplayTreeSet<int>.from({month})
              });
      }
    }
    return yearsAndMonths;
  }

  Future<List<PhotoDataEntry>> getPhotosOfMonthAndYear(DateTime time) async {
    final photosString = await restApiService.getPhotos(
      count: allImages,
      month: time.month,
      year: time.year,
      merged: true,
    );
    return photoEncoder.stringToPhotoData(photosString);
  }

  Future<bool> _hasDeviceConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return ConnectivityResult.none != connectivityResult;
  }

  Future<String> getPhotoUrl(String hash) async {
    return (await restApiService.buildPhotoUrl(
      hash: hash,
      photoFormat: PhotoFormat.fit_7680,
    ))
        .toString();
  }

  Future<String> getPreviewPhotoUrl(String hash) async {
    return (await restApiService.buildPhotoUrl(
      hash: hash,
      photoFormat: PhotoFormat.tile_500,
    ))
        .toString();
  }
}
