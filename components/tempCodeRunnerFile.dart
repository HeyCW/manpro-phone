import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/api.dart' as pointy;

class AESCrypt {
  final Key key;
  final IV iv;

  AESCrypt(String keyString)
      : key = Key.fromUtf8(keyString), // Key must be 32 bytes for AES-256
        iv = IV.fromLength(16); // Initialization vector

  String encrypt(String plainText) {
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64; // Return base64 string
  }

  String decrypt(String encryptedText) {
    final encrypter = Encrypter(AES(key));
    final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
    return decrypted;
  }
}

void main() {
  const String keyString =
      'ji2IZh5XaUAtgA2ubqoq'; // Must be 32 characters for AES-256
  final aesCrypt = AESCrypt(keyString);

  const plainText = '123';

  // Encrypt the plain text
  String encryptedText = aesCrypt.encrypt(plainText);
  print('Encrypted: $encryptedText');

  // Decrypt the encrypted text
  String decryptedText = aesCrypt.decrypt(encryptedText);
  print('Decrypted: $decryptedText');
}
