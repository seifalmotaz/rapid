import 'dart:convert';

extension StringCast on String {
  S? cast<S>() {
    if (S == int) return int.tryParse(this) as S?;
    if (S == double) return double.tryParse(this) as S?;
    if (S == num) return num.tryParse(this) as S?;
    if (S == bool) {
      return (this == 'true' || this == '1' ? true : false) as S?;
    }
    return null;
  }

  Map<String, List<String>> splitQuery({Encoding encoding = utf8}) {
    return split("&").fold({}, (map, element) {
      int index = element.indexOf("=");
      if (index == -1) {
        if (element != "") {
          var s = Uri.decodeQueryComponent(element, encoding: encoding);
          if (!map.containsKey(s)) {
            map[s] = [];
          }
        }
      } else if (index != 0) {
        var key = element.substring(0, index);
        var value = element.substring(index + 1);
        var k = Uri.decodeQueryComponent(key, encoding: encoding);
        var v = Uri.decodeQueryComponent(value, encoding: encoding);
        if (map.containsKey(k)) {
          map[k]!.add(v);
        } else {
          map[k] = [v];
        }
      }
      return map;
    });
  }
}
