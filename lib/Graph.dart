import 'dart:collection';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:collection/collection.dart' show IterableExtension;

const double ARROW_DEGREES = 0.5;
const double ARROW_LENGTH = 10;

class ArrowEdgeRenderer extends EdgeRenderer {
  var trianglePath = Path();

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    var trianglePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    graph.edges.forEach((edge) {
      var source = edge.source;
      var destination = edge.destination;

      var sourceOffset = source.position;

      var x1 = sourceOffset.dx;
      var y1 = sourceOffset.dy;

      var destinationOffset = destination.position;

      var x2 = destinationOffset.dx;
      var y2 = destinationOffset.dy;

      var startX = x1 + source.width / 2;
      var startY = y1 + source.height / 2;
      var stopX = x2 + destination.width / 2;
      var stopY = y2 + destination.height / 2;

      var clippedLine = clipLine(startX, startY, stopX, stopY, destination);

      Paint? edgeTrianglePaint;
      if (edge.paint != null) {
        edgeTrianglePaint = Paint()
          ..color = edge.paint?.color ?? paint.color
          ..style = PaintingStyle.fill;
      }

      var triangleCentroid = drawTriangle(
          canvas, edgeTrianglePaint ?? trianglePaint, clippedLine[0], clippedLine[1], clippedLine[2], clippedLine[3]);

      canvas.drawLine(Offset(clippedLine[0], clippedLine[1]), Offset(triangleCentroid[0], triangleCentroid[1]),
          edge.paint ?? paint);
    });
  }

  List<double> drawTriangle(Canvas canvas, Paint paint, double x1, double y1, double x2, double y2) {
    var angle = (atan2(y2 - y1, x2 - x1) + pi);
    var x3 = (x2 + ARROW_LENGTH * cos((angle - ARROW_DEGREES)));
    var y3 = (y2 + ARROW_LENGTH * sin((angle - ARROW_DEGREES)));
    var x4 = (x2 + ARROW_LENGTH * cos((angle + ARROW_DEGREES)));
    var y4 = (y2 + ARROW_LENGTH * sin((angle + ARROW_DEGREES)));
    trianglePath.moveTo(x2, y2); // Top;
    trianglePath.lineTo(x3, y3); // Bottom left
    trianglePath.lineTo(x4, y4); // Bottom right
    trianglePath.close();
    canvas.drawPath(trianglePath, paint);

    // calculate centroid of the triangle
    var x = (x2 + x3 + x4) / 3;
    var y = (y2 + y3 + y4) / 3;
    var triangleCentroid = [x, y];
    trianglePath.reset();
    return triangleCentroid;
  }

  List<double> clipLine(double startX, double startY, double stopX, double stopY, Node destination) {
    var resultLine = List.filled(4, 0.0);
    resultLine[0] = startX;
    resultLine[1] = startY;

    var slope = (startY - stopY) / (startX - stopX);
    var halfHeight = destination.height / 2;
    var halfWidth = destination.width / 2;
    var halfSlopeWidth = slope * halfWidth;
    var halfSlopeHeight = halfHeight / slope;

    if (-halfHeight <= halfSlopeWidth && halfSlopeWidth <= halfHeight) {
      // line intersects with ...
      if (destination.x > startX) {
        // left edge
        resultLine[2] = stopX - halfWidth;
        resultLine[3] = stopY - halfSlopeWidth;
      } else if (destination.x < startX) {
        // right edge
        resultLine[2] = stopX + halfWidth;
        resultLine[3] = stopY + halfSlopeWidth;
      }
    }

    if (-halfWidth <= halfSlopeHeight && halfSlopeHeight <= halfWidth) {
      // line intersects with ...
      if (destination.y < startY) {
        // bottom edge
        resultLine[2] = stopX + halfSlopeHeight;
        resultLine[3] = stopY + halfHeight;
      } else if (destination.y > startY) {
        // top edge
        resultLine[2] = stopX - halfSlopeHeight;
        resultLine[3] = stopY - halfHeight;
      }
    }

    return resultLine;
  }
}


const int DEFAULT_ITERATIONS = 1000;
const double REPULSION_RATE = 0.5;
const double REPULSION_PERCENTAGE = 0.4;
const double ATTRACTION_RATE = 0.15;
const double ATTRACTION_PERCENTAGE = 0.15;
const int CLUSTER_PADDING = 15;
const double EPSILON = 0.0001;

