import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

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
  String? vaiChover;
  String? pop;
  List<dynamic>? mediasDiariasSemana;
  bool? estadoBombaDagua;
  String? precisa_irrigar;
  bool isLoading = false;
  String error = '';
  Timer? _timer;
  List<dynamic>? tudoTebalaIrrigar;

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
        tudoTebalaIrrigar = fetchedData['tudo_tebala_irrigar'];
        precisa_irrigar = fetchedData['precisa_irrigar'].toString();;

        // Extrair informações de prever_chuva
        if (fetchedData['prever_chuva'] != null) {
          final preverChuva = fetchedData['prever_chuva'];
          vaiChover = preverChuva['description'];
          pop = preverChuva['pop']?.toString() ?? '0.0';
          double temp = preverChuva['temp']?.toDouble() ?? 0.0;
          vaiChover = "Previsão do tempo para hoje: ${vaiChover ?? "N/A"} com ${pop}% de chance de chuva, Temperatura: ${temp.toStringAsFixed(1)}°C";
        }
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

  double calculateHumidityPercentage(double humidityValue) {
    const maxSensorValue = 4095.0;
    return 100 - ((humidityValue / maxSensorValue) * 100);
  }

  String formatDate(String dateStr) {
    final date = DateFormat('EEE, dd MMM yyyy HH:mm:ss \'GMT\'').parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(date); // Alterado para exibir somente a data
  }

  String formatTime(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('HH:mm').format(date); // Formata para exibir somente a hora e os minutos
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
              style: TextStyle(fontSize: 30),
            ),
            if (error.isNotEmpty)
              Text(
                'Erro: $error',
                style: TextStyle(fontSize: 30),
              ),

            if (pop != null && double.parse(pop!) >= 70)
              Text(
                "Hoje a previsão é de chuva com $pop% de chance. Por isso, a irrigação será suspensa!",
                style: TextStyle(fontSize: 20, color: Colors.blue),
                textAlign: TextAlign.center, // Centraliza o texto
              ),

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
                        value: calculateHumidityPercentage(double.parse(umidade!)),
                        needleColor: textColor, // Cor do ponteiro
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text(
                          '${calculateHumidityPercentage(double.parse(umidade!)).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: textColor, // Cor do texto
                          ),
                        ),
                        angle: 90,
                        positionFactor: 0.75,
                      ),
                    ],
                  ),
                ],
              ),

            SizedBox(height: 30),

            if (mediaDiaria != null)
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(minimum: 0, maximum: 100),
                title: ChartTitle(text: 'Média Diária de Umidade'),
                legend: Legend(isVisible: false),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ChartSeries>[
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: [
                      {'label': 'Média Diária', 'value': calculateHumidityPercentage(double.parse(mediaDiaria!))},
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
              primaryXAxis: CategoryAxis(
                labelRotation: 0, // Rotaciona as labels para garantir que estejam horizontais
                interval: 1, // Define o intervalo entre as labels no eixo x
                labelStyle: TextStyle(fontSize: 12), // Ajusta o tamanho da fonte para as labels
              ),
              primaryYAxis: NumericAxis(minimum: 0, maximum: 100),
              title: ChartTitle(text: 'Médias Diárias da Umidade Semanal'),
              legend: Legend(isVisible: false),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <ChartSeries>[
                ColumnSeries<Map<String, dynamic>, String>(
                  dataSource: mediasDiariasSemana!.map((data) {
                    return {
                      'data': formatDate(data['data']),
                      'media_umidade_solo': calculateHumidityPercentage(double.parse(data['media_umidade_solo'].toString())),
                    };
                  }).toList(),
                  xValueMapper: (datum, _) => datum['data'],
                  yValueMapper: (datum, _) => datum['media_umidade_solo'],
                  dataLabelSettings: DataLabelSettings(isVisible: true, labelAlignment: ChartDataLabelAlignment.outer),
                  dataLabelMapper: (datum, _) => '${datum['media_umidade_solo'].toStringAsFixed(2)}%',
                ),
              ],
            ),


            SizedBox(height: 30),

            if (tudoTebalaIrrigar != null)
              SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: 45, // Rotaciona as labels se necessário para evitar sobreposição
                  labelStyle: TextStyle(fontSize: 12), // Ajusta o tamanho da fonte das labels
                ),
                primaryYAxis: NumericAxis(minimum: 0, maximum: 100),
                title: ChartTitle(text: 'Dados de Umidade ao Longo do Dia'),
                legend: Legend(isVisible: false),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ChartSeries>[
                  LineSeries<Map<String, dynamic>, String>(
                    dataSource: tudoTebalaIrrigar!.map((data) {
                      return {
                        'data': formatTime(data[0]), // Formata para mostrar somente hora e minuto
                        'valor': calculateHumidityPercentage(data[1]),
                      };
                    }).toList(),
                    xValueMapper: (datum, _) => datum['data'],
                    yValueMapper: (datum, _) => datum['valor'],
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                    dataLabelMapper: (datum, _) => '${datum['valor'].toStringAsFixed(2)}%',
                  ),
                ],
              ),


              SizedBox(height: 30),


            if (precisa_irrigar != null)
              Text("Irrigou hoje: $precisa_irrigar",
                style: TextStyle(fontSize: 30, color: textColor),
                ),

            SizedBox(height: 30),

            if (estadoBombaDagua != null)
              RichText(
                text: TextSpan(
                  text: "Bomba d'água ",
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
            if (vaiChover != null)
              Text(
                vaiChover!,
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center, // Centraliza o texto
              ),

            SizedBox(height: 40),

          ],
        ),
      ),
    );
  }
}
