// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:lib.app.dart/logging.dart';
import 'package:xi_client/client.dart';

import 'document.dart';
import 'editor.dart';

/// Top-level Widget.
class XiApp extends StatefulWidget {
  /// The client API interface to the xi-core Fuchsia service.
  final CoreProxy coreProxy;

  /// If `true`, draws a watermark on the editor view.
  final bool drawDebugBackground;

  /// [XiApp] constructor.
  const XiApp({
    @required this.coreProxy,
    this.drawDebugBackground = false,
    Key key,
  })  : assert(coreProxy != null),
        super(key: key);

  @override
  XiAppState createState() => new XiAppState();
}

/// State for XiApp.
class XiAppState extends State<XiApp> implements XiHandler {
  final Document _document = new Document();

  XiAppState();

  @override
  void initState() {
    super.initState();
    widget.coreProxy.handler = this;
    widget.coreProxy.clientStarted().then((_) => widget.coreProxy
        .newView()
        .then((viewId) => setState(
            () => _document.finalizeViewProxy(widget.coreProxy.view(viewId)))));
  }

  @override
  void alert(String text) {
    log.warning('received alert: $text');
  }

  @override
  XiViewHandler getView(String viewId) => _document;

  @override
  List<List<double>> measureWidths(List<Map<String, dynamic>> args) {
    return _document.measureWidths(args);
  }

  /// Uses a [MaterialApp] as the root of the Xi UI hierarchy.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Xi',
      home: new Material(
        // required for the debug background to render correctly
        type: MaterialType.transparency,
        child: Container(
          constraints: new BoxConstraints.expand(),
          color: Colors.white,
          child: new Editor(
              document: _document, debugBackground: widget.drawDebugBackground),
        ),
      ),
    );
  }
}
