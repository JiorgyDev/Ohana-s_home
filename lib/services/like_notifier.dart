import 'package:flutter/foundation.dart';

/// Notificador global para sincronizar likes entre diferentes pantallas
/// 
/// PROBLEMA QUE RESUELVE:
/// - HomeScreen da like → ProfileScreen no se entera
/// - Había que refrescar manualmente para ver cambios
/// 
/// CÓMO FUNCIONA:
/// 1. Cuando alguien da like, llama a notifyLikeChanged()
/// 2. ProfileScreen está "escuchando" y se actualiza solo
class LikeNotifier extends ChangeNotifier {
  // Este método es como gritar "¡HAY CAMBIOS!"
  void notifyLikeChanged() {
    notifyListeners(); // Avisa a todos los que están escuchando
  }
}

// Instancia GLOBAL - accesible desde cualquier parte de la app
final likeNotifier = LikeNotifier();