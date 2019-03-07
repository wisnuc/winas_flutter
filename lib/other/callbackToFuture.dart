import 'dart:async';

class Convert {
  /// convert Callback to Future
  Future callbackToAsync(props) async {
    Completer c = Completer();
    asyncToCallback(props, (error, value) {
      if (error != null) {
        c.completeError(error);
      } else {
        c.complete(value);
      }
    });
    return c.future;
  }

  /// convert Future to Callback
  void asyncToCallback(props, Function callback) {
    asyncFunction(props)
        .then((value) => callback(null, value))
        .catchError((onError) => callback(onError));
  }

  /// async function
  Future asyncFunction(props) async {
    await Future.delayed(Duration(seconds: 1));
  }
}
