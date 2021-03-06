// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../../sledge_errors.dart';
import '../change.dart';
import 'compressor.dart';
import 'converted_change.dart';
import 'key_value.dart';

/// Interface for converting T to Uint8List and back.
abstract class Converter<T> {
  /// Returns a converter of type T.
  factory Converter() {
    final result = _converters[T];
    if (result == null) {
      throw InternalSledgeError('No converter found for type `$T`.');
    }
    return result;
  }

  /// Returns default value for type T.
  T get defaultValue;

  /// Converts from Uint8List to T.
  T deserialize(final Uint8List x);

  /// Converts from T to Uint8List.
  Uint8List serialize(final T x);
}

/// Class for converting Map<K, V> to List<KeyValue> and back.
class MapToKVListConverter<K, V> {
  final Converter<K> _keyConverter;
  final Converter<V> _valueConverter;
  final Compressor _compressor = Compressor();

  /// Constructor.
  MapToKVListConverter({Converter<K> keyConverter, Converter<V> valueConverter})
      : _keyConverter = keyConverter ?? Converter<K>(),
        _valueConverter = valueConverter ?? Converter<V>();

  /// Converts from List<KeyValue> to Map<K, V>.
  ConvertedChange<K, V> deserialize(final Change _input) {
    final input = _uncompressKeysInChange(_input);
    final result = ConvertedChange<K, V>();
    for (var keyValue in input.changedEntries) {
      result.changedEntries[_keyConverter.deserialize(keyValue.key)] =
          _valueConverter.deserialize(keyValue.value);
    }
    for (var key in input.deletedKeys) {
      result.deletedKeys.add(_keyConverter.deserialize(key));
    }
    return result;
  }

  /// Converts from Map<K, V> to List<KeyValue>.
  Change serialize(final ConvertedChange<K, V> input) {
    final Change result = Change();
    for (final changedEntry in input.changedEntries.entries) {
      result.changedEntries.add(KeyValue(
          _keyConverter.serialize(changedEntry.key),
          _valueConverter.serialize(changedEntry.value)));
    }
    for (var key in input.deletedKeys) {
      result.deletedKeys.add(_keyConverter.serialize(key));
    }
    return _compressKeysInChange(result);
  }

  /// Restores (key, value)s from stored in Ledger state.
  Change _uncompressKeysInChange(final Change input) {
    Change result = Change();
    for (final entry in input.changedEntries) {
      result.changedEntries.add(_compressor.uncompressKeyInEntry(entry));
    }
    for (final key in input.deletedKeys) {
      result.deletedKeys.add(_compressor.uncompressKey(key));
    }
    return result;
  }

  /// Prepares (key, value)s to store in Ledger. (getting rid of long keys)
  Change _compressKeysInChange(final Change input) {
    Change result = Change();
    for (final entry in input.changedEntries) {
      result.changedEntries.add(_compressor.compressKeyInEntry(entry));
    }
    for (var key in input.deletedKeys) {
      result.deletedKeys.add(_compressor.compressKey(key));
    }
    return result;
  }
}

/// Converter for string.
class StringConverter implements Converter<String> {
  /// Constructor.
  const StringConverter();

  @override
  String get defaultValue => '';

  @override
  String deserialize(final Uint8List x) {
    if (x.length.isOdd) {
      throw InternalSledgeError(
          'Cannot parse String. Length should be even.');
    }
    return String.fromCharCodes(
        x.buffer.asUint16List(x.offsetInBytes, x.lengthInBytes ~/ 2));
  }

  @override
  Uint8List serialize(final String x) {
    return Uint16List.fromList(x.codeUnits).buffer.asUint8List();
  }
}

/// Converter for Int.
class IntConverter implements Converter<int> {
  /// Constructor.
  const IntConverter();

  static const int _serializationLength = 8;

  @override
  int get defaultValue => 0;

  @override
  int deserialize(final Uint8List x) {
    if (x.length != _serializationLength) {
      throw InternalSledgeError(
          "Can't parse int: Length should be $_serializationLength, "
          'found ${x.length} instead for input: `$x`.');
    }
    return x.buffer.asByteData().getInt64(x.offsetInBytes);
  }

