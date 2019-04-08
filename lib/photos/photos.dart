import 'dart:typed_data';
import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import './backup.dart';
import './photoList.dart';
import './devicePhotos.dart';
import '../redux/redux.dart';
import '../common/cache.dart';

const mediaTypes =
    'JPEG.PNG.JPG.GIF.BMP.RAW.RM.RMVB.WMV.AVI.MP4.3GP.MKV.MOV.FLV';
const videoTypes = 'RM.RMVB.WMV.AVI.MP4.3GP.MKV.MOV.FLV';

class Photos extends StatefulWidget {
  Photos({Key key, this.backupWorker}) : super(key: key);
  final BackupWorker backupWorker;
  @override
  _PhotosState createState() => new _PhotosState();
}

class _PhotosState extends State<Photos> {
  static bool loading = true;

  /// Album or LocalAlbum
  static List albumList = [];

  static String userUUID;
  ScrollController myScrollController = ScrollController();

  Future getCover(Album album, AppState state) async {
    Entry entry = album.items[0];

    final cm = await CacheManager.getInstance();
    final Uint8List thumbData = await cm.getThumbData(entry, state);

    if (this.mounted && thumbData != null) {
      album.setCover(thumbData);
      setState(() {});
    }
  }

  Future getLocalCover(LocalAlbum album) async {
    AssetEntity entity = album.items[0];
    final Uint8List thumbData = await entity.thumbDataWithSize(200, 200);
    if (this.mounted && thumbData != null) {
      album.setCover(thumbData);
      setState(() {});
    }
  }

  /// request and update drive list,
  Future<void> updateDrives(Store<AppState> store) async {
    AppState state = store.state;
    // get current drives data
    final res = await state.apis.req('drives', null);
    List<Drive> allDrives = List.from(
      res.data.map((drive) => Drive.fromMap(drive)),
    );

    store.dispatch(
      UpdateDrivesAction(allDrives),
    );
  }

