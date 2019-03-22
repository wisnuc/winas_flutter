import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

import '../redux/redux.dart';
import '../common/stationApis.dart';

/// handle cancel an isolate (via Isolate.kill())
class CancelIsolate {
  Isolate target;
  bool canceled = false;

  cancel() {
    if (canceled) return;

    if (target != null) {
      try {
        target.kill();
      } catch (e) {
        print('kill isolate error:\n $e');
      }
    }
    canceled = true;
  }

  setTarget(Isolate work) {
    target = work;
  }
}

/// A sink used to get a digest value out of `Hash.startChunkedConversion`.
class DigestSink extends Sink<Digest> {
  /// The value added to the sink, if any.
  Digest get value {
    assert(_value != null);
    return _value;
  }

  Digest _value;

  /// Adds [value] to the sink.
  ///
  /// Unlike most sinks, this may only be called once.
  @override
  void add(Digest value) {
    assert(_value == null);
    _value = value;
  }

  @override
  void close() {
    assert(_value != null);
  }
}

/// Pure isolate function to hash file
void isolateHash(SendPort sendPort) {
  final port = ReceivePort();
  // send current sendPort to caller
  sendPort.send(port.sendPort);

  // listen message from caller
  port.listen((message) {
    final filePath = message[0] as String;
    final answerSend = message[1] as SendPort;
    File file = File(filePath);
    final stream = file.openRead();
    final ds = DigestSink();

    final s = sha256.startChunkedConversion(ds);
    stream.listen(
      (List<int> chunk) {
        s.add(chunk);
      },
      onDone: () {
        s.close();
        final digest = ds.value;
        answerSend.send(digest.toString());
        port.close();
      },
      onError: (error) {
        print(error);
        answerSend.send(null);
        port.close();
      },
      cancelOnError: true,
    );
  });
}

/// upload single photo to target dir in Isolate
void isolateUpload(SendPort sendPort) {
  final port = ReceivePort();

  // send current sendPort to caller
  sendPort.send(port.sendPort);

  // listen message from caller
  port.listen((message) {
    final entryJson = message[0] as String;
    final filePath = message[1] as String;
    final sha256Value = message[2] as String;
    final apisJson = message[3] as String;
    final isCloud = message[4] as bool;
    final answerSend = message[5] as SendPort;

    final dir = Entry.fromMap(jsonDecode(entryJson));

    final file = File(filePath);
    final apis = Apis.fromMap(jsonDecode(apisJson));

    // set network status
    apis.isCloud = isCloud;

    // Entry dir, File photo
    final fileName = file.path.split('/').last;

    final FileStat stat = file.statSync();

    final formDataOptions = {
      'op': 'newfile',
      'size': stat.size,
      'sha256': sha256Value,
      'bctime': stat.modified.millisecondsSinceEpoch,
      'bmtime': stat.modified.millisecondsSinceEpoch,
      'policy': ['rename', 'rename'],
    };

    final args = {
      'driveUUID': dir.pdrv,
      'dirUUID': dir.uuid,
      'fileName': fileName,
      'file': UploadFileInfo(file, jsonEncode(formDataOptions)),
    };

    apis.upload(args, (error, value) {
      if (error != null) {
        answerSend.send(error.toString());
      } else {
        answerSend.send(null);
      }
    });

    port.close();
  });
}

/// hash file in Isolate
Future<String> hashViaIsolate(String filePath,
    {CancelIsolate cancelIsolate}) async {
  final response = ReceivePort();
  final work = await Isolate.spawn(isolateHash, response.sendPort);

  if (cancelIsolate != null) {
    cancelIsolate.setTarget(work);
  }
  // sendPort from isolateHash
  final sendPort = await response.first as SendPort;
  final answer = ReceivePort();

  // send filePath and sendPort(to get answer) to isolateHash
  sendPort.send([filePath, answer.sendPort]);
  final res = await answer.first as String;
  return res;
}

/// upload file in Isolate
Future<void> uploadViaIsolate(
    Apis apis, Entry targetDir, String filePath, String hash,
    {CancelIsolate cancelIsolate}) async {
  final response = ReceivePort();

  final work = await Isolate.spawn(isolateUpload, response.sendPort);

  if (cancelIsolate != null) {
    cancelIsolate.setTarget(work);
  }

  // sendPort from isolateHash
  final sendPort = await response.first as SendPort;
  final answer = ReceivePort();

  // send filePath and sendPort(to get answer) to isolateHash
  // Object in params need to convert to String
  // final entryJson = message[0] as String;
  // final filePath = message[1] as String;
  // final hash = message[2] as String;
  // final apisJson = message[3] as String;
  // final isCloud = message[4] as bool;
  // final answerSend = message[5] as SendPort;

  sendPort.send([
    targetDir.toString(),
    filePath,
    hash,
    apis.toString(),
    apis.isCloud,
    answer.sendPort
  ]);
  final error = await answer.first;
  if (error != null) throw error;
}
