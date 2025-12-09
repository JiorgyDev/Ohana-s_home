import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/messaging_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../data/model/message.dart';
import '../data/model/conversation.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final UserInfo otherUser;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.otherUser,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagingService _messagingService = MessagingService();
  final SocketService _socketService = SocketService();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isOtherUserTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocket();
  }

  void _loadMessages() async {
    try {
      final messages = await _messagingService.getMessages(
        widget.conversationId,
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar mensajes: $e')));
    }
  }

  void _setupSocket() {
    _socketService.connect();
    _socketService.joinConversation(widget.conversationId);

    _socketService.onNewMessage = (data) {
      if (data['conversationId'] == widget.conversationId) {
        final newMessage = Message.fromJson(data['message']);
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    };

    _socketService.onUserTyping = (conversationId) {
      if (conversationId == widget.conversationId) {
        setState(() => _isOtherUserTyping = true);
      }
    };

    _socketService.onUserStopTyping = (conversationId) {
      if (conversationId == widget.conversationId) {
        setState(() => _isOtherUserTyping = false);
      }
    };
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messageController.clear();
    });

    try {
      final message = await _messagingService.sendMessage(
        widget.conversationId,
        content,
      );

      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
    }
  }

  void _onTyping() {
    final userId = AuthService().userId;
    if (userId != null) {
      _socketService.sendTyping(widget.conversationId, userId);
    }
  }

  void _onStopTyping() {
    final userId = AuthService().userId;
    if (userId != null) {
      _socketService.sendStopTyping(widget.conversationId, userId);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A1617),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB42C1C),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.otherUser.avatar),
              backgroundColor: const Color(0xFFFE8043),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (_isOtherUserTyping)
                    const Text(
                      'escribiendo...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Mensajes
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFE8043)),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'No hay mensajes aún.\n¡Envía el primero!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine = message.isMine;

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFFFE8043)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Column(
                            crossAxisAlignment: isMine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(message.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input de mensaje
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (text) {
                      if (text.isNotEmpty) {
                        _onTyping();
                      } else {
                        _onStopTyping();
                      }
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFFE8043),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _socketService.leaveConversation(widget.conversationId);
    super.dispose();
  }
}
