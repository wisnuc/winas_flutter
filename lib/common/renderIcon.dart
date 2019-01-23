import 'package:flutter/material.dart';
import '../icons/winas_icons.dart';
import '../redux/redux.dart';

Widget renderIcon(String name, Metadata metadata) {
  String type = metadata?.type?.toLowerCase();
  if (type == null) {
    var nameList = name.split('.');
    type = nameList.length > 1
        ? nameList[nameList.length - 1].toLowerCase()
        : null;
  }
  switch (type) {
    case 'gif':
      return Icon(Winas.gif, color: Colors.deepOrange);
    case 'jpg':
    case 'jpeg':
      return Icon(Winas.jpg, color: Colors.deepOrange);
    case 'mov':
      return Icon(Winas.mov, color: Colors.deepOrange);
    case 'mp4':
      return Icon(Winas.mp4, color: Colors.deepOrange);
    case 'png':
      return Icon(Winas.png, color: Colors.deepOrange);
    case 'pdf':
      return Icon(Winas.word, color: Colors.blue);
    case 'docx':
    case 'doc':
      return Icon(Winas.word, color: Colors.blue);
    case 'pptx':
    case 'ppt':
      return Icon(Winas.ppt, color: Colors.deepOrange);
    case 'xls':
    case 'xlsx':
      return Icon(Winas.excel, color: Colors.green);
    default:
      return Icon(Icons.insert_drive_file);
  }
}
