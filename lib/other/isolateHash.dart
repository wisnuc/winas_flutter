import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:crypto/crypto.dart';

void isolateHash(SendPort sendPort) {
  final port = ReceivePort();
  // send current sendPort to caller
  sendPort.send(port.sendPort);

  // listen message from caller
  port.listen((message) {
    final filePath = message[0] as String;
    final answerSend = message[1] as SendPort;
    File file = File(filePath);
    List<int> bytes = file.readAsBytesSync();
    final digest = sha256.convert(bytes);
    answerSend.send(digest.toString());
  });
}

Future<String> hashViaIsolate(String filePath) async {
  final response = ReceivePort();
  await Isolate.spawn(isolateHash, response.sendPort);

  // sendPort from isolateHash
  final sendPort = await response.first as SendPort;
  final answer = ReceivePort();

  // send filePath and sendPort(to get answer) to isolateHash
  sendPort.send([filePath, answer.sendPort]);
  final res = await answer.first as String;
  return res;
}

/// hash file with throttle
// Future<String> hashWithThrottle(File file, List<int> bytes) async {
//   final chunkSize = 1024;
//   final ds = DigestSink();
//   ByteConversionSink value = sha256.startChunkedConversion(ds);
//   print('size ${bytes.length}');
//   for (int i = 0; i < bytes.length; i += chunkSize) {
//     await Future.delayed(Duration.zero);
//     final end = i + chunkSize <= bytes.length ? i + chunkSize : bytes.length;
//     value.add(bytes.sublist(i, end));
//   }
//   value.close();
//   Digest digest = ds.value;
//   return digest.toString();
// }
