import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';

class GraphView extends StatefulWidget {
  @override
  GraphViewState createState() => GraphViewState();
}

class GraphViewState extends State<GraphView> {
  List<Node> familyMembers = [];

  GraphViewState() {
    familyMembers.add(Node('Ned', 'Stark'));
    familyMembers.add(Node('Catelyn', 'Tully'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _GraphView(child: Text("Tesing"))
    );
  }
}

class _GraphView extends MultiChildRenderObjectWidget {
  _GraphView({
    required Widget child
  }) : super(children: [child]);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return __GraphView();
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    // TODO: implement updateRenderObject
    super.updateRenderObject(context, renderObject);
  }
}

class _GraphViewParentData extends ContainerBoxParentData<RenderBox> {
   /// if we are to implement flex, we'll set it here like
   /// int flex;
}

class __GraphView extends RenderBox
  with ContainerRenderObjectMixin<RenderBox, _GraphViewParentData>,
  RenderBoxContainerDefaultsMixin<RenderBox, _GraphViewParentData> {
  
    @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! _GraphViewParentData) {
       child.parentData = _GraphViewParentData();
   }
  }

   @override
    Size computeDryLayout(BoxConstraints constraints) {
      return Size(constraints.maxWidth, constraints.maxHeight);
    }
}

class Node {
  String name = "Unknown";
  String houseBorn = "Unkown";

  Node(this.name, this.houseBorn);
}

class NodeWidget extends StatelessWidget {
  final Node node;

  NodeWidget(this.node);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text(node.name),
    );
  }
}