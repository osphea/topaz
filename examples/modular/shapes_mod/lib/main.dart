// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:modular/module.dart';

void main() {
  Module().registerIntentHandler(ShapesIntentHandler());
}

class ShapesIntentHandler extends IntentHandler {
  @override
  void handleIntent(Intent intent) {}
}