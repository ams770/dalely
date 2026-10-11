import 'package:flutter/material.dart';

import 'app/bootstrap.dart';
import 'app/feen_app.dart';

void main() async {
  final dependencies = await bootstrap();
  runApp(DalelyApp(dependencies: dependencies));
}
