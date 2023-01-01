library rapid.route;

import 'dart:io';

import 'package:rapid/src/context/context.dart';
import 'package:rapid/src/helpers/pattern_extractor.dart';
import 'package:rapid/src/response_writer/writer.dart';
import 'package:rapid/src/utils/constant.dart';

part 'matcher.dart';

class Route {
  // main data
  final String path; // path as String (native path)
  final PathPattern pattern;
  final List<CtxHandler> handlers; // handler function
  // option data
  final List<String> methods; // allowed methods
  final List<String> accepts; // accepted content types

  Route({
    required this.path,
    required this.methods,
    required this.accepts,
    required this.pattern,
    required this.handlers,
  });

  factory Route.extract({
    required String path,
    required String methods,
    required List<String> accepts,
    required List<CtxHandler> handlers,
  }) {
    final pattern = extractPathPattern(path);
    final methodsList = methods.split(',').map((e) => e.trim().toUpperCase()).toList();
    return Route(
      path: path,
      handlers: handlers,
      pattern: pattern,
      accepts: accepts,
      methods: methodsList,
    );
  }

  Map<String, String?>? matchAndParse(String path, String method, ContentType? contentType) {
    if (accepts.isNotEmpty && contentType != null && !accepts.contains(contentType.mimeType)) {
      return null;
    }

    final match = pattern.regExp.firstMatch(path);
    if (match == null) return null;
    Map<String, String?> pParams = {};
    for (var e in pattern.paramNames) {
      pParams.addAll({e: match.namedGroup(e)});
    }
    return pParams;
  }

  Future<ResponseBodyWriter?> call(Context c, int handlerIndex) async {
    Object? response = await handlers[handlerIndex](c);

    if (response is ResponseBodyWriter) return response;

    if (response is String) {
      return TextResponse(response);
    }

    if (response is Map<String, dynamic> || response is List<dynamic> || response is Set<dynamic>) {
      return JsonResponse(response);
    }

    if (response is Function(HttpRequest)) {
      return CustomResponse(response);
    }

    return null;
  }
}
