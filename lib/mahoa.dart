import 'package:encrypt/encrypt.dart' as encrypt;

String decryptAes(String encryptedBase64, String keyString, String ivString) {
  final key = encrypt.Key.fromUtf8(keyString); // phải 16 bytes
  final iv = encrypt.IV.fromUtf8(ivString); // phải 16 bytes

  final encrypter = encrypt.Encrypter(
    encrypt.AES(key, mode: encrypt.AESMode.cbc),
  );

  final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);
  return decrypted;
}
