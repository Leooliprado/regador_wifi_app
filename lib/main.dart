import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system, // Configuração do modo de tema para seguir o tema do sistema
      theme: ThemeData.light().copyWith( // Definição do tema claro
        primaryColor: Colors.blue, // Cor primária
        colorScheme: const ColorScheme.light().copyWith( // Esquema de cores
          secondary: Colors.blue, // Cor secundária
        ),
      ),
      darkTheme: ThemeData.dark().copyWith( // Definição do tema escuro
        primaryColor: const Color.fromARGB(255, 219, 132, 1), // Cor primária
        colorScheme: const ColorScheme.dark().copyWith( // Esquema de cores
          secondary: const Color.fromARGB(255, 219, 132, 1), // Cor secundária
        ),
      ),
      home: Umidade(), // Definição da página inicial do aplicativo
    );
  }
}

class Umidade extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold( // Use Scaffold para aplicar a cor de fundo apropriada
      appBar: AppBar(
        title: const Text(
          'Umidade do Solo',
          style: TextStyle(fontSize: 25),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary, // Cor de fundo da barra de aplicativos
        centerTitle: true,
      ),
      body: MyHomePage(), // Remova o MaterialApp desnecessário
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String url = 'http://44.206.253.220:4000/puxar';
  String? data;
  bool isLoading = false;
  String error = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchData(); // Inicia a primeira busca de dados
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      fetchData(); // Atualiza os dados a cada 2 segundos
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancela o timer ao descartar o widget
    super.dispose();
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
      return response.body; // Assume que o servidor retorna texto simples
    } else {
      throw Exception('Falha ao carregar os dados. Código de status: ${response.statusCode}');
    }
  }


double calculateHumidityPercentage(String humidityData) {
  final int humidityValue = int.tryParse(humidityData) ?? 0;
  return 100 - ((humidityValue / 4095) * 100); // Calcula a porcentagem de umidade invertida
}

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data != null ? '$data umidade!' : 'Carregando...',
              style: TextStyle(fontSize: 30),
            ), // Mostra "Carregando..." enquanto os dados estão sendo carregados
            if (error.isNotEmpty) Text('Erro: $error'), // Mostra o erro se houver algum

            Text(
              'Umidade: ${data != null ? '${calculateHumidityPercentage(data!).toStringAsFixed(2)}%' : 'Carregando...'}',
              style: TextStyle(fontSize: 30),
            ), 


            if (data != null && int.tryParse(data!)! >= 3001)
              const Text(
                "bomba d'água ligada",
                style: TextStyle(fontSize: 30),
              ),
            if (data != null && int.tryParse(data!)! < 3001)
              const Text(
                "bomba d'água desligada",
                style: TextStyle(fontSize: 30),
              ),
          ],
        ),
      ),
    );
  }
}
