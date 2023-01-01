part of './route.dart';

class MatchedRoute {
  final Route route;
  final Map<String, String?> params;
  const MatchedRoute(this.route, this.params);

  int get handlersLen => route.handlers.length;
}

List<MatchedRoute> getMatched(List<Route> routes, HttpRequest req, int maxHandlersMatched) {
  final handlers = <MatchedRoute>[];
  for (var handler in routes) {
    if (!handler.methods.contains(req.method) && !handler.methods.contains('ALL')) continue;
    var matchAndParse = handler.matchAndParse(req.uri.path, req.method, req.headers.contentType);
    if (matchAndParse != null) {
      handlers.add(MatchedRoute(handler, matchAndParse));
    }
    if (maxHandlersMatched != -1 && handlers.length >= maxHandlersMatched) break;
  }
  return handlers;
}
