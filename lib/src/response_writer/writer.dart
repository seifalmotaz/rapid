library rapid.response_writer;

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:rapid/src/context/context.dart';

part 'custom_writers.dart';

abstract class ResponseBodyWriter {
  int status;
  final dynamic body;
  ResponseBodyWriter(this.body, [this.status = 200]);

  Future<void> write(HttpRequest req);
}

extension ResponseBodyMaker on Context {
  ResponseBodyWriter text(int status, String body) => TextResponse(body, status);
  ResponseBodyWriter json(int status, Map<String, dynamic> body) => JsonResponse(body, status);
}