class FruchtermanReingoldAlgorithm implements Algorithm {
  Map<Node, Offset> displacement = {};
  Random rand = Random();
  double graphHeight = 500; //default value, change ahead of time
  double graphWidth = 500;
  late double tick;

  int iterations = DEFAULT_ITERATIONS;
  double repulsionRate = REPULSION_RATE;
  double attractionRate = ATTRACTION_RATE;
  double repulsionPercentage = REPULSION_PERCENTAGE;
  double attractionPercentage = ATTRACTION_PERCENTAGE;

  @override
  EdgeRenderer? renderer;

  FruchtermanReingoldAlgorithm(
      {this.iterations = DEFAULT_ITERATIONS,
      this.renderer,
      this.repulsionRate = REPULSION_RATE,
      this.attractionRate = ATTRACTION_RATE,
      this.repulsionPercentage = REPULSION_PERCENTAGE,
      this.attractionPercentage = ATTRACTION_PERCENTAGE}) {
    renderer = renderer ?? ArrowEdgeRenderer();
  }

  @override
  void init(Graph? graph) {
    graph!.nodes.forEach((node) {
      displacement[node] = Offset.zero;
      node.position = Offset(rand.nextDouble() * graphWidth, rand.nextDouble() * graphHeight);
    });
  }

  @override
  void step(Graph? graph) {
    displacement = {};
    graph!.nodes.forEach((node) {
      displacement[node] = Offset.zero;
    });
    calculateRepulsion(graph.nodes);
    calculateAttraction(graph.edges);
    moveNodes(graph);
  }

  void moveNodes(Graph graph) {
    graph.nodes.forEach((node) {
      var newPosition = node.position += displacement[node]!;
      double newDX = min(graphWidth - 40, max(0, newPosition.dx));
      double newDY = min(graphHeight - 40, max(0, newPosition.dy));

      // double newDX = newPosition.dx;
      // double newDY = newPosition.dy;
      node.position = Offset(newDX, newDY);
    });
  }

  void cool(int currentIteration) {
    tick *= 1.0 - currentIteration / iterations;
  }

  void limitMaximumDisplacement(List<Node> nodes) {
    nodes.forEach((node) {
      if (node != focusedNode) {
        var dispLength = max(EPSILON, displacement[node]!.distance);
        node.position += displacement[node]! / dispLength * min(dispLength, tick);
      } else {
        displacement[node] = Offset.zero;
      }
    });
  }

  void calculateAttraction(List<Edge> edges) {
    edges.forEach((edge) {
      var source = edge.source;
      var destination = edge.destination;
      var delta = source.position - destination.position;
      var deltaDistance = max(EPSILON, delta.distance);
      var maxAttractionDistance = min(graphWidth * attractionPercentage, graphHeight * attractionPercentage);
      var attractionForce = min(0, (maxAttractionDistance - deltaDistance)).abs() / (maxAttractionDistance * 2);
      var attractionVector = delta * attractionForce * attractionRate;

      displacement[source] = displacement[source]! - attractionVector;
      displacement[destination] = displacement[destination]! + attractionVector;
    });
  }

  void calculateRepulsion(List<Node> nodes) {
    nodes.forEach((nodeA) {
      nodes.forEach((nodeB) {
        if (nodeA != nodeB) {
          var delta = nodeA.position - nodeB.position;
          var deltaDistance = max(EPSILON, delta.distance); //protect for 0
          var maxRepulsionDistance = min(graphWidth * repulsionPercentage, graphHeight * repulsionPercentage);
          var repulsionForce = max(0, maxRepulsionDistance - deltaDistance) / maxRepulsionDistance; //value between 0-1
          var repulsionVector = delta * repulsionForce * repulsionRate;

          displacement[nodeA] = displacement[nodeA]! + repulsionVector;
        }
      });
    });

    nodes.forEach((nodeA) {
      displacement[nodeA] = displacement[nodeA]! / nodes.length.toDouble();
    });
  }

  var focusedNode;

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    var size = findBiggestSize(graph!) * graph.nodeCount();
    graphWidth = size;
    graphHeight = size;

    var nodes = graph.nodes;
    var edges = graph.edges;

    tick = 0.1 * sqrt(graphWidth / 2 * graphHeight / 2);

    init(graph);

    for (var i = 0; i < iterations; i++) {
      calculateRepulsion(nodes);
      calculateAttraction(edges);
      limitMaximumDisplacement(nodes);

      cool(i);

      if (done()) {
        break;
      }
    }

