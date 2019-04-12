import 'package:flutter/material.dart';

List<Widget> appBarSlivers(double left, String title, {List<Widget> action}) {
  return [
    SliverAppBar(
      pinned: true,
      elevation: 0.0, // no shadow
      backgroundColor: left >= 72.0 ? Colors.grey[50] : Colors.transparent,
      centerTitle: false,
      brightness: Brightness.light,
      iconTheme: IconThemeData(color: Colors.black38),
      title: Text(
        title,
        style: TextStyle(
          color: left == 72.0 ? Colors.black87 : Colors.transparent,
          fontSize: 21,
          fontWeight: FontWeight.normal,
        ),
      ),
      actions: action,
    ),
    SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(left, 16, 16, 32),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 21,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    )
  ];
}
