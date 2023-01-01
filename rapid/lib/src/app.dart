// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:io';

import 'package:rapid/src/route/route.dart';
import 'package:rapid/src/utils/constant.dart';
import 'package:path/path.dart' as p;
import 'package:rapid/src/utils/mimetypes.dart';

import 'context/context.dart';
import 'response_writer/writer.dart';

class RapidRoutes {
  final String _basePath;

  String? _acceptedContentType;
  List<String> get _accepts => _acceptedContentType == null ? [] : [_acceptedContentType!];

  RapidRoutes([this._basePath = '']);

  final List<Route> _routes = [];
  final List<CtxHandler> _before = [];

  void group(String path) => RapidRoutes(path);
  void use(CtxHandler handler) => _before.add(handler);

  Route route(
    String path,
    String methods,
    CtxHandler handler, [
    List<CtxHandler> middlewares = const [],
  ]) {
    path = p.join(_basePath, path);
    var route = Route.extract(
      path: path,
      methods: methods,
      accepts: _accepts,
      handlers: [...middlewares, handler],
    );
    _routes.add(route);
    return route;
  }

  Route get(
    String path,
    CtxHandler handler, [
    List<CtxHandler> middlewares = const [],
  ]) =>
      route(path, 'GET', handler, middlewares);

  Route post(
    String path,
    CtxHandler handler, [
    List<CtxHandler> middlewares = const [],
  ]) =>
      route(path, 'POST', handler, middlewares);

  Route put(
    String path,
    CtxHandler handler, [
    List<CtxHandler> middlewares = const [],
  ]) =>
      route(path, 'PUT', handler, middlewares);

  Route patch(
    String path,
    CtxHandler handler, [
    List<CtxHandler> middlewares = const [],
  ]) =>
      route(path, 'PATCH', handler, middlewares);

  Route delete(
    String path,
    CtxHandler handler, [
    List<CtxHandler> middlewares = const [],
  ]) =>
      route(path, 'DELETE', handler, middlewares);

  RapidRoutes accept(String contentType) {
    _acceptedContentType = contentType;
    return this;
  }

  RapidRoutes get json {
    _acceptedContentType = MimeTypes.json;
    return this;
  }

  RapidRoutes get text {
    _acceptedContentType = MimeTypes.txt;
    return this;
  }

  RapidRoutes get form {
    _acceptedContentType = MimeTypes.urlEncodedForm;
    return this;
  }

  RapidRoutes get multiform {
    _acceptedContentType = MimeTypes.multipartForm;
    return this;
  }
}

class RapidApp extends RapidRoutes {
  RapidApp([super._basePath = '']);

  final _servers = <HttpServer>[];

  final List<CtxHandler> onDone = [];

  int maxHandlersMatched = 1;

  CtxHandler? on404Error;
  FutureOr Function(Context c, Object e, StackTrace stackTrace)? on500Error;
  CtxHandler? log = (ctx) {
    print("[${DateTime.now().toIso8601String()}] "
        "${ctx.req.response.headers.contentType?.mimeType} ${ctx.req.method} ${ctx.req.uri} ->"
        " ${ctx.req.response.statusCode}");
  };

  void app(RapidRoutes app) {
    final path = app._basePath;
    final routes = app._routes;

    final beforeRoutes = app._before.map((e) => e).toList();
    final r = route(path, 'ALL', beforeRoutes.first, beforeRoutes.skip(1).toList());

    _routes.add(r);
    _routes.addAll(routes);
  }

  Future<void> listen({
    String addr = '127.0.0.1',
    int port = 8080,
    int backlog = 0,
  }) async {
    final server = await HttpServer.bind(
      addr,
      port,
      shared: true,
      backlog: backlog,
    );
    _servers.add(server);
    server.listen(handleHttpRequest);
    print('HTTP Server listening on port http//$addr:$port');
  }

  Future<void> close() async {
    try {
      for (var server in _servers) {
        await server.close(force: true);
      }
    } catch (e) {
      //
    }
  }

  Future<void> handleHttpRequest(HttpRequest req) async {
    final matched = getMatched(_routes, req, maxHandlersMatched);
    final ctx = Context(req, matched);

    req.response.done.then((_) async {
      ctx.isHttpEventDone = true;
      for (var listener in onDone) {
        try {
          await listener(ctx);
        } catch (e, s) {
          print(e);
          print(s);
        }
      }
      if (log != null) {
        try {
          await log!(ctx);
        } catch (e, s) {
          print(e);
          print(s);
        }
      }
    });
    try {
      if (matched.isEmpty) {
        await _respond404(ctx);
      } else {
        final ResponseBodyWriter? response = await ctx.next;
        await _handleWriteResponse(response, ctx);
      }
    } on ResponseBodyWriter catch (e) {
      await _handleWriteResponse(e, ctx);
    } catch (e, s) {
      await _respond500(ctx, e, s);
      print(e);
      print(s);
    }
  }

  Future<void> _handleWriteResponse(ResponseBodyWriter? response, Context c) async {
    if (c.isHttpEventDone) return;
    if (response == null) {
      c.req.response.statusCode = 200;
      await c.req.response.close();
      return;
    }

    await response.write(c.req);
    await c.req.response.close();
  }

  Future<void> _respond404(Context c) async {
    if (on404Error != null) {
      final ResponseBodyWriter? response = await on404Error!(c);
      await _handleWriteResponse(response, c);
    } else {
      c.req.response.statusCode = 404;
      c.req.response.write('404 not found');
      await c.req.response.close();
    }
  }

  Future<void> _respond500(Context c, Object e, StackTrace stackTrace) async {
    if (on500Error != null) {
      final ResponseBodyWriter? response = await on500Error!(c, e, stackTrace);
      await _handleWriteResponse(response, c);
    } else {
      c.req.response.statusCode = 500;
      c.req.response.write('500 server error');
      await c.req.response.close();
    }
  }
}