    if (focusedNode == null) {
      positionNodes(graph);
    }

    shiftCoordinates(graph, shiftX, shiftY);

    return calculateGraphSize(graph);
  }

  void shiftCoordinates(Graph graph, double shiftX, double shiftY) {
    graph.nodes.forEach((node) {
      node.position = Offset(node.x + shiftX, node.y + shiftY);
    });
  }

  void positionNodes(Graph graph) {
    var offset = getOffset(graph);
    var x = offset.dx;
    var y = offset.dy;
    var nodesVisited = <Node>[];
    var nodeClusters = <NodeCluster>[];
    graph.nodes.forEach((node) {
      node.position = Offset(node.x - x, node.y - y);
    });

    graph.nodes.forEach((node) {
      if (!nodesVisited.contains(node)) {
        nodesVisited.add(node);
        var cluster = findClusterOf(nodeClusters, node);
        if (cluster == null) {
          cluster = NodeCluster();
          cluster.add(node);
          nodeClusters.add(cluster);
        }

        followEdges(graph, cluster, node, nodesVisited);
      }
    });

    positionCluster(nodeClusters);
  }

  void positionCluster(List<NodeCluster> nodeClusters) {
    combineSingleNodeCluster(nodeClusters);

    var cluster = nodeClusters[0];
    // move first cluster to 0,0
    cluster.offset(-cluster.rect!.left, -cluster.rect!.top);

    for (var i = 1; i < nodeClusters.length; i++) {
      var nextCluster = nodeClusters[i];
      var xDiff = nextCluster.rect!.left - cluster.rect!.right - CLUSTER_PADDING;
      var yDiff = nextCluster.rect!.top - cluster.rect!.top;
      nextCluster.offset(-xDiff, -yDiff);
      cluster = nextCluster;
    }
  }

  void combineSingleNodeCluster(List<NodeCluster> nodeClusters) {
    NodeCluster? firstSingleNodeCluster;

    nodeClusters.forEach((cluster) {
      if (cluster.size() == 1) {
        if (firstSingleNodeCluster == null) {
          firstSingleNodeCluster = cluster;
        } else {
          firstSingleNodeCluster!.concat(cluster);
        }
      }
    });

    nodeClusters.removeWhere((element) => element.size() == 1);
  }

  void followEdges(Graph graph, NodeCluster cluster, Node node, List nodesVisited) {
    graph.successorsOf(node).forEach((successor) {
      if (!nodesVisited.contains(successor)) {
        nodesVisited.add(successor);
        cluster.add(successor);

        followEdges(graph, cluster, successor, nodesVisited);
      }
    });

    graph.predecessorsOf(node).forEach((predecessor) {
      if (!nodesVisited.contains(predecessor)) {
        nodesVisited.add(predecessor);
        cluster.add(predecessor);

        followEdges(graph, cluster, predecessor, nodesVisited);
      }
    });
  }

  NodeCluster? findClusterOf(List<NodeCluster> clusters, Node node) {
    return clusters.firstWhereOrNull((element) => element.contains(node));
  }

  double findBiggestSize(Graph graph) {
    return graph.nodes.map((it) => max(it.height, it.width)).reduce(max);
  }

  Offset getOffset(Graph graph) {
    var offsetX = double.infinity;
    var offsetY = double.infinity;

    graph.nodes.forEach((node) {
      offsetX = min(offsetX, node.x);
      offsetY = min(offsetY, node.y);
    });

    return Offset(offsetX, offsetY);
  }

  bool done() {
    return tick < 1.0 / max(graphHeight, graphWidth);
  }

  void drawEdges(Canvas canvas, Graph graph, Paint linePaint) {}

  Size calculateGraphSize(Graph graph) {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;

    graph.nodes.forEach((node) {
      left = min(left, node.x);
      top = min(top, node.y);
      right = max(right, node.x + node.width);
      bottom = max(bottom, node.y + node.height);
    });

    return Size(right - left, bottom - top);
  }

  @override
  void setFocusedNode(Node node) {}

  @override
  void setDimensions(double width, double height) {
    graphWidth = width;
    graphHeight = height;
  }
}

class NodeCluster {
  List<Node>? nodes;

  Rect? rect;

  List<Node>? getNodes() {
    return nodes;
  }

  Rect? getRect() {
    return rect;
  }

  void setRect(Rect rect) {
    rect = rect;
  }

