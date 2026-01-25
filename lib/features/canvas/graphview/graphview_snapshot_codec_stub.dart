import 'dart:convert';

Codec<List<int>, List<int>> createGraphHistoryCodec() =>
    const _PassThroughCodec();

class _PassThroughCodec extends Codec<List<int>, List<int>> {
  const _PassThroughCodec();

  static const _PassThroughConverter _converter = _PassThroughConverter();

  @override
  Converter<List<int>, List<int>> get decoder => _converter;

  @override
  Converter<List<int>, List<int>> get encoder => _converter;
}

class _PassThroughConverter extends Converter<List<int>, List<int>> {
  const _PassThroughConverter();

  @override
  List<int> convert(List<int> input) => List<int>.from(input);
}
