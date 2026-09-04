import 'app/bootstrap.dart';
import 'app/bunyan_app.dart';

Future<void> main() async {
  await bootstrap(() => const BunyanApp());
}
