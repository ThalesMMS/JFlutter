import 'dart:convert';
import 'dart:io';

Codec<List<int>, List<int>> createGraphHistoryCodec() => gzip;
