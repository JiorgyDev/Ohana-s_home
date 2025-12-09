import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Callbacks
  Function(Map<String, dynamic>)? onNewMessage;
  Function(String)? onUserTyping;
  Function(String)? onUserStopTyping;
  Function(Map<String, dynamic>)? onMessagesRead;
  Function(String)? onUserOnline;
  Function(String)? onUserOffline;

  bool get isConnected => _isConnected;

  // Conectar al servidor Socket.io
  void connect() {
    if (_socket != null && _isConnected) {
      print('🔌 Socket ya está conectado');
      return;
    }

    final userId = AuthService().userId;
    if (userId == null) {
      print('❌ No hay userId, no se puede conectar socket');
      return;
    }

    print('🔌 Conectando socket...');

    _socket = IO.io(
      'https://wooheartc-back.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Socket conectado');
      _isConnected = true;
      // Autenticar usuario
      _socket!.emit('authenticate', userId);
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket desconectado');
      _isConnected = false;
    });

    // Escuchar eventos
    _socket!.on('new_message', (data) {
      print('📩 Nuevo mensaje recibido');
      if (onNewMessage != null) onNewMessage!(data);
    });

    _socket!.on('user_typing', (data) {
      print('⌨️ Usuario escribiendo');
      if (onUserTyping != null) onUserTyping!(data['conversationId']);
    });

    _socket!.on('user_stop_typing', (data) {
      print('⏸️ Usuario dejó de escribir');
      if (onUserStopTyping != null) onUserStopTyping!(data['conversationId']);
    });

    _socket!.on('messages_read', (data) {
      print('✅ Mensajes leídos');
      if (onMessagesRead != null) onMessagesRead!(data);
    });

    _socket!.on('user_online', (userId) {
      print('🟢 Usuario online: $userId');
      if (onUserOnline != null) onUserOnline!(userId);
    });

    _socket!.on('user_offline', (userId) {
      print('⚫ Usuario offline: $userId');
      if (onUserOffline != null) onUserOffline!(userId);
    });

    _socket!.onError((error) {
      print('🚨 Error en socket: $error');
    });
  }

  // Unirse a una conversación
  void joinConversation(String conversationId) {
    if (_socket != null && _isConnected) {
      print('🚪 Uniéndose a conversación: $conversationId');
      _socket!.emit('join_conversation', conversationId);
    }
  }

  // Salir de una conversación
  void leaveConversation(String conversationId) {
    if (_socket != null && _isConnected) {
      print('🚪 Saliendo de conversación: $conversationId');
      _socket!.emit('leave_conversation', conversationId);
    }
  }

  // Usuario está escribiendo
  void sendTyping(String conversationId, String userId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing', {
        'conversationId': conversationId,
        'userId': userId,
      });
    }
  }

  // Usuario dejó de escribir
  void sendStopTyping(String conversationId, String userId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('stop_typing', {
        'conversationId': conversationId,
        'userId': userId,
      });
    }
  }

  // Desconectar socket
  void disconnect() {
    if (_socket != null) {
      print('🔌 Desconectando socket...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  // Limpiar callbacks
  void clearCallbacks() {
    onNewMessage = null;
    onUserTyping = null;
    onUserStopTyping = null;
    onMessagesRead = null;
    onUserOnline = null;
    onUserOffline = null;
  }
}
