import 'package:flutter/material.dart';
import 'Graph.dart';

void main() {
  runApp(MaterialApp(
    home: GraphView()
  ));
}

class Test extends StatefulWidget {
  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {

  List<String> quote = [
    'One',
    'Two',
    'Three'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        title: Text('Family Tree'),
        centerTitle: true,
      ),
      body: Column(
        children: quote.map((e) => Text(e)).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        child: Text("Button"),
      ),
    );
  }
}
