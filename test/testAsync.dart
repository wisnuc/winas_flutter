import 'dart:async';

Future<String> oneSecondLater() {
  print('before Future.delayed');
  var a = Future.delayed(Duration(seconds: 1), () => '1s later');
  print('after Future.delayed');
  return a;
}

Future<void> printDailyNewsDigest() async {
  print('before await str');
  var str = await oneSecondLater();
  print(str);
}

main() {
  print('1');
  printDailyNewsDigest();
  print('2');
}
