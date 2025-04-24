import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class GenerateTestUserSig {
  static int sdkAppId = 20022321;
  // static int expireTime = 604800;
  static String secretKey = '344692cd93bdf2e02be060d8f8755e5237059fe9bee25a151d6f88fa21c08c46';
  static int appId = 1256635546;
  static int bizId = 93434;

  static genTestSig(String userId) {
    int currTime = _getCurrentTime();
    String sig = '';
    Map<String, dynamic> sigDoc = <String, dynamic>{};
    sigDoc.addAll({
      "TLS.ver": "2.0",
      "TLS.identifier": userId,
      "TLS.sdkappid": sdkAppId,
      // "TLS.expire": expireTime,
      // "TLS.time": currTime,
    });

    sig = _hmacSHA256(
      identifier: userId,
      currTime: currTime,
      // expire: expireTime,
    );
    sigDoc['TLS.sig'] = sig;
    String jsonStr = json.encode(sigDoc);
    List<int> compress = zlib.encode(utf8.encode(jsonStr));
    return _escape(content: base64.encode(compress));
  }

  static int _getCurrentTime() {
    return (DateTime.now().millisecondsSinceEpoch / 1000).floor();
  }

  static String _hmacSHA256({
    required String identifier,
    required int currTime,
    // required int expire,
  }) {
    int sdkappid = sdkAppId;
    String contentToBeSigned =
        "TLS.identifier:$identifier\nTLS.sdkappid:$sdkappid\nTLS.time:$currTime\n";
    Hmac hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
    Digest hmacSha256Digest =
        hmacSha256.convert(utf8.encode(contentToBeSigned));
    return base64.encode(hmacSha256Digest.bytes);
  }

  static String _escape({
    required String content,
  }) {
    return content
        .replaceAll('+', '*')
        .replaceAll('/', '-')
        .replaceAll('=', '_');
  }
}
