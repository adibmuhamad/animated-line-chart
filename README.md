[![pub package](https://img.shields.io/pub/v/animated_line_chart.svg)](https://pub.dev/packages/animated_line_chart)

# animated_line_chart

![Example](https://raw.githubusercontent.com/adibmuhamad/animated-line-chart/main/screenshots/example.png)

An animated line chart library for flutter.
 - Support for datetime axis
 - Animation of the chart
 - Divide region based on datetime

## Getting Started

Try the sample project or include in your project.

Example code:
```dart
    final List<DataPoint> data = [
        DataPoint(x: DateTime(2023, 1, 1), y: 10),
        DataPoint(x: DateTime(2023, 1, 15), y: 30),
        DataPoint(x: DateTime(2023, 2, 1), y: 20),
        DataPoint(x: DateTime(2023, 2, 15), y: 40),
        DataPoint(x: DateTime(2023, 3, 1), y: 50),
        DataPoint(x: DateTime(2023, 3, 15), y: 60),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SizedBox(
          width: 300, 
          height: 200,
          child: AnimatedLineChart(
            data: data,
            dividerX: DateTime(2023, 2, 1),
            leftChartColor: Colors.grey,
            rightChartColor: Colors.green,
          ),
        ),
      ),
    );
```

## Contributing

Feel free to contribute! Here's how you can contribute:

- [Open an issue](https://github.com/adibmuhamad/animated-line-chart/issues) if you believe you've encountered a bug.
- Make a [pull request](https://github.com/adibmuhamad/animated-line-chart/pull) to add new features/make quality-of-life improvements/fix bugs.

## Author

- Muhammad Adib Yusrul Muna

## License
Copyright © 2023 Muhammad Adib Yusrul Muna

This software is distributed under the MIT license. See the [LICENSE](https://github.com/adibmuhamad/animated-line-chart/blob/main/LICENSE) file for the full license text.