  @override
  Uint8List serialize(final int x) =>
      Uint8List(_serializationLength)..buffer.asByteData().setInt64(0, x);
}

/// Converter for double.
class DoubleConverter implements Converter<double> {
  /// Constructor.
  const DoubleConverter();

  static const int _serializationLength = 8;

  @override
  double get defaultValue => 0.0;

  @override
  double deserialize(final Uint8List x) {
    if (x.length != _serializationLength) {
      throw InternalSledgeError(
          "Can't parse double: Length should be $_serializationLength, "
          'found ${x.length} instead for input: `$x`.');
    }
    return x.buffer.asByteData().getFloat64(x.offsetInBytes);
  }

  @override
  Uint8List serialize(final double x) =>
      Uint8List(_serializationLength)..buffer.asByteData().setFloat64(0, x);
}

/// Converter for bool.
class BoolConverter implements Converter<bool> {
  /// Constructor.
  const BoolConverter();

  @override
  bool get defaultValue => false;

  @override
  bool deserialize(final Uint8List x) {
    if (x.lengthInBytes != 1) {
      throw InternalSledgeError(
          "Can't parse bool. Length should be 1,"
          'found ${x.lengthInBytes} bytes instead.');
    }
    if (x[0] != 0 && x[0] != 1) {
      throw InternalSledgeError(
          "Can't parse bool. Value should be 0 or 1, "
          'found ${x[0]} bytes instead.');
    }
    return x[0] == 1;
  }

  @override
  // ignore: avoid_positional_boolean_parameters
  Uint8List serialize(final bool x) {
    return Uint8List.fromList([x ? 1 : 0]);
  }
}

/// Converter for Uint8List.
class Uint8ListConverter implements Converter<Uint8List> {
  /// Constructor.
  const Uint8ListConverter();

  @override
  Uint8List get defaultValue => Uint8List(0);

  @override
  Uint8List deserialize(final Uint8List x) => x;

  @override
  Uint8List serialize(final Uint8List x) => x;
}

enum _NumInternalType { _int, _double }

/// Converter for num.
class NumConverter implements Converter<num> {
  /// Constructor.
  const NumConverter();

  @override
  num get defaultValue => 0;

  // The length of the serialization:
  // 1 byte for the type of the number (_int or _double)
  //
  // 8 bytes for number itself (64 bit integer or 64 bit double).
  static const int _serializationLength = 9;

  @override
  num deserialize(final Uint8List x) {
    if (x.length != _serializationLength) {
      throw InternalSledgeError(
          "Can't parse double: Length should be $_serializationLength, "
          'found ${x.length} instead for input: `$x`.');
    }

    if (x[0] >= _NumInternalType.values.length) {
      throw InternalSledgeError(
          "Can't parse double: First byte should be 0 or 1, "
          'found ${x[0]} instead.');
    }

    _NumInternalType type = _NumInternalType.values[x[0]];
    num value;
    switch (type) {
      case _NumInternalType._int:
        value = x.buffer.asByteData().getInt64(x.offsetInBytes + 1);
        break;
      case _NumInternalType._double:
        value = x.buffer.asByteData().getFloat64(x.offsetInBytes + 1);
        break;
    }
    return value;
  }

  @override
  Uint8List serialize(final num x) {
    final list = Uint8List(_serializationLength);
    final byteData = list.buffer.asByteData();
    if (x.runtimeType == int) {
      byteData
        ..setInt8(0, _NumInternalType._int.index)
        ..setInt64(1, x);
    } else {
      byteData
        ..setInt8(0, _NumInternalType._double.index)
        ..setFloat64(1, x);
    }
    return list;
  }
}

const _converters = <Type, Converter>{
  int: IntConverter(),
  String: StringConverter(),
  double: DoubleConverter(),
  bool: BoolConverter(),
  Uint8List: Uint8ListConverter(),
  num: NumConverter(),
};
