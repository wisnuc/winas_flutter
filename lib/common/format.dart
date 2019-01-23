String prettySize(int size) {
  if (size == null) return '';
  if (size < 1024) return '$size B';
  if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
  if (size < 1024 * 1024 * 1024)
    return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
  return '${(size / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

String prettyDate(int time) {
  if (time == null) return '';
  var t = DateTime.fromMillisecondsSinceEpoch(time);
  var year = t.year;
  var month = t.month;
  var day = t.day;
  var hour = t.hour;
  var minute = t.minute;
  // var second = t.second;
  return '$year.$month.$day $hour: $minute';
}
