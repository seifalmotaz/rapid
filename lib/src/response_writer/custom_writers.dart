part of './writer.dart';

class TextResponse extends ResponseBodyWriter {
  TextResponse(super.body, [super.status]) : assert(body is String);

  @override
  Future<void> write(HttpRequest req) async {
    req.response.statusCode = status;
    req.response.headers.contentType = ContentType.text;
    req.response.write(body);
  }
}

class JsonResponse extends ResponseBodyWriter {
  JsonResponse(super.body, [super.status]) : assert(body is Map || body is List);

  @override
  Future<void> write(HttpRequest req) async {
    req.response.statusCode = status;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(body));
  }
}

class CustomResponse extends ResponseBodyWriter {
  CustomResponse(super.body, [super.status]) : assert(body is FutureOr Function(HttpRequest req));

  @override
  Future<void> write(HttpRequest req) async {
    req.response.statusCode = status;
    body as FutureOr Function(HttpRequest req);
    await body(req);
  }
}
