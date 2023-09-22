import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:predicto/model/individual_stock_prediction_model.dart';
import 'package:predicto/model/predicted_stocks.dart';

void main() {
  runApp(const MyApp());
}

List<Color> gradientColors = [
  Colors.blue,
  Colors.indigo,
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Predicto'),
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
  List<PredictedStocks> allPredictedStocks = [];

  Future<List<PredictedStocks>> loadJsonFromAssets() async {
    String jsonString =
    await rootBundle.loadString('assets/predicted_data.json');

    final jsonResponse = json.decode(jsonString);

    List<PredictedStocks> stocks = [];

    for (var i in jsonResponse) {
      stocks.add(PredictedStocks.fromJson(i));
    }

    return stocks;
  }

  @override
  void initState() {
    super.initState();
    loadJsonFromAssets().then((predictedStocks) {
      allPredictedStocks = predictedStocks;
      stocksName = predictedStocks[0].allStocks.keys.toList();
      years = predictedStocks.map((e) => e.date.split('-')[0]).toSet().toList();
      setState(() {});
    });
  }

  bool showAvg = false;
  String? selectedStock;
  String? selectedYear;
  List<String>? years;
  List<String>? stocksName;
  List<IndividualStock> tempIndividualStock = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text(
          widget.title,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              "Pick stock for prediction:",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                return stocksName!
                    .where((element) =>
                    element
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()))
                    .toList();
              },
              onSelected: (value) {
                setState(() {
                  selectedStock = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Pick year for prediction:",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                years == null
                    ? Center(
                  child: CircularProgressIndicator(),
                )
                    : Expanded(
                  child: DropdownButtonFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      value: selectedYear,
                      items: years!
                          .map((year) =>
                          DropdownMenuItem(
                              value: year, child: Text(year)))
                          .toList(),
                      onChanged: (value) {
                        print(value);
                        selectedYear = value;
                      }),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1.5,
                  child: LineChart(
                    mainData(),
                    // showAvg ? avgData() : mainData(),
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 34,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        showAvg = !showAvg;
                      });
                    },
                    child: Text(
                      'avg',
                      style: TextStyle(
                        fontSize: 12,
                        color: showAvg
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70),


            Expanded(child: Container()),
            ElevatedButton(
              onPressed: () {
                var filteredStocksByDate = allPredictedStocks.where(
                        (element) =>
                    element.date.split('-')[0] == selectedYear);

                List<IndividualStock> individualStock =
                filteredStocksByDate.map((e) {
                  String? numRange = e.allStocks[selectedStock];

                  RegExp regExp = RegExp(
                      r'(\d+\.\d+)'); // Regular expression to match decimal numbers

                  Iterable<RegExpMatch> matches = regExp.allMatches(numRange!);

                  List<double> numbers = matches
                      .map((match) => double.parse(match.group(0)!))
                      .toList();

                  // Calculate the average
                  double average = (numbers[0] + numbers[1]) / 2;

                  double calculatedMonthInDigits =
                      (int.parse(e.date.split('-')[1]) - 1) * 2;
                  return IndividualStock(
                      convertedMonthToInt: calculatedMonthInDigits,
                      stockPrice: average);
                }).toList();

                tempIndividualStock = individualStock;
                tempIndividualStock.forEach((element) {
                  print(element.convertedMonthToInt);
                  print(element.stockPrice);
                });
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Show Prediction'),
              ),
            )
          ],
        ),
      ),
    );
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Colors.green,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: Colors.yellow,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: const FlTitlesData(
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 45,
          ),
        ),
      ),
      minX: 0,
      maxX: 22,
      minY: 0,
      maxY: 230,
      lineBarsData: [
        LineChartBarData(
          spots: tempIndividualStock.map((e) =>
              FlSpot(e.convertedMonthToInt, e.stockPrice)).toList(),
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

Widget leftTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 15,
  );
  String text;
  switch (value.toInt()) {
    case 0:
      text = '\$0';
      break;

    case 50:
      text = '\$50';
      break;
    case 100:
      text = '\$100';
      break;
    case 150:
      text = '\$150';
      break;
    case 200:
      text = '\$200';
      break;
    default:
      return Container();
  }

  return Text(text, style: style, textAlign: TextAlign.left);
}

Widget bottomTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  Widget text;
  switch (value.toInt()) {
    case 0:
      text = const Text('JAN', style: style);
      break;
    case 2:
      text = const Text('FEB', style: style);
      break;
    case 4:
      text = const Text('MAR', style: style);
      break;
    case 6:
      text = const Text('APR', style: style);
      break;
    case 8:
      text = const Text('MAY', style: style);
      break;
    case 10:
      text = const Text('JUN', style: style);
      break;
    case 12:
      text = const Text('JUL', style: style);
      break;
    case 14:
      text = const Text('AUG', style: style);
      break;
    case 16:
      text = const Text('SEP', style: style);
      break;
    case 18:
      text = const Text('OCT', style: style);
      break;
    case 20:
      text = const Text('NOV', style: style);
      break;
    case 22:
      text = const Text('DEC', style: style);
      break;
    default:
      text = const Text('', style: style);
      break;
  }

  return SideTitleWidget(
    angle: 1,
    axisSide: meta.axisSide,
    child: text,
  );
}
