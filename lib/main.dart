import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  String? data;
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
        data = fetchedData;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> fetchDataFromServer() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao carregar os dados. Código de status: ${response.statusCode}');
    }
  }

  double calculateHumidityPercentage(String humidityData) {
    final int humidityValue = int.tryParse(humidityData) ?? 0;
    return 100 - ((humidityValue / 4095) * 100);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Text(
            data != null ? '$data umidade!' : 'Carregando...',
            style: TextStyle(fontSize: 20),
             ), // Mostra "Carregando..." enquanto os dados estão sendo carregados
              if (error.isNotEmpty) Text('Erro: $error'), // Mostra o erro se houver algum

            if (data != null)
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
                        value: calculateHumidityPercentage(data!),
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text(
                          '${calculateHumidityPercentage(data!).toStringAsFixed(2)}%',
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

            if (data != null)
              RichText(
                text: TextSpan(
                  text: "bomba d'água ",
                  style: TextStyle(fontSize: 30, color: textColor), // Default text style
                  children: [
                    TextSpan(
                      text: int.tryParse(data!)! >= 3001 ? 'ligada' : 'desligada',
                      style: TextStyle(
                        color: int.tryParse(data!)! >= 3001 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
