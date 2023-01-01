import 'package:test/test.dart';
import 'package:rapid/src/helpers/pattern_extractor.dart';

void main() {
  test('Test one', () {
    final p = extractPathPattern('/{firstName}/{secondName}');
    expect(p.regExp.pattern, r'^/?(?<firstName>[a-zA-Z0-9_\-\.]+)/?(?<secondName>[a-zA-Z0-9_\-\.]+)/?$');
  });

  test('Test two', () {
    final p2 = extractPathPattern('/{firstName}-{secondName}');
    expect(p2.regExp.pattern, r'^/?(?<firstName>[a-zA-Z0-9_\-\.]+)-(?<secondName>[a-zA-Z0-9_\-\.]+)/?$');
  });
}
