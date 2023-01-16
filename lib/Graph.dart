import 'package:flutter/material.dart';
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
      child: CustomPaint(
        child: Container(),
        painter: GraphViewPainter(),),
    );
  }
}

class GraphViewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(Paint()..color = Colors.blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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