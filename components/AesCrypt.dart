import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:convert/convert.dart';
import 'dart:convert';

String decryptAES(String encryptedData, String secretKey) {
  final key =
      encrypt.Key.fromUtf8(secretKey.padRight(32, '0').substring(0, 32));
      
  final iv =
      encrypt.IV.fromLength(16); // Ganti dengan IV yang digunakan saat enkripsi
  final encrypter = encrypt.Encrypter(encrypt.AES(key));

  final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
  final decrypted = encrypter.decrypt(encrypted, iv: iv);
  return decrypted;
}

void main() {
  final encryptedData = 'U2FsdGVkX1/kVeNWlob12cF/nBdQzOjWh0If7GVcgGs=';
  final secret_key = 'ji2IZh5XaUAtgA2ubqoq';
  final decryptedData = decryptAES(encryptedData, secret_key);
  print(decryptedData);
}