  Future refresh(Store<AppState> store, bool isManual) async {
    AppState state = store.state;
    if (!isManual && state.localUser.uuid == userUUID && albumList.length > 0) {
      return;
    }
    int time = DateTime.now().millisecondsSinceEpoch;
    List<String> driveUUIDs = List.from(state.drives.map((d) => d.uuid));
    String places = driveUUIDs.join('.');
    List<AssetEntity> localAssetList;
    try {
      // req local photos
      try {
        List<AssetPathEntity> pathList = await PhotoManager.getAssetPathList();
        // get all photos
        localAssetList = await pathList[0].assetList;
        localAssetList = List.from(localAssetList);
      } catch (e) {
        print(e);
        localAssetList = [];
      }
      localAssetList.sort((a, b) => b.createTime - a.createTime);

      await updateDrives(store);

      print('get local photo: ${DateTime.now().millisecondsSinceEpoch - time}');
      // all photos and videos
      final res = await state.apis.req('search', {
        'places': places,
        'types': mediaTypes,
        'order': 'newest',
      });

      print('get nas photo: ${DateTime.now().millisecondsSinceEpoch - time}');
      final List<Entry> allMedia = List.from(
        res.data.map((d) => Entry.fromSearch(d, state.drives)).where(
            (d) => d?.metadata?.height != null && d?.metadata?.width != null),
      );

      // sort allMedia
      allMedia.sort((a, b) {
        int order = b.hdate.compareTo(a.hdate);
        return order == 0 ? b.mtime.compareTo(a.mtime) : order;
      });
      print('sort photo: ${DateTime.now().millisecondsSinceEpoch - time}');
      final allMediaAlbum = Album(allMedia, '所有照片', places);

      final videoArray = videoTypes.split('.');

      final List<Entry> allVideos = List.from(
        allMedia.where(
          (entry) => videoArray.contains(entry?.metadata?.type),
        ),
      );

      final allVideosAlbum = Album(allVideos, '所有视频', places);
      final localAlbum = LocalAlbum(localAssetList, '本机照片');

      // find photos in each backup drives, filter: lenth > 0
      final List<Album> backupAlbums = List.from(
        state.drives
            .where((d) => d.type == 'backup')
            .map(
              (d) => Album(
                    List.from(allMedia.where((entry) => entry.pdrv == d.uuid)),
                    d.label,
                    d.uuid,
                  ),
            )
            .where((a) => a.length > 0),
      );

      albumList = [];
      albumList.add(allMediaAlbum);
      albumList.add(allVideosAlbum);
      albumList.add(localAlbum);
      albumList.addAll(backupAlbums);

      // request album's cover
      for (var album in albumList) {
        if (album is Album) {
          getCover(album, state).catchError(print);
        } else if (album is LocalAlbum) {
          getLocalCover(album).catchError(print);
        }
      }
      print('get album: ${DateTime.now().millisecondsSinceEpoch - time}');
      // cache data
      userUUID = state.localUser.uuid;
      if (this.mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (error) {
      if (this.mounted) {
        setState(() {
          loading = false;
        });
      }
      // TODO: handle error
      throw error;
    }
  }

  /// refresh per second
  Future autoRefresh({bool isFirst = false}) async {
    await Future.delayed(
        isFirst ? Duration(milliseconds: 100) : Duration(seconds: 1));
    if (this.mounted) {
      if (!loading) {
        setState(() {});
      }
      autoRefresh();
    }
  }

  @override
  void initState() {
    super.initState();
    autoRefresh(isFirst: true).catchError(print);
  }

  List<Widget> renderSlivers() {
    return <Widget>[
      SliverPadding(
        padding: EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio: 0.8,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final album = albumList[index];
              final worker = widget.backupWorker;
              bool isBackuping = worker.isRunning && (album is LocalAlbum);
              return Container(
                child: Material(
                  child: InkWell(
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              if (album is Album) {
                                return PhotoList(album: album);
                              } else if (album is LocalAlbum) {
                                return DevicePhotos(
                                  album: album,
                                  backupWorker: widget.backupWorker,
                                );
                              }
                            },
                          ),
                        ),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: album.cover != null
                                ? Container(
                                    constraints: BoxConstraints.expand(),
                                    child: Image.memory(
                                      album.cover,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                  ),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
                            width: double.infinity,
                            child: Text(
                              isBackuping ? album.name + '-备份中' : album.name,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
                            width: double.infinity,
                            child: Text(
                              isBackuping
                                  ? worker.progress
                                  : album.length.toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: albumList.length,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Store<AppState>>(
      onInit: (store) => refresh(store, false).catchError(print),
      onDispose: (store) => {},
      converter: (store) => store,
      builder: (context, store) {
        AppState state = store.state;
        return Scaffold(
          appBar: AppBar(
            elevation: 2.0, // shadow
            brightness: Brightness.light,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black38),
            title: Text('相簿', style: TextStyle(color: Colors.black87)),
            actions: <Widget>[
              Center(
                child: Text('本机照片备份', style: TextStyle(color: Colors.black87)),
              ),
              Switch(
                activeColor: Colors.teal,
                value: state.config.autoBackup == true,
                onChanged: (value) {
                  store.dispatch(UpdateConfigAction(
                    Config(
                      gridView: state.config.gridView,
                      autoBackup: value,
                    ),
                  ));
                  if (value == true) {
                    widget.backupWorker.start();
                  } else {
                    widget.backupWorker.abort();
                  }
                },
              )
            ],
          ),
          body: loading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: () => refresh(store, true),
                  child: DraggableScrollbar.semicircle(
                    controller: myScrollController,
                    child: Container(
                      child: CustomScrollView(
                        controller: myScrollController,
                        physics: AlwaysScrollableScrollPhysics(),
                        slivers: renderSlivers(),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
