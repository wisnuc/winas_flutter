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
    this.bandwidth = '${net['networkInterface']['speed']} Mbps';
    this.sn = device['sn'];
    this.cert = device['cert'];
    this.address = net['networkInterface']['address'];
    this.interfaceName = net['networkInterface']['interfaceName'];

    this.fingerprint = device['fingerprint'];
    this.signer = device['signer'];
    this.certNotBefore = prettyDate(device['notBefore']);
    this.certNotAfter = prettyDate(device['notAfter']);
  }
}
