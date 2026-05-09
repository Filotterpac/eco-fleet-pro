import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

class EcoNavLogic {
  final FlutterTts tts = FlutterTts();
  String lastVocalAdvice = "";

  EcoNavLogic() {
    tts.setLanguage("it-IT");
    tts.setSpeechRate(0.5);
  }

  Map<String, String> getTimes(Map<String, dynamic> stats, String selectedMode) { // <-- Aggiungi il parametro selectedMode
    double km = stats['distanza_km'].toDouble();
    
    // Seleziona la media di velocità corretta dal dizionario stats
    // Attenzione: 'eco' nel tuo DB si chiamava 'target'
    String speedKey = selectedMode == 'eco' ? 'vel_media_target' : 'vel_media_$selectedMode';
    double vMode = stats[speedKey]?.toDouble() ?? 50.0; 

    return {
      "arrivo": DateFormat('HH:mm').format(DateTime.now().add(Duration(minutes: (km/vMode*60).toInt()))),
      "rimasto": "${(km/vMode*60).toInt()} min"
    };
  }







  Map<String, String> calculateETA(Map<String, dynamic> stats) {
    double kmTot = stats['distanza_km'].toDouble();
    double vNorm = stats['vel_media_normale'].toDouble();
    double vEco = stats['vel_media_target'].toDouble();
    
    DateTime ora = DateTime.now();
    return {
      "std": DateFormat('HH:mm').format(ora.add(Duration(minutes: (kmTot/vNorm*60).toInt()))),
      "eco": DateFormat('HH:mm').format(ora.add(Duration(minutes: (kmTot/vEco*60).toInt()))),
      "rimasto": "${(kmTot/vEco*60).toInt()} min"
    };
  }

  void speakAdvice(String advice, double metri) {
    String text = "";
    if (advice.contains("VELEGGIA")) text = "Veleggia ora, discesa tra ${metri.toInt()} metri";
    if (advice.contains("RALLENTA")) text = "Rallenta dolcemente per limite imminente";
    if (advice.contains("LIMITE")) text = "Attenzione, sei sopra il limite stradale";

    if (text != "" && text != lastVocalAdvice) {
      tts.speak(text);
      lastVocalAdvice = text;
    }
  }
}