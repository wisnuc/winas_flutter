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
      return aIcon(Winas.gif, Colors.deepOrange);
    case 'jpg':
    case 'jpeg':
      return aIcon(Winas.jpg, Colors.deepOrange);
    case 'mov':
      return aIcon(Winas.mov, Colors.deepOrange);
    case 'mp4':
      return aIcon(Winas.mp4, Colors.deepOrange);
    case 'png':
      return aIcon(Winas.png, Colors.deepOrange);
    case 'pdf':
      return aIcon(Winas.word, Colors.blue);
    case 'docx':
    case 'doc':
      return aIcon(Winas.word, Colors.blue);
    case 'pptx':
    case 'ppt':
      return aIcon(Winas.ppt, Colors.deepOrange);
    case 'xls':
    case 'xlsx':
      return aIcon(Winas.excel, Colors.green);
    default:
      return aIcon(Icons.insert_drive_file, Colors.black38);
  }
}
