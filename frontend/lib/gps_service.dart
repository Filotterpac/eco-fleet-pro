import 'package:geolocator/geolocator.dart';

class GpsService {
  static Future<Position?> ottieniPosizione() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Il GPS del telefono è spento.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permessi GPS negati.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permessi negati permanentemente.');
    } 

    try {
      // IL SALVAVITA: Aspettiamo massimo 5 secondi, poi andiamo in errore controllato
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), // <-- Impedisce il blocco dell'app!
      );
    } catch (e) {
      // Se scatta il timeout (spesso accade sugli emulatori), proviamo a prendere l'ultima posizione salvata
      Position? ultimaPosizione = await Geolocator.getLastKnownPosition();
      if (ultimaPosizione != null) {
        return ultimaPosizione;
      }
      return Future.error('Nessun segnale GPS. Assicurati di aver impostato una posizione nell\'emulatore.');
    }
  }
}