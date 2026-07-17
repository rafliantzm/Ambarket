import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HTML boot loader can be removed after Flutter fallback UI mounts', () {
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
    final index = File('web/index.html').readAsStringSync();

    expect(bootstrap, contains('flutter-first-frame'));
    expect(bootstrap, contains('ambarket-flutter-mounted'));
    expect(bootstrap, contains('removeBootLoader'));
    expect(bootstrap, contains('showBootError'));

    expect(index, contains('window.ambarketReload'));
    expect(index, contains('_ambarketReload'));
  });
}
