import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class Map3DScreen extends StatefulWidget {
  final List<double> lats;
  final List<double> lons;
  final List<double> alts;

  const Map3DScreen({Key? key, required this.lats, required this.lons, required this.alts}) : super(key: key);

  @override
  _Map3DScreenState createState() => _Map3DScreenState();
}

class _Map3DScreenState extends State<Map3DScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);
    _load3DMap();
  }

  Future<void> _load3DMap() async {
    try {
      // ATTENZIONE: Usa 10.0.2.2 per l'Emulatore. Usa il tuo IP Wi-Fi se usi un telefono fisico!
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/3d_route'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lats': widget.lats,
          'lons': widget.lons,
          'alts': widget.alts,
        }),
      );

      if (response.statusCode == 200) {
        _controller.loadHtmlString(response.body);
        setState(() => isLoading = false);
      } else {
        print("Errore Server: ${response.statusCode}");
      }
    } catch (e) {
      print("Errore Connessione 3D: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Digital Twin 3D", style: TextStyle(color: Colors.cyanAccent)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.cyanAccent),
                  SizedBox(height: 15),
                  Text("Generazione Ologramma 3D...", style: TextStyle(color: Colors.grey))
                ],
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}