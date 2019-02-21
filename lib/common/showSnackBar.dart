import 'package:flutter/material.dart';

void showSnackBar(BuildContext ctx, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    duration: Duration(seconds: 1),
  );

  // Find the Scaffold in the Widget tree and use it to show a SnackBar!
  // Scaffold.of(ctx, nullOk: true)?.showSnackBar(snackBar);
  Scaffold.of(ctx).showSnackBar(snackBar);
}
