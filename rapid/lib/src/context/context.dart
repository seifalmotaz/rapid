library rapid.context;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:rapid/src/response_writer/writer.dart';
import 'package:rapid/src/route/route.dart';
import 'package:rapid/src/utils/mimetypes.dart';
import 'package:rapid/src/utils/string_extention.dart';

import 'form_data.dart';

part './store.dart';

const cachedBodyKey = '_cachedBody';
const cachedHeadersKey = '_headers_map';

class Context {
  final HttpRequest req;
  Context(this.req, List<MatchedRoute> matchedRoutes) {
    _matchedRoutes = matchedRoutes;
    if (matchedRoutes.isNotEmpty) {
      notFound = false;
      _currentWorkingRoute = matchedRoutes[0];
    } else {
      notFound = true;
    }
  }

  // helpers
  final store = RequestStore();

  /// to track the close of the response
  bool isHttpEventDone = false;

  // matched routes handler
  int _indexRoute = 0;
  int _indexHandler = -1;
  late final bool notFound;
  late MatchedRoute _currentWorkingRoute;
  late final List<MatchedRoute> _matchedRoutes;

  bool get nextExist {
    final bool = _indexRoute + 1 >= _matchedRoutes.length;
    final bool2 = _indexHandler + 1 >= _currentWorkingRoute.handlersLen; // the one for main handler
    if (bool && bool2) return false;
    return true;
  }

  Future<ResponseBodyWriter?> get next {
    if (notFound || isHttpEventDone) return Future.value();
    if ((_indexHandler + 1) == _currentWorkingRoute.handlersLen) {
      _indexRoute++;
      _indexHandler = -1;
      if ((_indexRoute) == _matchedRoutes.length) {
        return Future.value();
      }
      _currentWorkingRoute = _matchedRoutes[_indexRoute];
    }
    _indexHandler++;
    return _currentWorkingRoute.route(this, _indexHandler);
  }

  // params manipulator
  Map<String, String?> get _params => _currentWorkingRoute.params;
  T? param<T>(String i) {
    final p = _params[i];
    if (p == null) return null;
    if (p.isEmpty) return null;
    if (T == String) return p as T;
    return p.cast<T>();
  }

  // uri manipulator
  String get hostname => req.uri.host;
  String? get ip => req.connectionInfo?.remoteAddress.address;
  //
  ContentType? get contentType => req.headers.contentType;

  // query params manipulator
  late final Map<String, List<String>> _query;
  T? query<T>(String i) {
    if (_query[i] == null) return null;
    if (T is List) return _query[i] as T;
    if (_query[i]!.isEmpty) return null;
    if (T is String) return _query[i]!.first as T;
    return _query[i]!.first.cast<T>();
  }

  // header manipulator
  Map<String, List<String>> get headersMap {
    final Map<String, List<String>>? headersMap = store.tryGet(cachedHeadersKey);
    if (headersMap != null) return headersMap;
    final h = <String, List<String>>{};
    req.headers.forEach((name, values) {
      h.addAll({name: values});
    });
    store.set(cachedHeadersKey, h);
    return h;
  }

  /// returning list or map from request json body
  Future get body async {
    final cachedBody = store.tryGet(cachedBodyKey);
    if (cachedBody == null) {
      String string = await utf8.decodeStream(req);
      var body = string.isEmpty ? {} : jsonDecode(string);
      store.set(cachedBodyKey, body);
      return body;
    }
    return cachedBody;
  }

  Future<Uint8List> get bodyBytes async {
    BytesBuilder bytesBuilder = await req.fold<BytesBuilder>(BytesBuilder(copy: false), (a, b) => a..add(b));
    return bytesBuilder.takeBytes();
  }

  /// covert the form data to [BodyForm] class that contains the fields and the files if exist
  Future<BodyForm> get form async {
    final cachedBody = store.tryGet(cachedBodyKey);
    if (cachedBody != null) return cachedBody;
    if (contentType?.mimeType == MimeTypes.urlEncodedForm) {
      return await _form();
    } else if (contentType?.mimeType == MimeTypes.multipartForm) {
      return await _multipartForm();
    }
    throw JsonResponse({
      "msg": "cannot decode the body of the request",
      "details": "${contentType?.mimeType} is not "
          "subtype of `url-encoded-form` or `multipart/form`"
    }, 415);
  }

  Future<BodyForm> _form() async {
    var bytes = await bodyBytes;
    Map<String, List<String>> value = String.fromCharCodes(bytes).splitQuery();
    return BodyForm(value, {});
  }

  Future<BodyForm> _multipartForm() async {
    final Map<String, List<String>> formFields = {};
    final Map<String, List<FilePart>> formFiles = {};

    final contentType = req.headers.contentType!;
    if (contentType.parameters['boundary'] == null) {
      throw JsonResponse('Missing `boundary` field in headers', 400);
    }

    Stream<MimeMultipart> parts = MimeMultipartTransformer(contentType.parameters['boundary']!).bind(req);

    await for (var part in parts) {
      Map<String, String?> parameters;
      {
        final String contentDisposition = part.headers['content-disposition']!;
        parameters = ContentType.parse(contentDisposition).parameters;
      }

      /// get the name of form field
      String? name = parameters['name'];

      if (name == null) {
        throw JsonResponse('Cannot find the header name field for the request content', 400);
      }

      /// check if this part is field or file
      if (!parameters.containsKey('filename')) {
        if (formFields.containsKey(name)) {
          formFields[name]!.add(await utf8.decodeStream(part));
        } else {
          formFields[name] = [await utf8.decodeStream(part)];
        }
        continue;
      }

      /// ================ handle if it's file =====================
      String? filename = parameters['filename'];
      if (filename == null) {
        throw JsonResponse('Cannot find the header name field for the request', 400);
      }

      /// add the file to formFiles as stream
      if (formFiles.containsKey(name)) {
        formFiles[name]!.add(FilePart(name, filename, part));
      } else {
        formFiles[name] = [FilePart(name, filename, part)];
      }
    }
    return BodyForm(formFields, formFiles);
  }
}
