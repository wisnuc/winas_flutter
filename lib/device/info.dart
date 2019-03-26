import '../common/utils.dart';

class Info {
  String bleAddr;
  String eccName;
  String bandwidth;
  String sn;
  String cert;
  String address;
  String interfaceName;

  String fingerprint;
  String signer;
  String certNotBefore;
  String certNotAfter;
  Info.fromMap(Map m) {
    final device = m['device'];
    final net = m['net'];
    this.bleAddr = device['bleAddr'];
    this.eccName = device['ecc'];

    this.sn = device['sn'];
    this.cert = device['cert'];
    if (net != null && net['state'] == 70) {
      final interface = net['addresses'][0];
      this.bandwidth = '${interface['speed']} Mbps';
      this.address = interface['address'];
      this.interfaceName = interface['address'];
    } else {
      this.bandwidth = '未知';
      this.address = '未知';
      this.interfaceName = '未知';
    }

    this.fingerprint = device['fingerprint'];
    this.signer = device['signer'];
    this.certNotBefore = prettyDate(device['notBefore']);
    this.certNotAfter = prettyDate(device['notAfter']);
  }
}
