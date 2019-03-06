import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import './photoList.dart';
import '../redux/redux.dart';
import '../common/cache.dart';

const mediaTypes =
    'JPEG.PNG.JPG.GIF.BMP.RAW.RM.RMVB.WMV.AVI.MP4.3GP.MKV.MOV.FLV';
const videoTypes = 'RM.RMVB.WMV.AVI.MP4.3GP.MKV.MOV.FLV';

class Photos extends StatefulWidget {
  Photos({Key key}) : super(key: key);

  @override
  _PhotosState createState() => new _PhotosState();
}

class _PhotosState extends State<Photos> {
  static bool loading = true;
  static List<Album> albumList = [];
  static String userUUID;
  ScrollController myScrollController = ScrollController();

  Future getCover(Album album, AppState state) async {
    Entry entry = album.items[0];

    final cm = await CacheManager.getInstance();
    final String thumbSrc = await cm.getThumb(entry, state);

    if (this.mounted && thumbSrc != null) {
      album.setCover(thumbSrc);
      setState(() {});
    }
  }

  Future refresh(AppState state, bool isManual) async {
    if (!isManual && state.localUser.uuid == userUUID && albumList.length > 0) {
      return;
    }

    List<String> driveUUIDs = List.from(state.drives.map((d) => d.uuid));
    String places = driveUUIDs.join('.');

    try {
      // all photos and videos
      final res = await state.apis.req('search', {
        'places': places,
        'types': mediaTypes,
        'order': 'newest',
      });

      final List<Entry> allMedia = List.from(
        res.data.map((d) => Entry.fromSearch(d, state.drives)),
      );

      final allMediaAlbum = Album(allMedia, '所有照片', places);

      final videoArray = videoTypes.split('.');

      final List<Entry> allVideos = List.from(
        allMedia.where(
          (entry) => videoArray.contains(entry?.metadata?.type),
        ),
      );
      final allVideosAlbum = Album(allVideos, '所有视频', places);

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
      albumList.addAll(backupAlbums);

      // request album's cover
      for (Album album in albumList) {
        getCover(album, state).catchError(print);
      }

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
      throw error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) =>
          refresh(store.state, false).catchError((error) => print(error)),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
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
              : RefreshIndicator(
                  onRefresh: () => refresh(state, true),
                  child: DraggableScrollbar.semicircle(
                    controller: myScrollController,
                    child: Container(
                      child: CustomScrollView(
                        controller: myScrollController,
                        physics: AlwaysScrollableScrollPhysics(),
                        slivers: <Widget>[
                          SliverPadding(
                              padding: EdgeInsets.all(16),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16.0,
                                  crossAxisSpacing: 16.0,
                                  childAspectRatio: 0.8,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (BuildContext context, int index) {
                                    Album album = albumList[index];
                                    return Container(
                                      child: Material(
                                        child: InkWell(
                                          onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return PhotoList(
                                                        album: album);
                                                  },
                                                ),
                                              ),
                                          child: Container(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: album.cover != null
                                                      ? Image.file(
                                                          File(album.cover),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : Container(
                                                          color:
                                                              Colors.grey[300],
                                                        ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.fromLTRB(
                                                      0, 4, 0, 4),
                                                  width: double.infinity,
                                                  child: Text(album.name),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.fromLTRB(
                                                      0, 0, 0, 4),
                                                  width: double.infinity,
                                                  child: Text(
                                                      album.length.toString()),
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
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