  void add(Node node) {
    nodes!.add(node);

    if (nodes!.length == 1) {
      rect = Rect.fromLTRB(node.x, node.y, node.x + node.width, node.y + node.height);
    } else {
      rect = Rect.fromLTRB(min(rect!.left, node.x), min(rect!.top, node.y), max(rect!.right, node.x + node.width),
          max(rect!.bottom, node.y + node.height));
    }
  }

  bool contains(Node node) {
    return nodes!.contains(node);
  }

  int size() {
    return nodes!.length;
  }

  void concat(NodeCluster cluster) {
    cluster.nodes!.forEach((node) {
      node.position = (Offset(rect!.right + CLUSTER_PADDING, rect!.top));
      add(node);
    });
  }

  void offset(double xDiff, double yDiff) {
    nodes!.forEach((node) {
      node.position = (node.position + Offset(xDiff, yDiff));
    });

    rect = rect!.translate(xDiff, yDiff);
  }

  NodeCluster() {
    nodes = [];
    rect = Rect.zero;
  }
}


abstract class EdgeRenderer {
  void render(Canvas canvas, Graph graph, Paint paint);
}

abstract class Algorithm {
  EdgeRenderer? renderer;

  /// Executes the algorithm.
  /// @param shiftY Shifts the y-coordinate origin
  /// @param shiftX Shifts the x-coordinate origin
  /// @return The size of the graph
  Size run(Graph? graph, double shiftX, double shiftY);

  void setFocusedNode(Node node);

  void init(Graph? graph);

  void step(Graph? graph);

  void setDimensions(double width, double height);
}

class Graph {
  final List<Node> _nodes = [];
  final List<Edge> _edges = [];
  List<GraphObserver> graphObserver = [];

  List<Node> get nodes => _nodes; //  List<Node> nodes = _nodes;
  List<Edge> get edges => _edges;

  var isTree = false;

  int nodeCount() => _nodes.length;

  void addNode(Node node) {
    // if (!_nodes.contains(node)) {
    _nodes.add(node);
    notifyGraphObserver();
    // }
  }

  void addNodes(List<Node> nodes) => nodes.forEach((it) => addNode(it));

  void removeNode(Node? node) {
    if (!_nodes.contains(node)) {
//            throw IllegalArgumentException("Unable to find node in graph.")
    }

    if (isTree) {
      successorsOf(node).forEach((element) => removeNode(element));
    }

    _nodes.remove(node);

    _edges.removeWhere((edge) => edge.source == node || edge.destination == node);

    notifyGraphObserver();
  }

  void removeNodes(List<Node> nodes) => nodes.forEach((it) => removeNode(it));

  Edge addEdge(Node source, Node destination, {Paint? paint}) {
    final edge = Edge(source, destination, paint: paint);
    addEdgeS(edge);

    return edge;
  }

  void addEdgeS(Edge edge) {
    var sourceSet = false;
    var destinationSet = false;
    _nodes.forEach((node) {
      if (!sourceSet && node == edge.source) {
        edge.source = node;
        sourceSet = true;
      } else if (!destinationSet && node == edge.destination) {
        edge.destination = node;
        destinationSet = true;
      }
    });
    if (!sourceSet) {
      _nodes.add(edge.source);
    }
    if (!destinationSet) {
      _nodes.add(edge.destination);
    }

    if (!_edges.contains(edge)) {
      _edges.add(edge);
      notifyGraphObserver();
    }
  }

  void addEdges(List<Edge> edges) => edges.forEach((it) => addEdgeS(it));

  void removeEdge(Edge edge) => _edges.remove(edge);

  void removeEdges(List<Edge> edges) => edges.forEach((it) => removeEdge(it));

  void removeEdgeFromPredecessor(Node? predecessor, Node? current) {
    _edges.removeWhere((edge) => edge.source == predecessor && edge.destination == current);
  }

  bool hasNodes() => _nodes.isNotEmpty;

  Edge? getEdgeBetween(Node source, Node? destination) =>
      _edges.firstWhereOrNull((element) => element.source == source && element.destination == destination);

  bool hasSuccessor(Node? node) => _edges.any((element) => element.source == node);

  List<Node> successorsOf(Node? node) => getOutEdges(node!).map((e) => e.destination).toList();

  bool hasPredecessor(Node node) => _edges.any((element) => element.destination == node);

  List<Node> predecessorsOf(Node? node) => getInEdges(node!).map((edge) => edge.source).toList();

