import 'package:flutter/material.dart';
import '../icons/winas_icons.dart';

Widget renderIcon(name, type) {
  return Icon(type == 'file' ? Winas.word : Icons.folder, color: Colors.blue);
}
