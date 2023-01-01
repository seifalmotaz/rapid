import 'package:rapid/rapid.dart';

void main() {
  final app = RapidApp();
  app.json.get('/json', (ctx) => {'message': 'Hello World'});
  app.json.get('/{name:string}', (ctx) {
    String p = ctx.param('name')!;
    return p;
  });
  app.form.post('/form/basic', (c) async {
    var body = await c.form;
    return body['name'];
  });
  app.listen(port: 4400);
}
