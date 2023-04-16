import 'package:animated_line_chart/animated_line_chart.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animated Line Chart',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Animated Line Chart'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<DataPoint> data = [
    DataPoint(x: DateTime(2023, 1, 1), y: 10),
    DataPoint(x: DateTime(2023, 1, 15), y: 30),
    DataPoint(x: DateTime(2023, 2, 1), y: 20),
    DataPoint(x: DateTime(2023, 2, 15), y: 40),
    DataPoint(x: DateTime(2023, 3, 1), y: 50),
    DataPoint(x: DateTime(2023, 3, 15), y: 60),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SizedBox(
          width: 300, // set the desired width
          height: 200, // set the desired height
          child: AnimatedLineChart(
            data: data,
            dividerX: DateTime(2023, 2, 1),
            // dividerXColor: Colors.grey,
            leftChartColor: Colors.grey,
            rightChartColor: Colors.green,
            // showXLabel: true,
            // showYLabel: true,
            // labelTextStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            // showDotAnimation: false,
            // showLastData: true,
          ),
        ),
      ),
    );
  }
}