  bool contains({Node? node, Edge? edge}) =>
      node != null && _nodes.contains(node) || edge != null && _edges.contains(edge);

//  bool contains(Edge edge) => _edges.contains(edge);

  bool containsData(data) => _nodes.any((element) => element.data == data);

  Node getNodeAtPosition(int position) {
    if (position < 0) {
//            throw IllegalArgumentException("position can't be negative")
    }

    final size = _nodes.length;
    if (position >= size) {
//            throw IndexOutOfBoundsException("Position: $position, Size: $size")
    }

    return _nodes[position];
  }

  @Deprecated('Please use the builder and id mechanism to build the widgets')
  Node getNodeAtUsingData(Widget data) => _nodes.firstWhere((element) => element.data == data);

  Node getNodeUsingKey(ValueKey key) => _nodes.firstWhere((element) => element.key == key);

  Node getNodeUsingId(dynamic id) => _nodes.firstWhere((element) => element.key == ValueKey(id));

  List<Edge> getOutEdges(Node node) => _edges.where((element) => element.source == node).toList();

  List<Edge> getInEdges(Node node) => _edges.where((element) => element.destination == node).toList();

  void notifyGraphObserver() => graphObserver.forEach((element) {
        element.notifyGraphInvalidated();
      });

  String toJson() {
    var jsonString = {
      'nodes': [
       ..._nodes.map((e) => e.hashCode.toString())
      ],
      'edges': [
        ..._edges.map((e) =>   {'from': e.source.hashCode.toString(), 'to': e.destination.hashCode.toString()})
      ]
    };

    return json.encode(jsonString);
  }

}

class Node {
  ValueKey? key;

  @Deprecated('Please use the builder and id mechanism to build the widgets')
  Widget? data;

  @Deprecated('Please use the Node.Id')
  Node(this.data, {Key? key}) {
    this.key = ValueKey(key?.hashCode ?? data.hashCode);
  }

  Node.Id(dynamic id) {
    key = ValueKey(id);
  }

  Size size = Size(0, 0);

  Offset position = Offset(0, 0);

  double get height => size.height;

  double get width => size.width;

  double get x => position.dx;

  double get y => position.dy;

  set y(double value) {
    position = Offset(position.dx, value);
  }

  set x(double value) {
    position = Offset(value, position.dy);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Node && hashCode == other.hashCode;

  @override
  int get hashCode {
    return key?.value.hashCode ?? key.hashCode;
  }

  @override
  String toString() {
    return 'Node{position: $position, key: $key, _size: $size}';
  }
}

class Edge {
  Node source;
  Node destination;

  Key? key;
  Paint? paint;

  Edge(this.source, this.destination, {this.key, this.paint});

  @override
  bool operator ==(Object? other) => identical(this, other) || other is Edge && hashCode == other.hashCode;

  @override
  int get hashCode => key?.hashCode ?? Object.hash(source, destination);
}

abstract class GraphObserver {
  void notifyGraphInvalidated();
}

typedef NodeWidgetBuilder = Widget Function(Node node);

class GraphView extends StatefulWidget {
  final Graph graph;
  final Algorithm algorithm;
  final Paint? paint;
  final NodeWidgetBuilder builder;
  final bool animated;

  GraphView(
      {Key? key, required this.graph, required this.algorithm, this.paint, required this.builder, this.animated = true})
      : super(key: key);

  @override
  _GraphViewState createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> {
  @override
  Widget build(BuildContext context) {
    if (widget.algorithm is FruchtermanReingoldAlgorithm) {
      return _GraphViewAnimated(
        key: widget.key,
        graph: widget.graph,
        algorithm: widget.algorithm,
        paint: widget.paint,
        builder: widget.builder,
      );
    } else {
      return _GraphView(
        key: widget.key,
        graph: widget.graph,
        algorithm: widget.algorithm,
        paint: widget.paint,
        builder: widget.builder,
      );
    }
  }
}

class _GraphView extends MultiChildRenderObjectWidget {
  final Graph graph;
  final Algorithm algorithm;
  final Paint? paint;

  _GraphView({Key? key, required this.graph, required this.algorithm, this.paint, required NodeWidgetBuilder builder})
      : super(key: key, children: _extractChildren(graph, builder)) {
    assert(() {
      if (children.isEmpty) {
        throw FlutterError(
          'Children must not be empty, ensure you are overriding the builder',
        );
      }

      return true;
    }());
  }

