final RegExp parmRegExp = RegExp(r"{(\w+)\:?(\w+)?}", caseSensitive: false);

// create an class with for extractPathPattern function result
class PathPattern {
  final RegExp regExp;
  final List<String> paramNames;
  final bool usesWildcardMatcher;

  PathPattern(this.regExp, this.paramNames, this.usesWildcardMatcher);
}

/// {`pattern (regexp)`, `param names`, `usesWildcardMatcher bool`}
PathPattern extractPathPattern(String path) {
  List<String> segments = Uri.tryParse(path)?.pathSegments ?? [path];

  final List<String> paramNames = [];
  bool usesWildcardMatcher = false;

  var pattern = '^';
  for (var segment in segments) {
    if (segment == '*' && segment != segments.first && segment == segments.last) {
      pattern += r'(?:/.*|)';
      usesWildcardMatcher = true;
      break;
    }

    pattern += '/?';

    String regexPath = segment.replaceAllMapped(parmRegExp, (match) {
      String regex = '';

      String paramName = match[1]!;
      String? type = match[2];

      switch (type) {
        case 'int':
          regex += r"[0-9]+";
          break;
        case 'double':
          regex += r"[0-9]*\.[0-9]+";
          break;
        case 'num':
          regex += r"[0-9]*(\.[0-9]+)?";
          break;
        case 'any':
          regex += r"[^\\/]+";
          break;
        case 'path':
          regex += r"\/.*|";
          usesWildcardMatcher = true;
          break;
        default:
          regex += r"[a-zA-Z0-9_\-\.]+";
      }

      if (type?.endsWith('?') ?? false || paramName.endsWith('?')) {
        regex += '?';
        if (segment[match.start - 1] == '/') {
          regex = '?$regex';
        }
      }

      paramNames.add(paramName);
      return r'(?<' + paramName + r'>' + regex + r')';
    });

    pattern += regexPath;
  }
  if (pattern.endsWith('/')) {
    pattern += '?';
  } else if (!usesWildcardMatcher) {
    pattern += '/?';
  }

  pattern += r'$';
  var matcher = RegExp(pattern, caseSensitive: false);
  return PathPattern(matcher, paramNames, usesWildcardMatcher);
}
