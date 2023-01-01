import 'package:dio/dio.dart';
import 'package:rapid/rapid.dart';
import 'package:test/test.dart';

void main() {
  const port = 4040;
  group('General testing', () {
    late final RapidApp app;
    setUpAll(() async {
      app = RapidApp();
      app.log = null;
      app.json.get('/json', (ctx) => {'message': 'Hello World'});
      app.json.get('/{name:string}', (ctx) {
        String p = ctx.param('name')!;
        return p;
      });
      app.multiform.post('/form/basic', (c) async {
        var body = await c.form;
        return body['name'];
      });

      await app.listen(port: port);
    });

    tearDownAll(() async {
      await app.close();
    });

    test('> Json response', () async {
      final dio = Dio();
      final res = await dio.get('http://localhost:$port/json');
      final data = res.data as Map<String, dynamic>;
      expect(data.containsKey('message'), isTrue);
      expect(data['message'] == 'Hello World', isTrue);
    });

    test('> Parameter parsing in url', () async {
      final dio = Dio();
      final res = await dio.get('http://localhost:$port/Seif');
      expect(res.data == 'Seif', isTrue);
    });

    test('> Form route with one field', () async {
      final dio = Dio();
      final res = await dio.post('http://localhost:$port/form/basic', data: FormData.fromMap({'name': 'Seif'}));
      final data = res.data as List;
      expect(data.first == 'Seif', isTrue);
    });
  });

  group('URL parameters testing', () {
    late final RapidApp app;
    setUpAll(() async {
      app = RapidApp();
      app.log = null;
      app.json.get('/{age:int}', (ctx) {
        int p = ctx.param('age')!;
        return p.toString();
      });
      app.json.get('/{name}', (ctx) {
        String p = ctx.param('name')!;
        return p;
      });
      app.json.get('/{percentage:double}', (ctx) {
        double p = ctx.param('percentage')!;
        return p;
      });
      app.json.get('/test/{first}-{sec}', (ctx) {
        String first = ctx.param('first')!;
        String sec = ctx.param('sec')!;
        return '$first $sec';
      });
      app.json.get('/{first}/{sec}', (ctx) {
        String first = ctx.param('first')!;
        String sec = ctx.param('sec')!;
        return '$first $sec';
      });
      await app.listen(port: port);
    });

    tearDownAll(() async {
      await app.close();
    });

    test('> `int` test', () async {
      final dio = Dio();
      final res = await dio.get('http://localhost:$port/1');
      expect(res.data == '1', isTrue);
    });

    test('> `string` (default) test', () async {
      final dio = Dio();
      final res = await dio.get('http://localhost:$port/string');
      expect(res.data == 'string', isTrue);
    });

    test('> `double` test', () async {
      final dio = Dio();
      final res = await dio.get('http://localhost:$port/1.0');
      expect(res.data == '1.0', isTrue);
    });

    test('> 2 parameters testing', () async {
      final dio = Dio();
      final res = await dio.get('http://localhost:$port/Seif/Almotaz');
      expect(res.data == 'Seif Almotaz', isTrue);
    });

    test('> 2 parameters in same segmant testing', () async {
      final dio = Dio();
      final res = await dio.get('http://localhost:$port/test/Seif-Almotaz');
      expect(res.data == 'Seif Almotaz', isTrue);
    });
  });
}
