// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show ListBase;
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

/// Generic class for layout elements: provides the box coordinates of
/// viewport position and the element to place at that position.
abstract class LayoutElement<T> {
  /// Box layout for this Element
  final double x, y, w, h;

  /// The element positioned at this location
  final T element;

  /// Constructor
  LayoutElement({this.x, this.y, this.w, this.h, this.element});

  /// Override comparator so LayoutElements with the same values evaluate to
  /// equal.
  @override
  bool operator ==(dynamic other) =>
      other is LayoutElement &&
      x == other.x &&
      y == other.y &&
      w == other.w &&
      h == other.h &&
      element == other.element;

  /// get hashCode
  @override
  int get hashCode {
    return hash4(
        (w - x).hashCode, (h - y).hashCode, (x * y).hashCode, element.hashCode);
  }
}

/// Class for returning a layer of the Layout.
/// Each [Layer] contains all the [LayoutElement]s in that Layer.
/// LayoutElements are not required to fully tile the area.
class Layer<LayoutElement> extends ListBase<LayoutElement> {
  final List<LayoutElement> _innerList = <LayoutElement>[];

  /// Constructor for adding a single element to a Layer
  Layer({LayoutElement element}) {
    if (element != null) {
      _innerList.add(element);
    }
  }

  /// Constructor for adding a list of [LayoutElement]s to a layer
  Layer.fromList({List<LayoutElement> elements}) {
    _innerList.addAll(elements);
  }

  @override
  int get length => _innerList.length;

  @override
  set length(int length) => _innerList.length = length;

  @override
  void operator []=(int index, LayoutElement value) {
    _innerList[index] = value;
  }

  @override
  LayoutElement operator [](int index) => _innerList[index];

  @override
  void add(LayoutElement value) => _innerList.add(value);

  @override
  void addAll(Iterable<LayoutElement> all) => _innerList.addAll(all);
}

/// Convenience class for placing a single Surface at a coordinate and size on
/// screen
class SurfaceLayout extends LayoutElement {
  /// Constructor
  SurfaceLayout({double x, double y, double w, double h, String surfaceId})
      : super(x: x, y: y, w: w, h: h, element: surfaceId);

  /// Export to JSON
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'surfaceId': element,
      };

  /// Decode from JSON
  SurfaceLayout.fromJson(Map<String, dynamic> json)
      : super(
            x: json['x'],
            y: json['y'],
            w: json['w'],
            h: json['h'],
            element: json['surfaceId']);

  @override
  String toString() {
    return toJson().toString();
  }

  /// Create a full size SurfaceLayout with this surfaceId for the given context
  SurfaceLayout.fullSize({LayoutContext layoutContext, String surfaceId})
      : super(
            x: 0,
            y: 0,
            w: layoutContext.size.width,
            h: layoutContext.size.height,
            element: surfaceId);
}

/// Convenience class for placing a Stack of [Surface] elements at a coordinate
/// and size on screen. The box dimensions of the [StackLayout] apply to each of
/// the surfaces in the [StackLayout] - they are all intended to fit the stack
/// dimensions.
class StackLayout extends LayoutElement {
  /// Constructor
  StackLayout(
      {double x, double y, double w, double h, List<String> surfaceStack})
      : super(x: x, y: y, w: w, h: h, element: surfaceStack);

  /// Export to JSON
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'surfaceStack': element,
      };

  /// Decode from JSON
  StackLayout.fromJson(Map<String, dynamic> json)
      : super(
            x: json['x'],
            y: json['y'],
            w: json['w'],
            h: json['h'],
            element: json['surfaceStack']);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// The context in which the CompositionDelegate determines layout
class LayoutContext {
  /// The size of the viewport the CompositionDelegate can use
  final Size size;

  /// The acceptable minimum width of a Surface in this context
  final double minSurfaceWidth;

  /// Constructor
  const LayoutContext({@required this.size, @required this.minSurfaceWidth});
}

/// Simple class for capturing 2D size of boxes in layout.
class Size {
  /// height
  final double height;

  /// width
  final double width;

  /// constructor
  const Size(this.width, this.height);

  /// convert to JSON
  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
      };
}

/// List of Layout Strategies implemented by the composition delegate
enum layoutStrategyType {
  /// The fallback layout strategy: stack surfaces.
  /// Logic in stack_strategy/stack_strategy.dart.
  stackStrategy,

  /// Split the space evenly.
  /// Logic in split_evenly_strategy/split_evenly_strategy.dart.
  splitEvenlyStrategy,

  /// The Mondrian layout logic. Uses co-presentation signals to lay out
  /// as many of the surfaces that want to co-present together as can fit,
  /// starting with the most focused surface.
  /// Logic in copresent_strategy/copresent_strategy.dart
  copresentStrategy,
}
