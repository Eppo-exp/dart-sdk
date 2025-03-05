import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Generates an MD5 hash of the input string with the given salt
String getMD5Hash(String input, String salt) {
  final saltedInput = '$salt$input';
  final bytes = utf8.encode(saltedInput);
  final digest = md5.convert(bytes);
  return digest.toString();
}

/// Decodes a base64 encoded string to a UTF-8 string
String decodeBase64(String input) {
  if (input.isEmpty) return '';
  try {
    return utf8.decode(base64.decode(input));
  } catch (e) {
    return input; // Return original if decoding fails
  }
}

/// Encodes a string as base64
String encodeBase64(String input) {
  return base64.encode(utf8.encode(input));
}

/// Decodes a value based on its variation type
dynamic decodeValue(String encodedValue, String variationType) {
  final decodedString = decodeBase64(encodedValue);

  switch (variationType.toLowerCase()) {
    case 'integer':
      return int.tryParse(decodedString) ?? 0;
    case 'numeric':
      return double.tryParse(decodedString) ?? 0.0;
    case 'boolean':
      return decodedString.toLowerCase() == 'true';
    case 'json':
      try {
        return jsonDecode(decodedString);
      } catch (e) {
        return {};
      }
    case 'string':
    default:
      return decodedString;
  }
}

/// Decodes a map of base64 encoded strings
Map<String, String> decodeStringMap(Map<String, String> encodedMap) {
  return encodedMap.map((key, value) => MapEntry(key, decodeBase64(value)));
}