  // Traverses the nodes depth-first collects the list of child widgets that are created.
  static List<Widget> _extractChildren(Graph graph, NodeWidgetBuilder builder) {
    final result = <Widget>[];

    graph.nodes.forEach((node) {
      var widget = node.data ?? builder(node);
      result.add(widget);
    });

    return result;
  }

  @override
  RenderCustomLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomLayoutBox(graph, algorithm, paint);
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomLayoutBox renderObject) {
    renderObject
      ..graph = graph
      ..algorithm = algorithm
      ..edgePaint = paint;
  }
}

class RenderCustomLayoutBox extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, NodeBoxData>, RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData> {
  late Graph _graph;
  late Algorithm _algorithm;
  late Paint _paint;

  RenderCustomLayoutBox(
    Graph graph,
    Algorithm algorithm,
    Paint? paint, {
    List<RenderBox>? children,
  }) {
    _algorithm = algorithm;
    _graph = graph;
    edgePaint = paint;
    addAll(children);
  }

  Paint get edgePaint => _paint;

  set edgePaint(Paint? value) {
    _paint = value ??
        (Paint()
          ..color = Colors.black
          ..strokeWidth = 3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    markNeedsPaint();
  }

  Graph get graph => _graph;

  set graph(Graph value) {
    _graph = value;
    markNeedsLayout();
  }

  Algorithm get algorithm => _algorithm;

  set algorithm(Algorithm value) {
    _algorithm = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeBoxData) {
      child.parentData = NodeBoxData();
    }
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.biggest;
      assert(size.isFinite);
      return;
    }

    var child = firstChild;
    var position = 0;
    var looseConstraints = BoxConstraints.loose(constraints.biggest);
    while (child != null) {
      final node = child.parentData as NodeBoxData;

      child.layout(looseConstraints, parentUsesSize: true);
      graph.getNodeAtPosition(position).size = child.size;

      child = node.nextSibling;
      position++;
    }

    size = algorithm.run(graph, 10, 10);

    child = firstChild;
    position = 0;
    while (child != null) {
      final node = child.parentData as NodeBoxData;

      node.offset = graph.getNodeAtPosition(position).position;

      child = node.nextSibling;
      position++;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);

    algorithm.renderer?.render(context.canvas, graph, edgePaint);

    context.canvas.restore();

    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Graph>('graph', graph));
    properties.add(DiagnosticsProperty<Algorithm>('algorithm', algorithm));
    properties.add(DiagnosticsProperty<Paint>('paint', edgePaint));
  }
}

class NodeBoxData extends ContainerBoxParentData<RenderBox> {}

class _GraphViewAnimated extends StatefulWidget {
  final Graph graph;
  final Algorithm algorithm;
  final Paint? paint;
  final nodes = <Widget>[];
  final stepMilis = 25;

  _GraphViewAnimated(
      {Key? key, required this.graph, required this.algorithm, this.paint, required NodeWidgetBuilder builder}) {
    graph.nodes.forEach((node) {
      nodes.add(node.data ?? builder(node));
    });
  }

  @override
  _GraphViewAnimatedState createState() => _GraphViewAnimatedState();
}

class _GraphViewAnimatedState extends State<_GraphViewAnimated> {
  late Timer timer;
  late Graph graph;
  late Algorithm algorithm;

  @override
  void initState() {
    graph = widget.graph;

    algorithm = widget.algorithm;
    algorithm.init(graph);
    startTimer();

    super.initState();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: widget.stepMilis), (timer) {
      algorithm.step(graph);
      update();
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    algorithm.setDimensions(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: EdgeRender(algorithm, graph, Offset(20, 20)),
        ),
        ...List<Widget>.generate(graph.nodeCount(), (index) {
          return Positioned(
            child: GestureDetector(
              child: widget.nodes[index],
              onPanUpdate: (details) {
                graph.getNodeAtPosition(index).position += details.delta;
                update();
              },
            ),
            top: graph.getNodeAtPosition(index).position.dy,
            left: graph.getNodeAtPosition(index).position.dx,
          );
        }),
      ],
    );
  }

  Future<void> update() async {
    setState(() {});
  }
}

class EdgeRender extends CustomPainter {
  Algorithm algorithm;
  Graph graph;
  Offset offset;

  EdgeRender(this.algorithm, this.graph, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    var edgePaint = (Paint()
      ..color = Colors.black
      ..strokeWidth = 3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    algorithm.renderer!.render(canvas, graph, edgePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
