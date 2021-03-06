// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:fuchsia_scenic_flutter/child_view.dart' show ChildView;
import 'package:fuchsia_scenic_flutter/child_view_connection.dart'
    show ChildViewConnection;
import 'package:tiler/tiler.dart';

import '../tile_model/module_info.dart';
import '../tile_model/tile_model_serializer.dart';
import 'widgets/drop_target_widget.dart';
import 'widgets/editing_tile_chrome.dart';

const _kSizerThickness = 48.0;
const _kSizerHandleThickness = 8.0;
const _kSizerHandleLength = 32.0;

/// Tiling layout Layout presenter widget.
@immutable
class LayoutPresenter extends StatelessWidget {
  /// The model being rendered.
  final TilerModel tilerModel;

  /// Whether edit mode is on or not.
  final bool isEditing;

  /// Maps a surface id to the view.
  final BuiltMap<String, ChildViewConnection> connections;

  /// Maps a parameter id to a color.
  final Map<String, Color> parametersToColors;

  /// Currently focused mod.
  final ValueNotifier<String> focusedMod;

  /// Called when tiler model should be set to model.
  ///
  /// This should be implemented by the story_widget.
  final void Function(TilerModel model) setTilerModel;

  /// Constructor for a tiling layout presenter.
  const LayoutPresenter({
    @required this.tilerModel,
    @required this.isEditing,
    @required this.connections,
    @required this.parametersToColors,
    @required this.focusedMod,
    @required this.setTilerModel,
  });

  @override
  Widget build(BuildContext context) {
    final tiler = Tiler(
      model: tilerModel,
      sizerThickness: isEditing ? _kSizerThickness : 0,
      sizerBuilder: isEditing ? _sizerBuilder : null,
      chromeBuilder: _buildChrome,
    );

    if (!isEditing) {
      return tiler;
    }

    return AnimatedBuilder(
      animation: tilerModel,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _addTarget(tileAfter: _getRoot, axis: Axis.horizontal),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _addTarget(tileAfter: _getRoot, axis: Axis.vertical),
                  child,
                  _addTarget(tileBefore: _getRoot, axis: Axis.vertical),
                ],
              ),
            ),
            _addTarget(tileBefore: _getRoot, axis: Axis.horizontal),
          ],
        );
      },
      child: Expanded(child: tiler),
    );
  }

  TileModel _getRoot() => tilerModel.root;

  Widget _sizerBuilder(
    BuildContext context,
    Axis axis,
    TileModel tileBefore,
    TileModel tileAfter,
  ) =>
      Stack(
        children: <Widget>[
          Container(
            color: Colors.transparent,
            // TODO(ahetzroni): wrap in AnimatedSize when variably sized sizers becomes available and adding drop targets
            child: SizedBox(
              width: axis == Axis.horizontal ? null : _kSizerThickness,
              height: axis == Axis.vertical ? null : _kSizerThickness,
              child: Center(
                child: Container(
                  width: axis == Axis.horizontal
                      ? _kSizerHandleLength
                      : _kSizerHandleThickness,
                  height: axis == Axis.vertical
                      ? _kSizerHandleLength
                      : _kSizerHandleThickness,
                  decoration: const BoxDecoration(color: Colors.black),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: _addTarget(
              tileBefore: () => tileBefore,
              tileAfter: () => tileAfter,
              axis: axis,
            ),
          ),
        ],
      );

  Widget _buildChrome(BuildContext context, TileModel tile) {
    ModuleInfo content = tile.content;
    final modName = content.modName;
    final connection = connections[modName];

    if (!isEditing) {
      return ChildView(connection: connection);
    }

    TilerModel tilerModelForCancel;

    return LayoutBuilder(
        builder: (context, constraints) => EditingTileChrome(
              focusedMod: focusedMod,
              parameterColors:
                  content.parameters.map((p) => parametersToColors[p]),
              tilerModel: tilerModel,
              tile: tile,
              modName: modName,
              childView: ChildView(
                focusable: false,
                hitTestable: false,
                connection: connection,
              ),
              editingSize: constraints.biggest,
              willStartDrag: () {
                tilerModelForCancel = cloneTiler(tilerModel);
              },
              didCancelDrag: () {
                setTilerModel(tilerModelForCancel);
              },
            ));
  }

  Widget _addTarget({
    TileModel Function() tileBefore,
    TileModel Function() tileAfter,
    Axis axis,
  }) =>
      DropTargetWidget(
        onAccept: (tile) {
          tilerModel
            ..remove(tile)
            ..add(
              content: tile.content,
              nearTile: (tileBefore ?? tileAfter)(),
              direction: tileBefore != null
                  ? (axis == Axis.horizontal
                      ? AxisDirection.down
                      : AxisDirection.right)
                  : (axis == Axis.horizontal
                      ? AxisDirection.up
                      : AxisDirection.left),
            );
        },
        onWillAccept: (tile) =>
            tile != tileBefore?.call() && tile != tileAfter?.call(),
        axis: axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
        baseSize: _kSizerThickness,
        hoverSize: _kSizerThickness,
      );
}
