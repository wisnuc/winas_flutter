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
import '../icons/winas_icons.dart';

const mediaTypes =
    'JPEG.PNG.JPG.GIF.BMP.RAW.RM.RMVB.WMV.AVI.MP4.3GP.MKV.MOV.FLV.MPEG';
const videoTypes = 'RM.RMVB.WMV.AVI.MP4.3GP.MKV.MOV.FLV.MPEG';

class Photos extends StatefulWidget {
  Photos({Key key, this.backupWorker}) : super(key: key);
  final BackupWorker backupWorker;
  @override
  _PhotosState createState() => _PhotosState();
}

class _PhotosState extends State<Photos> {
  static bool loading = true;

  /// Album or LocalAlbum
  static List albumList = [];

  /// current users's userUUID
  static String userUUID;

  /// req data error
  bool error = false;

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

  /// request and update drive list
  Future<List<Drive>> updateDrives(Store<AppState> store) async {
    AppState state = store.state;
    // get current drives data
    final res = await state.apis.req('drives', null);
    List<Drive> allDrives = List.from(
      res.data.map((drive) => Drive.fromMap(drive)),
    );

    store.dispatch(
      UpdateDrivesAction(allDrives),
    );
    return allDrives;
  }

  /// req local Photos
  Future<List<AssetEntity>> localPhotos() async {
    int time = DateTime.now().millisecondsSinceEpoch;
    List<AssetEntity> localAssetList;
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
    print('get local photo: ${DateTime.now().millisecondsSinceEpoch - time}');
    return localAssetList;
  }

  /// req nasPhotos
  Future<List<Entry>> nasPhotos(Store<AppState> store) async {
    int time = DateTime.now().millisecondsSinceEpoch;
    AppState state = store.state;
    final List<Drive> drives = await updateDrives(store);

    List<String> driveUUIDs = List.from(drives.map((d) => d.uuid));
    String places = driveUUIDs.join('.');

    // all photos and videos
    final res = await state.apis.req('search', {
      'places': places,
      'types': mediaTypes,
      'order': 'newest',
    });

    final List<Entry> allMedia = List.from(
      res.data.map((d) => Entry.fromSearch(d, drives)).where(
          (d) => d?.metadata?.height != null && d?.metadata?.width != null),
    );

    // sort allMedia
    allMedia.sort((a, b) {
      int order = b.hdate.compareTo(a.hdate);
      return order == 0 ? b.mtime.compareTo(a.mtime) : order;
    });

    print('get nas photo: ${DateTime.now().millisecondsSinceEpoch - time}');
    return allMedia;
  }

  Future refresh(Store<AppState> store, bool isManual) async {
    // use store.state to keep the state as latest
    if (!isManual &&
        store.state.localUser.uuid == userUUID &&
        albumList.length > 0) {
      return;
    }

    /// reload after error
    if (isManual && error) {
      setState(() {
        error = false;
        loading = true;
      });
    }

    try {
      // req data
      // final List res = await Future.wait([localPhotos(), nasPhotos(store)]);

      //local photos
      // List<AssetEntity> localAssetList = res[0];

      //nas photos
      List<Entry> allMedia = await nasPhotos(store);

      final allMediaAlbum = Album(allMedia, '所有照片');

      final videoArray = videoTypes.split('.');

      final List<Entry> allVideos = List.from(
        allMedia.where(
          (entry) => videoArray.contains(entry?.metadata?.type),
        ),
      );

      final allVideosAlbum = Album(allVideos, '所有视频');
      // final localAlbum = LocalAlbum(localAssetList, '本机照片');

      // find photos in each backup drives, filter: lenth > 0
      final List<Album> backupAlbums = List.from(
        store.state.drives
            .where((d) => d.type == 'backup')
            .map(
              (d) => Album(
                    List.from(allMedia.where((entry) => entry.pdrv == d.uuid)),
                    d.label,
                  ),
            )
            .where((a) => a.length > 0),
      );

      albumList = [];
      albumList.add(allMediaAlbum);
      albumList.add(allVideosAlbum);
      // albumList.add(localAlbum);
      albumList.addAll(backupAlbums);

      // request album's cover
      for (var album in albumList) {
        if (album is Album) {
          getCover(album, store.state).catchError(print);
        } else if (album is LocalAlbum) {
          getLocalCover(album).catchError(print);
        }
      }

      // cache data
      userUUID = store.state.localUser.uuid;
      if (this.mounted) {
        setState(() {
          loading = false;
          error = false;
        });
      }
    } catch (e) {
      print(e);
      if (this.mounted) {
        setState(() {
          loading = false;
          error = true;
        });
      }
    }
  }

