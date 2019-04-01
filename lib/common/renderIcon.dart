import 'package:flutter/material.dart';
import '../icons/winas_icons.dart';
import '../redux/redux.dart';

Function sizedIcon = (double size) =>
    ((IconData data, Color color) => Icon(data, color: color, size: size));

Widget renderIcon(String name, Metadata metadata, {double size: 24}) {
  String type = metadata?.type?.toLowerCase();
  Function aIcon = sizedIcon(size);
  if (type == null) {
    var nameList = name.split('.');
    type = nameList.length > 1
        ? nameList[nameList.length - 1].toLowerCase()
        : null;
  }
  switch (type) {
    case 'gif':
      return aIcon(Winas.gif, Color(0xffea4335));
    case 'jpg':
    case 'jpeg':
      return aIcon(Winas.jpg, Color(0xffea4335));
    case 'png':
      return aIcon(Winas.png, Color(0xffea4335));
    case 'bmp':
    case 'heic':
      return aIcon(Icons.image, Color(0xffea4335));
    case 'mov':
      return aIcon(Winas.mov, Color(0xfff44336));
    case 'mp4':
      return aIcon(Winas.mp4, Color(0xfff44336));
    case 'mkv':
      return aIcon(Winas.video, Color(0xfff44336));

    case 'pdf':
      return aIcon(Winas.pdf, Color(0xFFdb4437));
    case 'docx':
    case 'doc':
      return aIcon(Winas.word, Color(0xFF4285f4));
    case 'txt':
      return aIcon(Winas.txt, Colors.grey);
    case 'pptx':
    case 'ppt':
      return aIcon(Winas.ppt, Color(0xFFdb4437));
    case 'xls':
    case 'xlsx':
      return aIcon(Winas.excel, Color(0xFF0f9d58));
    case 'mp3':
    case 'flac':
      return aIcon(Winas.audio, Color(0xFF00bcd4));
    default:
      return aIcon(Icons.insert_drive_file, Colors.black38);
  }
}
