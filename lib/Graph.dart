
import 'package:flutter/cupertino.dart';

class GraphView extends StatefulWidget {
  @override
  GraphViewState createState() => GraphViewState();
}

class GraphViewState extends State<GraphView> {
  @override
  Widget build(BuildContext context) {
    return NodeWidget();
  }
}

class NodeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(child: Text("TestNode"),);
  }
}

class Graph {
  List<Node> nodeList = [];
}

class Node {
  int nodeId = 1234;
  String name = "Node";
}

