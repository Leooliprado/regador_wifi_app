import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        colorScheme: const ColorScheme.light().copyWith(
          secondary: Colors.blue,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color.fromARGB(255, 219, 132, 1),
        colorScheme: const ColorScheme.dark().copyWith(
          secondary: const Color.fromARGB(255, 219, 132, 1),
        ),
      ),
      home: Umidade(),
    );
  }
}

class Umidade extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Umidade do Solo',
          style: TextStyle(fontSize: 25),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        centerTitle: true,
      ),
      body: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final String url = 'http://44.206.253.220:4000/puxar';
  String? umidade;
  String? mediaDiaria;
  List<dynamic>? mediasDiariasSemana;
  bool? estadoBombaDagua;
  bool isLoading = false;
  String error = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchData();
    startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      startTimer();
    }
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      fetchData();
    });
  }

  void fetchData() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final fetchedData = await fetchDataFromServer();
      setState(() {
        umidade = fetchedData['umidade'].toString();
        mediaDiaria = fetchedData['media_diaria'].toString();
        estadoBombaDagua = fetchedData['estado_bomba'] as bool?;
        mediasDiariasSemana = fetchedData['medias_diarias_semana'];
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        print(error);
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchDataFromServer() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar os dados. Código de status: ${response.statusCode}');
    }
  }

  double calculateHumidityPercentage(String? humidityData) {
    if (humidityData == null) {
      return 0.0;
    }

    double humidityValue = double.tryParse(humidityData) ?? 0.0;
    return 100 - ((humidityValue / 4095) * 100);
  }

  String formatDate(String dateStr) {
    final date = DateFormat('EEE, dd MMM yyyy HH:mm:ss').parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            SizedBox(height: 30),

            Text(
              umidade != null ? '$umidade umidade!' : 'Carregando...',
              style: TextStyle(fontSize: 20),
            ),
            if (error.isNotEmpty) Text('Erro: $error'),

            if (umidade != null)
              SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 101,
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 0,
                        endValue: 101,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: calculateHumidityPercentage(umidade),
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text(
                          '${calculateHumidityPercentage(umidade).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        angle: 90,
                        positionFactor: 0.75,
                      ),
                    ],
                  ),
                ],
              ),

            if (mediaDiaria == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nenhuma média diária de umidade disponível',
                      style: TextStyle(fontSize: 25, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            SizedBox(height: 30),

            if (mediaDiaria != null)
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                title: ChartTitle(text: 'Média Diária de Umidade'),
                legend: Legend(isVisible: false),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ChartSeries>[
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: [
                      {'label': 'Média Diária', 'value': calculateHumidityPercentage(mediaDiaria)},
                    ],
                    xValueMapper: (datum, _) => datum['label'],
                    yValueMapper: (datum, _) => datum['value'],
                    dataLabelSettings: DataLabelSettings(isVisible: true, labelAlignment: ChartDataLabelAlignment.auto),
                    dataLabelMapper: (datum, _) => '${datum['value'].toStringAsFixed(2)}%',
                  ),
                ],
              ),

            SizedBox(height: 30),

            if (mediasDiariasSemana != null)
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                title: ChartTitle(text: 'Médias Diárias da Umidade Semanal'),
                legend: Legend(isVisible: false),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ChartSeries>[
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: mediasDiariasSemana!.map((data) {
                      return {
                        'data': data['data'],
                        'media_umidade_solo': calculateHumidityPercentage(data['media_umidade_solo'].toString()),
                      };
                    }).toList(),
                    xValueMapper: (datum, _) => formatDate(datum['data']),
                    yValueMapper: (datum, _) => datum['media_umidade_solo'],
                    dataLabelSettings: DataLabelSettings(isVisible: true, labelAlignment: ChartDataLabelAlignment.outer),
                    dataLabelMapper: (datum, _) => '${datum['media_umidade_solo'].toStringAsFixed(2)}%',
                  ),
                ],
              ),

            SizedBox(height: 30),

            if (estadoBombaDagua != null)
              RichText(
                text: TextSpan(
                  text: "bomba d'água ",
                  style: TextStyle(fontSize: 30, color: textColor),
                  children: [
                    TextSpan(
                      text: estadoBombaDagua! ? 'ligada' : 'desligada',
                      style: TextStyle(
                        color: estadoBombaDagua! ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
