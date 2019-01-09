// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_ui_viewsv1/fidl_async.dart';

import '../child_view_connection.dart';

/// A singleton class that allows receive events from the view container.
class ViewContainerListenerImpl extends ViewContainerListener {
  /// The shared [ViewContainerListenerImpl] instance.
  static final ViewContainerListenerImpl instance =
      new ViewContainerListenerImpl._();

  ViewContainerListenerImpl._() : super();

  static final Map<int, ChildViewConnection> _connections =
      HashMap<int, ChildViewConnection>();

  final ViewContainerListenerBinding _binding = ViewContainerListenerBinding();

  /// adds a [ChildViewConnection] for a given [key]
  void addConnectionForKey(int key, ChildViewConnection connection) {
    _connections[key] = connection;
  }

  /// returns true if a given [key] was previously added via
  /// [addConnectionForKey]
  bool containsConnectionForKey(int key) {
    return _connections.containsKey(key);
  }

  /// Returns an interface handle whose peer is bound to the this object.
  InterfaceHandle<ViewContainerListener> createInterfaceHandle() {
    return _binding.wrap(this);
  }

  /// returns [ChildViewConnection] for given [key]
  ChildViewConnection getConnectionForKey(int key) {
    return _connections[key];
  }

  @override
  Future<Null> onChildAttached(int childKey, ViewInfo childViewInfo) async {
    ChildViewConnection connection = _connections[childKey];
    connection?.onAttachedToContainer(childViewInfo);
  }

  @override
  Future<Null> onChildUnavailable(int childKey) async {
    ChildViewConnection connection = _connections[childKey];
    connection?.onUnavailable();
  }

  /// remove a [ChildViewConnection] for a given [key]
  ChildViewConnection removeConnectionForKey(int key) {
    return _connections.remove(key);
  }
}