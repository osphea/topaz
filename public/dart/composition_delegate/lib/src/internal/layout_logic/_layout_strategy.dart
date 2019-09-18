// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show LinkedHashSet;

import 'package:composition_delegate/src/layout/layout_types.dart';
import 'package:composition_delegate/src/internal/tree/_surface_tree.dart';

export 'dart:collection' show LinkedHashSet;
export 'package:composition_delegate/src/layout/layout_types.dart';
export 'package:composition_delegate/src/surface/surface.dart';
export 'package:composition_delegate/src/internal/tree/_surface_tree.dart';

/// Abstract class for defining the LayoutStrategy interface. Custom layout
/// implementations and experiments can extend LayoutStrategy and override
/// getLayout() and isStale(). The shape of the surface graph and the
/// inter-surface relationships are not affected by Layout Strategy: a goal
/// is to be able to do runtime hot-swapping of Strategies to compare efficacy
/// for the same collection of surfaces and relationships.

/// ignore: one_member_abstracts
abstract class LayoutStrategy {
  /// return the layout of the story for the given state. [focusedSurfaces] is
  /// set of Surfaces in the Story, in order in which they have most recently
  /// been focused. [hiddenSurfaces] is the set of Surfaces that e.g. through
  /// UI manipulation have been 'hidden', but not removed from the Surface.
  /// The [layoutContext] describes the context of the layout: e.g. the size of
  /// the view port assigned to this Story. [previousLayout] is the previous
  /// layout of the Story: it was not necessarily generated by this strategy. It
  /// is provided in case Strategies want to adopt principles like being as
  /// stationary as possible with layout. The [surfaceTree] is the description
  /// of the relationships between Surfaces in the story.
  ///
  /// Strategies take this metadata and determine based on focus, relationships,
  /// hidden surfaces etc, what the current layout should be. The returned
  /// layout is a list of [Layer]s, comprised of a collection of positioned
  /// elements that implement [LayoutElement].
  List<Layer> getLayout({
    LinkedHashSet<String> focusedSurfaces,
    Set<String> hiddenSurfaces,
    LayoutContext layoutContext,
    List<Layer> previousLayout,
    SurfaceTree surfaceTree,
  });
}