  /// refresh per second to show backup progress
  Future autoRefresh({bool isFirst = false}) async {
    await Future.delayed(
        isFirst ? Duration(milliseconds: 100) : Duration(seconds: 1));
    if (this.mounted) {
      if (!loading && !error) {
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

  List<Widget> renderSlivers(Store store) {
    final worker = widget.backupWorker;
    return <Widget>[
      // backup switch
      SliverToBoxAdapter(
        child: loading || error
            ? Container()
            : Container(
                padding: EdgeInsets.only(left: 16, right: 8),
                color: Colors.blue,
                child: Row(
                  children: <Widget>[
                    Center(
                      child: Text(
                        worker.isFinished
                            ? '备份已经完成'
                            : worker.isRunning ? '备份照片中' : '本机照片备份',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Container(width: 16),
                    Expanded(
                      child: Container(
                        child: Text(
                          worker.isRunning ? worker.progress : '',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      flex: 1,
                    ),
                    Text(
                      store.state.config.autoBackup == true ? '' : '备份已关闭',
                      style: TextStyle(color: Colors.white),
                    ),
                    Switch(
                      activeColor: Colors.white,
                      value: store.state.config.autoBackup == true,
                      onChanged: (value) {
                        store.dispatch(UpdateConfigAction(
                          Config(
                            gridView: store.state.config.gridView,
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
              ),
      ),
      // backup loading
      SliverToBoxAdapter(
        child: worker.isRunning
            ? Container(
                child: LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.blue[700]),
                  backgroundColor: Colors.blue,
                ),
              )
            : Container(),
      ),

      // all photos
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
                              album.name,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
                            width: double.infinity,
                            child: Text(
                              album.length.toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: 2,
          ),
        ),
      ),

      SliverToBoxAdapter(
        child: albumList.length - 2 < 1
            ? Container()
            : Container(
                padding: EdgeInsets.only(left: 16, right: 8),
                // padding: EdgeInsets.all(16),
                child: Text('来自备份的照片', style: TextStyle(fontSize: 18)),
              ),
      ),

      // backup drives
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
              final album = albumList[index + 2];
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
                              album.name,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
                            width: double.infinity,
                            child: Text(
                              album.length.toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: albumList.length - 2,
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
        return Scaffold(
          appBar: AppBar(
            elevation: 2.0, // shadow
            brightness: Brightness.light,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black38),
            title: Text('相簿', style: TextStyle(color: Colors.black87)),
          ),
          body: loading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : error
                  ? Center(
                      child: Column(
                        children: <Widget>[
                          Expanded(flex: 4, child: Container()),
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Container(
                              width: 72,
                              height: 72,
                              // padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(36),
                              ),
                              child: Icon(
                                Winas.logo,
                                color: Colors.grey[50],
                                size: 84,
                              ),
                            ),
                          ),
                          Text(
                            '加载页面失败，请检查网络设置',
                            style: TextStyle(color: Colors.black38),
                          ),
                          FlatButton(
                            padding: EdgeInsets.all(0),
                            child: Text(
                              '重新加载',
                              style: TextStyle(color: Colors.teal),
                            ),
                            onPressed: () => refresh(store, true),
                          ),
                          Expanded(flex: 6, child: Container()),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => refresh(store, true),
                      child: DraggableScrollbar.semicircle(
                        controller: myScrollController,
                        child: Container(
                          child: CustomScrollView(
                            controller: myScrollController,
                            physics: AlwaysScrollableScrollPhysics(),
                            slivers: renderSlivers(store),
                          ),
                        ),
                      ),
                    ),
        );
      },
    );
  }
}
