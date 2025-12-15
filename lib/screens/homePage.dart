import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ohanas_app/services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/model/comment.dart';
import '../data/model/conversation.dart';
import '../services/comment_services.dart';
import '../services/messaging_service.dart';
import '../services/socket_service.dart';
import '../services/translation_service.dart';
import '../widgets/language_selection_screen.dart';
import '../widgets/translated_text.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';

// ============================================
// SERVICIO PARA CONECTAR CON EL API
// ============================================
class PetService {
  static const String baseUrl = 'https://wooheartc-back.onrender.com/api/v1';

  static Future<List<PhotoPost>> fetchPets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pets'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final petsData = jsonData['data']['pets'] as List;
        final List<PhotoPost> pets = petsData
            .map((petJson) => PhotoPost.fromJson(petJson))
            .toList();

        pets.shuffle(); // ← AGREGA ESTA LÍNEA

        return pets;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar mascotas: $e');
    }
  }
}

// ignore: camel_case_types
class homepage extends StatelessWidget {
  const homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScreen(); // ← Solo devuelve MainScreen, sin MaterialApp
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  PageController _pageController = PageController();

  final List<Widget> _screens = [
    HomeScreen(),
    ProfileScreen(),
    SuscScreen(),
    InboxScreen(),
    SettingsScreen(),
  ];

  // ✅ MÉTODO HELPER PARA TRADUCIR
  String _translate(String text) {
    final currentLang = TranslationService().currentLanguage;

    // Traducciones manuales simples
    final translations = {
      'es': {
        'Inicio': 'Inicio',
        'Perfil': 'Perfil',
        'Suscribir': 'Suscribir',
        'Mensajes': 'Mensajes',
        'Ajustes': 'Ajustes',
      },
      'en': {
        'Inicio': 'Home',
        'Perfil': 'Profile',
        'Suscribir': 'Subscribe',
        'Mensajes': 'Messages',
        'Ajustes': 'Settings',
      },
    };

    return translations[currentLang]?[text] ?? text;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Si NO estás en Inicio (index 0)
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0; // Cambiar a Inicio
          });
          return false; // NO salir de la app
        }
        // Si YA estás en Inicio, permitir salir
        return true;
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Color(0xFF7C4C48),
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color.fromARGB(255, 63, 63, 63),
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: _translate('Inicio'), // ← TRADUCIDO
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: _translate('Perfil'), // ← TRADUCIDO
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 219, 85, 71),
                  borderRadius: BorderRadius.circular(80),
                ),
                child: Image.asset(
                  'assets/icons/adopcion3.png',
                  width: 28,
                  height: 28,
                ),
              ),
              label: _translate('Suscribir'), // ← TRADUCIDO
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: _translate('Mensajes'), // ← TRADUCIDO
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: _translate('Ajustes'), // ← TRADUCIDO
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TAMBIÉN TRADUCE ESTOS TEXTOS EN HomeScreen
// ============================================

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  late Future<List<PhotoPost>> _petsFuture;

  @override
  void initState() {
    super.initState();
    _petsFuture = PetService.fetchPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: Color(0xFFFE8043),
        onRefresh: () async {
          setState(() {
            _petsFuture = PetService.fetchPets();
          });
          await _petsFuture;
        },
        child: FutureBuilder<List<PhotoPost>>(
          future: _petsFuture,
          builder: (context, snapshot) {
            // CASO 1: Cargando
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFE8043)),
                    SizedBox(height: 16),
                    TranslatedText(
                      'Cargando mascotas...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }

            // CASO 2: Error
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    SizedBox(height: 16),
                    TranslatedText(
                      'Error al cargar mascotas',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '${snapshot.error}', // ← Error técnico, NO traducir
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _petsFuture = PetService.fetchPets();
                        });
                      },
                      child: TranslatedText('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFE8043),
                      ),
                    ),
                  ],
                ),
              );
            }

            // CASO 3: Sin datos
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, color: Colors.grey, size: 60),
                    SizedBox(height: 16),
                    TranslatedText(
                      'No hay mascotas disponibles',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            // CASO 4: Mostrar datos
            final posts = snapshot.data!;

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: null,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final actualIndex = index % posts.length; // ← AGREGA ESTA LÍNEA
                return PhotoPostWidget(
                  post: posts[actualIndex], // ← USA actualIndex
                  onLike: () =>
                      _toggleLike(posts, actualIndex), // ← USA actualIndex
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _toggleLike(List<PhotoPost> posts, int index) {
    setState(() {
      posts[index].isLiked = !posts[index].isLiked;
      if (posts[index].isLiked) {
        posts[index].likes++;
      } else {
        posts[index].likes--;
      }
      _petsFuture = Future.value(posts);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class PhotoPostWidget extends StatefulWidget {
  final PhotoPost post;
  final VoidCallback onLike;

  const PhotoPostWidget({Key? key, required this.post, required this.onLike})
    : super(key: key);

  @override
  _PhotoPostWidgetState createState() => _PhotoPostWidgetState();
}

class _PhotoPostWidgetState extends State<PhotoPostWidget> {
  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;
  late PageController _imagePageController;
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;
  String? _translatedDescription;
  List<Comment> _comments = [];
  bool _loadingComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likes;
    _commentsCount = widget.post.comments;
    _imagePageController = PageController();
    _loadDescription(); // ← AÑADIR ESTA LÍNEA
  }

  // ← AÑADIR ESTE MÉTODO COMPLETO
  Future<void> _loadDescription() async {
    final translated = await TranslationService().translate(
      widget.post.description,
    );
    if (mounted) {
      setState(() {
        _translatedDescription = translated;
      });
    }
  }

  @override
  void didUpdateWidget(PhotoPostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      setState(() {
        _currentImageIndex = 0;
      });
      _imagePageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Carrusel de imágenes
        widget.post.imageUrls.isNotEmpty
            ? GestureDetector(
                onPanUpdate: (details) {
                  if (details.delta.dx.abs() > details.delta.dy.abs()) {}
                },
                child: PageView.builder(
                  controller: _imagePageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.post.imageUrls.length,
                  physics: ClampingScrollPhysics(),
                  pageSnapping: true,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                      child: Center(
                        child: Image.network(
                          widget.post.imageUrls[index],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Color(0xFF7C4C48).withOpacity(0.5),
                              child: Center(
                                child: Icon(
                                  Icons.error,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFE8043),
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            : Container(
                color: Colors.grey[800],
                child: Center(
                  child: Icon(Icons.pets, color: Colors.white, size: 80),
                ),
              ),

        // Gradiente para mejorar legibilidad
        IgnorePointer(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xFF2A1617).withOpacity(0.3),
                  Color(0xFF2A1617).withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),

        // Indicadores de página (puntitos)
        if (widget.post.imageUrls.length > 1)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.post.imageUrls.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Color(0xFFFFFC98)
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),

        // Botones laterales
        Positioned(
          right: 12,
          bottom: 30,
          child: Column(
            children: [
              _buildActionButton(
                customIcon: Image.asset(
                  'assets/icons/adopcion2.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                label: _formatNumber(widget.post.adopcion),
                onTap: () => _adoptarPost(context),
              ),
              SizedBox(height: 10),
              _buildActionButton(
                customIcon: Image.asset(
                  'assets/icons/apoyar2.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                label: _formatNumber(widget.post.apoyo),
                onTap: () => _apoyarPost(context),
              ),
              SizedBox(height: 10),
              _buildActionButton(
                customIcon: Image.asset(
                  _isLiked ? 'assets/icons/like7.png' : 'assets/icons/like.png',
                  width: 55,
                  height: 55,
                  fit: BoxFit.contain,
                  color: _isLiked ? Color(0xFFB42C1C) : Colors.white,
                ),
                label: _formatNumber(_likesCount),
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                    _likesCount += _isLiked ? 1 : -1;
                  });

                  widget.post.isLiked = _isLiked;
                  widget.post.likes = _likesCount;
                },
              ),
              SizedBox(height: 10),
              _buildActionButton(
                customIcon: Image.asset(
                  'assets/icons/escribiendo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  color: Colors.white,
                ),
                label: _formatNumber(_commentsCount),
                onTap: () => _showComments(context, widget.post.id),
              ),
              SizedBox(height: 10),
              _buildActionButton(
                customIcon: Image.asset(
                  'assets/icons/compartir2.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  color: Colors.white,
                ),
                label: _formatNumber(widget.post.shares),
                onTap: _sharePostToWhatsApp,
              ),
            ],
          ),
        ),

        // Información del post
        Positioned(
          left: 12,
          bottom: 20,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.post.username}', // ← Nombre de usuario, NO traducir
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),

              // Descripción del post traducida
              Text(
                _translatedDescription ??
                    widget.post.description, // ← CAMBIO PRINCIPAL
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.justify,
                maxLines: _isDescriptionExpanded ? null : 3,
                overflow: _isDescriptionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (widget.post.description.length > 100)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Builder(
                      builder: (context) {
                        final isSpanish =
                            TranslationService().currentLanguage == 'es';
                        return Text(
                          _isDescriptionExpanded
                              ? (isSpanish ? 'Ver menos' : 'See less')
                              : (isSpanish ? 'Ver más' : 'See more'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    IconData? iconData,
    Widget? customIcon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    double iconSize = 30,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 45,
            height: 45,
            child: Center(
              child: customIcon ?? Icon(iconData, color: color, size: iconSize),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label, // ← Números (likes, shares, etc.), NO traducir
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showComments(BuildContext context, String petId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          // Cargar comentarios solo una vez
          Future.microtask(() {
            if (_comments.isEmpty && !_loadingComments) {
              _loadComments(petId);
            }
          });
          return Container(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                TranslatedText(
                  'Comentarios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Lista de comentarios
                _loadingComments
                    ? Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _comments.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(32),
                        child: TranslatedText(
                          'No hay comentarios aún. ¡Sé el primero!',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(
                        height: 300,
                        child: ListView.builder(
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _buildComment(
                              comment.username,
                              comment.content,
                            );
                          },
                        ),
                      ),

                SizedBox(height: 16),
                Divider(color: Colors.grey[700]),
                SizedBox(height: 8),

                // Campo para escribir comentario
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Escribe un comentario...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        maxLength: 500,
                        buildCounter:
                            (
                              context, {
                              required currentLength,
                              maxLength,
                              required isFocused,
                            }) {
                              return Text(
                                '$currentLength/$maxLength',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              );
                            },
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _sendComment(petId, setModalState),
                      icon: Icon(Icons.send, color: Colors.blue),
                      tooltip: 'Enviar',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      // Limpiar al cerrar el modal
      _commentController.clear();
    });
  }

  // ============================================
  // FUNCIÓN PARA CARGAR COMENTARIOS
  // ============================================
  Future<void> _loadComments(String petId) async {
    if (_loadingComments) return; // ← Evitar cargas duplicadas

    setState(() {
      _loadingComments = true;
    });

    try {
      final comments = await CommentService()
          .getCommentsByPet(petId)
          .timeout(
            Duration(seconds: 3), // ← Reducir a 3 segundos
            onTimeout: () => <Comment>[], // ← Retornar lista vacía en timeout
          );

      if (mounted) {
        setState(() {
          _comments = comments;
          _loadingComments = false;
        });
      }
    } catch (e) {
      print('Error cargando comentarios: $e');
      if (mounted) {
        setState(() {
          _comments = []; // ← Asegurar que quede vacío
          _loadingComments = false;
        });
      }
    }
  }

  // ============================================
  // FUNCIÓN PARA ENVIAR COMENTARIO
  // ============================================
  Future<void> _sendComment(String petId, StateSetter setModalState) async {
    final content = _commentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El comentario no puede estar vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final result = await CommentService().createComment(
        petId: petId,
        content: content,
      );

      if (result['success']) {
        // Limpiar el campo
        _commentController.clear();

        // Recargar comentarios
        await _loadComments(petId);

        // ✅ INCREMENTAR CONTADOR DE COMENTARIOS
        setState(() {
          _commentsCount++;
          widget.post.comments = _commentsCount; // Actualizar el post también
        });

        // Actualizar modal
        setModalState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comentario publicado ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al publicar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================
  // WIDGET DE COMENTARIO (mantener igual)
  // ============================================
  Widget _buildComment(String username, String comment) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 16),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(comment, style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sharePostToWhatsApp() async {
    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              TranslatedText('Preparando para compartir...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFFFE8043),
        ),
      );

      // Descargar la imagen
      final response = await http.get(Uri.parse(widget.post.imageUrls.first));

      if (response.statusCode != 200) {
        throw Exception('Error al descargar imagen');
      }

      // Guardar temporalmente
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/share_${widget.post.id}.jpg';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(response.bodyBytes);

      // Texto para compartir
      final text =
          '''
🐶 ¡Mira a ${widget.post.username}!

${widget.post.description.length > 100 ? '${widget.post.description.substring(0, 100)}...' : widget.post.description}

❤️ Descarga Wooheart App y ayúdanos a encontrarle un hogar.
''';

      // Compartir
      await Share.shareXFiles([XFile(imagePath)], text: text);

      // Limpiar archivo temporal después de 3 segundos
      Future.delayed(Duration(seconds: 3), () {
        if (imageFile.existsSync()) {
          imageFile.deleteSync();
        }
      });
    } catch (e) {
      debugPrint('Error al compartir: $e');

      // Mostrar error al usuario
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('No se pudo compartir. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _apoyarPost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdoptarScreen()),
    );
  }

  void _adoptarPost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CrearScreen()),
    );
  }
}

// Pantalla de Descubrir
class DiscoverScreen extends StatelessWidget {
  final List<String> categories = [
    'Tendencias',
    'Fotografía',
    'Naturaleza',
    'Comida',
    'Arte',
    'Viajes',
  ];

  //pantalla crear original (descubrir)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Descubrir', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF7C4C48),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar...',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),

          // Categorías
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  child: Chip(
                    label: Text(categories[index]),
                    backgroundColor: Colors.grey[800],
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),

          // Grid de fotos
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              'Foto ${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(index + 1) * 123} likes',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//pantalla adoptar
class CrearScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 36),

            // Logo
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFE8043).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/icons/adopcion.png',
                width: 70,
                height: 70,
              ),
            ),
            const SizedBox(height: 16),

            // Título principal
            TranslatedText(
              'Wooheart Adoptar',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A1617),
              ),
            ),
            const SizedBox(height: 8),

            // Subtítulo
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFE8043),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TranslatedText(
                '🏡 COMPROMISO MENSUAL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Descripción principal
            TranslatedText(
              '¡Conviértete en el héroe permanente de una vida!\n\n'
              'Al adoptar mensualmente, no solo cambias una vida, '
              'te conviertes en su familia. Cada mes recibirás actualizaciones '
              'exclusivas, fotos y videos de tu ahijado/a.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Beneficios exclusivos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C4C48), Color(0xFF2A1617)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  TranslatedText(
                    '✨ BENEFICIOS EXCLUSIVOS ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBenefit(
                    '📸 Álbum mensual personalizado de tu ahijado/a',
                  ),
                  _buildBenefit('🎥 Videos exclusivos de progreso'),
                  _buildBenefit('📧 Cartas virtuales mensuales'),
                  _buildBenefit('🏆 Certificado digital de adopción'),
                  _buildBenefit('💝 Regalo de cumpleaños para tu ahijado/a'),
                  _buildBenefit('👥 Acceso a grupo VIP de adoptantes'),
                  _buildBenefit('🎟️ Invitación a eventos especiales'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Título de planes
            TranslatedText(
              'ELIGE TU PLAN MENSUAL',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A1617),
              ),
            ),
            const SizedBox(height: 4),
            TranslatedText(
              'Cancela cuando quieras, sin compromiso',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Planes de suscripción
            _buildPlanCard(
              title: 'Plan Guardián',
              price: '5',
              description: 'Ideal para comenzar',
              benefits: [
                'Actualización mensual',
                'Fotos exclusivas',
                'Certificado digital',
              ],
              color: Color(0xFF9C27B0),
              isPopular: false,
            ),

            _buildPlanCard(
              title: 'Plan Protector',
              price: '10',
              description: 'El más popular',
              benefits: [
                'Todo del Plan Guardián',
                'Videos mensuales',
                'Cartas personalizadas',
                'Acceso grupo VIP',
              ],
              color: Color(0xFFFE8043),
              isPopular: true,
            ),

            _buildPlanCard(
              title: 'Plan Ángel',
              price: '20',
              description: 'Máximo impacto',
              benefits: [
                'Todo del Plan Protector',
                'Video llamada trimestral',
                'Regalo de cumpleaños',
                'Visita presencial anual',
                'Álbum físico de fin de año',
              ],
              color: Color(0xFFB42C1C),
              isPopular: false,
            ),

            const SizedBox(height: 24),

            // Testimonio visual
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TranslatedText(
                    '💬 Testimonio de adoptante',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/icons/mapache.jpg',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TranslatedText(
                            '"Adopté a Luna hace 6 meses y cada día recibo su amor en fotos. ¡Es parte de mi familia ahora!"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TranslatedText(
                    '- María González, Plan Protector',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nota final
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFFE8043), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.favorite, color: Color(0xFFB42C1C), size: 32),
                  const SizedBox(height: 8),
                  TranslatedText(
                    'Tu compromiso mensual significa un hogar seguro, comida diaria y atención veterinaria constante.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFFFE8043), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TranslatedText(
              text,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String description,
    required List<String> benefits,
    required Color color,
    required bool isPopular,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? color : Colors.grey.shade300,
          width: isPopular ? 3 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // Header del plan
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Column(
              children: [
                if (isPopular)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TranslatedText(
                      '⭐ MÁS POPULAR',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isPopular) const SizedBox(height: 8),
                TranslatedText(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                TranslatedText(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$', // ← Símbolo, NO traducir
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      price, // ← Precio, NO traducir
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: TranslatedText(
                        ' USD/mes',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Beneficios
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ...benefits.map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TranslatedText(
                            benefit,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botón de acción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: TranslatedText(
                      'Adoptar Ahora',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//pantalla apoyar
class AdoptarScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 36),

            // Logo
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFE8043).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/icons/apoyar.png',
                width: 70,
                height: 70,
              ),
            ),
            const SizedBox(height: 16),

            // Título principal
            TranslatedText(
              'WooHeart Apoyar',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A1617),
              ),
            ),
            const SizedBox(height: 8),

            // Subtítulo
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFE8043),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TranslatedText(
                '❤️ APOYO ÚNICO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Descripción principal
            // Mensaje motivacional final
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFFE8043).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.favorite, color: Color(0xFFB42C1C), size: 40),
                  const SizedBox(height: 12),
                  TranslatedText(
                    '¿Quieres ser parte de esta cadena de amor?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A1617),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TranslatedText(
                    'Tu contribución, sin importar el monto, marca una diferencia REAL en la vida de quien más lo necesita.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Título de opciones
            TranslatedText(
              'ELIGE TU APORTE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A1617),
              ),
            ),
            const SizedBox(height: 4),
            TranslatedText(
              'Pago único - Sin mensualidades',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Otro monto
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFFE8043), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TranslatedText(
                    '💝 ¿Monto?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      suffixText: 'USD',
                      hintText: TranslationService().currentLanguage == 'en'
                          ? 'Enter your amount'
                          : 'Ingresa tu monto',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color(0xFFFE8043),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFE8043),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: TranslatedText(
                        'Contribuir Ahora',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nota de transparencia
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      '100% de tu donación va directamente a ayudar',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImpact(String amount, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFFE8043),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              amount, // ← Número/monto, NO traducir
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TranslatedText(
              description,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGift(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFFFE8043), size: 18),
          const SizedBox(width: 8),
          Expanded(child: TranslatedText(text, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildContributionCard({
    required String amount,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    bool isRecommended = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecommended ? color : Colors.grey.shade300,
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: isRecommended
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TranslatedText(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TranslatedText(
                                'RECOMENDADO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      TranslatedText(
                        description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      '\$$amount', // ← Monto, NO traducir
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'USD', // ← Moneda, NO traducir
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//pantalla suscribir
class SuscScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 36),

            // Logo
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFE8043).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/icons/adopcion3.png',
                width: 70,
                height: 70,
              ),
            ),
            const SizedBox(height: 16),

            // Título principal
            TranslatedText(
              'WooHeart suscribir',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A1617),
              ),
            ),
            const SizedBox(height: 8),

            // Subtítulo
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFE8043),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TranslatedText(
                'COMPROMISO MENSUAL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Descripción principal
            TranslatedText(
              'Susucribete y "Cada mes, recibirás una tarjeta virtual con el rostro de quien ayudaste: un perrito que ahora tiene alimento, un gatito con un refugio cálido, o una persona que recuperó esperanza. No es solo un recuerdo... es la prueba de que tu suscripción silenciosa cambia vidas. ¿Quieres ser parte de esta cadena de amor?"',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 15, height: 1.5),
            ),

            // // Impacto inmediato
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [Color(0xFF7C4C48), Color(0xFF2A1617)],
            //     ),
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   child: Column(
            //     children: [
            //       TranslatedText(
            //         '🌟 TU IMPACTO INMEDIATO',
            //         style: TextStyle(
            //           color: Colors.white,
            //           fontWeight: FontWeight.bold,
            //           fontSize: 16,
            //         ),
            //       ),
            //       const SizedBox(height: 16),
            //       _buildImpact(
            //         'Con \$2 USD',
            //         'Alimentas a un perrito por 1 día',
            //       ),
            //       _buildImpact('Con \$5 USD', 'Cubres vacunas básicas'),
            //       _buildImpact('Con \$10 USD', 'Provees refugio por 1 semana'),
            //       _buildImpact(
            //         'Con \$15 USD',
            //         'Atiendes una emergencia veterinaria menor',
            //       ),
            //       _buildImpact(
            //         'Con \$30 USD',
            //         'Rescatas y cuidas a un animal por 1 mes',
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 24),

            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Color(0xFFF5F5F5),
            //     borderRadius: BorderRadius.circular(16),
            //     border: Border.all(
            //       color: Color(0xFFFE8043).withOpacity(0.3),
            //       width: 2,
            //     ),
            //   ),
            //   child: Column(
            //     children: [
            //       Icon(Icons.card_giftcard, color: Color(0xFFFE8043), size: 40),
            //       const SizedBox(height: 12),
            //       TranslatedText(
            //         'Con tu apoyo recibirás:',
            //         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            //       ),
            //       const SizedBox(height: 12),
            //       _buildGift('📧 Tarjeta virtual de agradecimiento'),
            //       _buildGift('📸 Foto del peludito que ayudaste'),
            //       _buildGift('💌 Mensaje personalizado de impacto'),
            //       _buildGift('🎖️ Insignia digital de colaborador'),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 24),

            // Título de opciones
            TranslatedText(
              'ELIGE TU APORTE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A1617),
              ),
            ),
            const SizedBox(height: 4),
            TranslatedText(
              'Pago único - Sin mensualidades',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Opciones de contribución
            _buildContributionCard(
              amount: '5',
              title: 'Granito de arena',
              description: 'Alimenta a un peludito por 1 dia',
              icon: Icons.restaurant,
              color: Color(0xFF9C27B0),
            ),
            _buildContributionCard(
              amount: '10',
              title: 'Luz de esperanza',
              description: 'Alimenta a un peludito por 2 dia',
              icon: Icons.restaurant,
              color: Color(0xFF9C27B0),
            ),
            _buildContributionCard(
              amount: '60',
              title: 'Angel de la guarda',
              description: 'Alimenta a un peludito por 12 dia',
              icon: Icons.restaurant,
              color: Color(0xFF9C27B0),
            ),
            _buildContributionCard(
              amount: '150',
              title: 'Corazon dorado',
              description: 'Alimenta a un peludito por 30 dia',
              icon: Icons.restaurant,
              color: Color(0xFF9C27B0),
            ),

            const SizedBox(height: 24),

            // Otro monto
            // Container(
            //   padding: EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     border: Border.all(color: Color(0xFFFE8043), width: 2),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Column(
            //     children: [
            //       TranslatedText(
            //         '💝 ¿Otro monto?',
            //         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            //       ),
            //       const SizedBox(height: 12),
            //       TextField(
            //         keyboardType: TextInputType.number,
            //         decoration: InputDecoration(
            //           prefixText: '\$ ',
            //           suffixText: 'USD',
            //           hintText: TranslationService().currentLanguage == 'en'
            //               ? 'Enter your amount'
            //               : 'Ingresa tu monto',
            //           border: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //           focusedBorder: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(8),
            //             borderSide: BorderSide(
            //               color: Color(0xFFFE8043),
            //               width: 2,
            //             ),
            //           ),
            //         ),
            //       ),
            //       const SizedBox(height: 12),
            //       SizedBox(
            //         width: double.infinity,
            //         child: ElevatedButton(
            //           onPressed: () {},
            //           style: ElevatedButton.styleFrom(
            //             backgroundColor: Color(0xFFFE8043),
            //             foregroundColor: Colors.white,
            //             padding: EdgeInsets.symmetric(vertical: 16),
            //             shape: RoundedRectangleBorder(
            //               borderRadius: BorderRadius.circular(12),
            //             ),
            //           ),
            //           child: TranslatedText(
            //             'Contribuir Ahora',
            //             style: TextStyle(
            //               fontSize: 16,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // const SizedBox(height: 24),

            // Testimonio visual
            // Container(
            //   padding: EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Color(0xFFF5F5F5),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Column(
            //     children: [
            //       TranslatedText(
            //         '💬 Historia de impacto',
            //         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            //       ),
            //       const SizedBox(height: 12),
            //       Stack(
            //         children: [
            //           ClipRRect(
            //             borderRadius: BorderRadius.circular(12),
            //             child: Image.asset(
            //               'assets/icons/mapache.jpg',
            //               width: double.infinity,
            //               height: 200,
            //               fit: BoxFit.cover,
            //             ),
            //           ),
            //           Positioned(
            //             bottom: 10,
            //             left: 10,
            //             right: 10,
            //             child: Container(
            //               padding: EdgeInsets.all(12),
            //               decoration: BoxDecoration(
            //                 color: Colors.black.withOpacity(0.7),
            //                 borderRadius: BorderRadius.circular(8),
            //               ),
            //               child: TranslatedText(
            //                 '"Gracias a tu apoyo, Max comió hoy y tiene un hogar temporal seguro"',
            //                 textAlign: TextAlign.center,
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontSize: 13,
            //                   fontStyle: FontStyle.italic,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),

            // const SizedBox(height: 24),

            // Nota de transparencia
            // Container(
            //   padding: EdgeInsets.all(12),
            //   decoration: BoxDecoration(
            //     border: Border.all(color: Colors.grey.shade300),
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   child: Row(
            //     children: [
            //       Icon(Icons.verified, color: Color(0xFF4CAF50), size: 20),
            //       const SizedBox(width: 8),
            //       Expanded(
            //         child: TranslatedText(
            //           '100% de tu donación va directamente a ayudar',
            //           style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImpact(String amount, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFFE8043),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              amount, // Mantener sin traducir porque incluye montos
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TranslatedText(
              description,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGift(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFFFE8043), size: 18),
          const SizedBox(width: 8),
          Expanded(child: TranslatedText(text, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildContributionCard({
    required String amount,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    bool isRecommended = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecommended ? color : Colors.grey.shade300,
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: isRecommended
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TranslatedText(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TranslatedText(
                                'RECOMENDADO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      TranslatedText(
                        description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      '\$$amount', // Mantener sin traducir (es un monto)
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'USD', // Mantener sin traducir (código de moneda)
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Pantalla de Mensajes
class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final MessagingService _messagingService = MessagingService();
  final SocketService _socketService = SocketService();

  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupSocket();
  }

  void _loadConversations() async {
    try {
      final conversations = await _messagingService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar conversaciones: $e')),
        );
      }
    }
  }

  void _setupSocket() {
    _socketService.connect();

    _socketService.onNewMessage = (data) {
      _loadConversations();
    };
  }

  void _openChat(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversation.id,
          otherUser: conversation.otherUser,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  void _openUserSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserSearchScreen()),
    ).then((_) => _loadConversations());
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Bandeja de entrada',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFE8043)),
            )
          : _conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes conversaciones aún',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón + para empezar',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFFFE8043),
              onRefresh: () async => _loadConversations(),
              child: ListView.separated(
                itemCount: _conversations.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.grey, height: 1),
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            conversation.otherUser.avatar,
                          ),
                          backgroundColor: const Color(0xFFFE8043),
                        ),
                        if (conversation.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${conversation.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      conversation.otherUser.name,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    trailing: Text(
                      _formatTime(conversation.lastMessageTime),
                      style: TextStyle(
                        color: conversation.unreadCount > 0
                            ? const Color(0xFFFE8043)
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => _openChat(conversation),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFE8043),
        onPressed: _openUserSearch,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _socketService.clearCallbacks();
    super.dispose();
  }
}

// Pantalla de Perfil
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;
  String _username = 'Usuario';
  String _email = '';
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLikesCount();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadLikesCount();
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    setState(() {
      _username = authService.username ?? 'Usuario';
      _email = authService.email ?? '';
    });
  }

  Future<void> _loadLikesCount() async {
    try {
      final posts = await PetService.fetchPets();
      final totalLikes = posts.where((post) => post.isLiked).length;

      setState(() {
        _likesCount = totalLikes;
      });
    } catch (e) {
      setState(() {
        _likesCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadLikesCount();
        },
        child: Column(
          children: [
            // Header del perfil
            Container(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  SizedBox(height: 36),
                  Icon(
                    Icons.person_outline_outlined,
                    color: Colors.black,
                    size: 50,
                  ),
                  SizedBox(height: 16),

                  Text(
                    '$_username', // ← Username NO se traduce (es nombre propio)
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  // ✅ TEXTO TRADUCIDO
                  TranslatedText(
                    'Amante de los animales 🐶',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 75, 75, 75),
                    ),
                  ),

                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('456', '🐕‍🦺 Apoyos'),
                      _buildStatColumn('$_likesCount', '🫶 Me encanta'),
                    ],
                  ),
                  SizedBox(height: 18),
                  TranslatedText(
                    '🌟 "¿Listo para marcar la diferencia? Con [Monto]/mes apoyás a quien más lo necesita.\n',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 75, 75, 75),
                    ),
                  ),
                  TranslatedText(
                    'Recibirás una tarjeta de impacto mensual con lo que ayudaste\n❤️ Tu aporte cambia vidas.\n¡Sumate Hoy!',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 75, 75, 75),
                    ),
                  ),
                ],
              ),
            ),

            // Botones de categorías
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryButton(
                    index: 0,
                    icon: Icons.check_circle,
                    label: 'Adoptados',
                  ),
                  _buildCategoryButton(
                    index: 1,
                    icon: Icons.volunteer_activism,
                    label: 'Apoyo',
                  ),
                  _buildCategoryButton(
                    index: 4,
                    icon: Icons.thumb_up,
                    label: 'Likes',
                  ),
                ],
              ),
            ),

            // Grid de posts del usuario
            Expanded(
              child: _selectedTab == 4
                  ? FutureBuilder<List<PhotoPost>>(
                      future: PetService.fetchPets(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFE8043),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return Center(
                            child: TranslatedText('No hay posts disponibles'),
                          );
                        }

                        final likedPosts = snapshot.data!
                            .where((post) => post.isLiked)
                            .toList();

                        if (likedPosts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                TranslatedText('Aún no tienes posts favoritos'),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: EdgeInsets.all(2),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                          itemCount: likedPosts.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              likedPosts[index].imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: Icon(Icons.error, color: Colors.white),
                                );
                              },
                            );
                          },
                        );
                      },
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(2),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: _getItemCount(),
                      itemBuilder: (context, index) {
                        return Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFFFE8043) : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          SizedBox(height: 4),
          // ✅ CAMBIO: Usar TranslatedText aquí
          TranslatedText(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Color(0xFFFE8043) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  int _getItemCount() {
    switch (_selectedTab) {
      case 0:
        return 15; // Todos
      case 1:
        return 8; // Ahijados
      case 2:
        return 5; // Adoptados
      case 3:
        return 12; // Apoyo
      case 4:
        return 20; // Likes
      default:
        return 0;
    }
  }

  Widget _buildStatColumn(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        // ✅ CAMBIO: Usar TranslatedText aquí también
        TranslatedText(
          label,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}

//pantalla ajustes
class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: TranslatedText(
          'Ajustes',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // CUENTA
          ListTile(
            leading: Icon(Icons.person, color: Colors.black54),
            title: TranslatedText("Cuenta"),
            subtitle: TranslatedText("Actualizar información personal"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountScreen()),
              );
            },
          ),
          const Divider(),

          // NOTIFICACIONES
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.black54),
            title: TranslatedText("Notificaciones"),
            subtitle: TranslatedText("Administrar notificaciones"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),
          const Divider(),

          // IDIOMA
          ListTile(
            leading: Icon(Icons.language, color: Colors.black54),
            title: TranslatedText("Idioma"),
            subtitle: TranslatedText("Seleccionar idioma"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LanguageSelectionScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // AYUDA
          ListTile(
            leading: Icon(Icons.help_outline, color: Colors.black54),
            title: TranslatedText("Ayuda"),
            subtitle: TranslatedText("Centro de soporte"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpScreen()),
              );
            },
          ),
          const Divider(),

          // CERRAR SESIÓN
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: TranslatedText(
              "Cerrar sesión",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              // Mostrar diálogo de confirmación
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: TranslatedText('Cerrar sesión'),
                  content: TranslatedText(
                    '¿Estás seguro que deseas cerrar sesión?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: TranslatedText('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: TranslatedText(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // Cerrar sesión
                await AuthService().logout();

                if (context.mounted) {
                  // Ir al login y eliminar todas las rutas
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/loginScreen', (route) => false);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    // Cargar datos del usuario desde AuthService
    final user = await AuthService().getCurrentUser();
    if (user != null) {
      setState(() {
        _nombreController.text = user['username'] ?? '';
        _emailController.text = user['email'] ?? '';
        _celularController.text = user['phone'] ?? '';
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().updateProfile(
        name: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        phone: _celularController.text.trim(),
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Información actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditing = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al actualizar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: TranslatedText(
          'Cuenta',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFFFE8043)),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Color(0xFFFE8043).withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFFFE8043),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFFE8043),
                          child: IconButton(
                            icon: Icon(Icons.camera_alt, size: 20),
                            color: Colors.white,
                            onPressed: () {
                              // Cambiar foto de perfil
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Nombre
              TextFormField(
                controller: _nombreController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  label: TranslatedText('Nombre completo'),
                  prefixIcon: Icon(Icons.person, color: Color(0xFFFE8043)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFFE8043), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  label: TranslatedText('Correo electrónico'),
                  prefixIcon: Icon(Icons.email, color: Color(0xFFFE8043)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFFE8043), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El correo es requerido';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Celular
              TextFormField(
                controller: _celularController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  label: TranslatedText('Número de celular'),
                  prefixIcon: Icon(Icons.phone, color: Color(0xFFFE8043)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFFE8043), width: 2),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Botones
              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _cargarDatos();
                          setState(() => _isEditing = false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: TranslatedText('Cancelar'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _guardarCambios,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFE8043),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : TranslatedText(
                                'Guardar',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 24),

              // Cambiar contraseña
              ListTile(
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(Icons.lock, color: Color(0xFFFE8043)),
                title: TranslatedText('Cambiar contraseña'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navegar a cambiar contraseña
                  showDialog(
                    context: context,
                    builder: (context) => _CambiarPasswordDialog(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    super.dispose();
  }
}

// Diálogo para cambiar contraseña
class _CambiarPasswordDialog extends StatefulWidget {
  @override
  State<_CambiarPasswordDialog> createState() => _CambiarPasswordDialogState();
}

class _CambiarPasswordDialogState extends State<_CambiarPasswordDialog> {
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: TranslatedText('Cambiar contraseña'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _actualController,
            obscureText: _obscureActual,
            decoration: InputDecoration(
              label: TranslatedText('Contraseña actual'),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureActual ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureActual = !_obscureActual),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _nuevaController,
            obscureText: _obscureNueva,
            decoration: InputDecoration(
              label: TranslatedText('Nueva contraseña'),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNueva ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureNueva = !_obscureNueva),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _confirmarController,
            obscureText: _obscureConfirmar,
            decoration: InputDecoration(
              label: TranslatedText('Confirmar contraseña'),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmar ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirmar = !_obscureConfirmar),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: TranslatedText('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Validar campos
            if (_actualController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: TranslatedText('Ingresa tu contraseña actual'),
                ),
              );
              return;
            }

            if (_nuevaController.text.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: TranslatedText(
                    'La contraseña debe tener al menos 6 caracteres',
                  ),
                ),
              );
              return;
            }

            if (_nuevaController.text != _confirmarController.text) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: TranslatedText('Las contraseñas no coinciden'),
                ),
              );
              return;
            }

            // Cambiar contraseña
            final result = await AuthService().changePassword(
              currentPassword: _actualController.text,
              newPassword: _nuevaController.text,
            );

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Contraseña actualizada'),
                backgroundColor: result['success'] ? Colors.green : Colors.red,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFE8043)),
          child: TranslatedText(
            'Cambiar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ============================================
// 2. PANTALLA DE NOTIFICACIONES
// ============================================
class NotificationsScreen extends StatefulWidget {
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _todasNotificaciones = true;
  bool _notifMascotas = true;
  bool _notifEventos = true;
  bool _notifPromociones = false;
  bool _notifMensajes = true;
  bool _sonido = true;
  bool _vibracion = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: TranslatedText(
          'Notificaciones',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Activar todas
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: _todasNotificaciones,
              onChanged: (value) {
                setState(() {
                  _todasNotificaciones = value;
                  if (!value) {
                    _notifMascotas = false;
                    _notifEventos = false;
                    _notifPromociones = false;
                    _notifMensajes = false;
                  }
                });
              },
              title: TranslatedText(
                'Activar todas las notificaciones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: TranslatedText('Recibir todas las notificaciones'),
              activeColor: Color(0xFFFE8043),
            ),
          ),

          SizedBox(height: 24),

          TranslatedText(
            'Tipos de notificaciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),

          SizedBox(height: 12),

          // Notificaciones de mascotas
          _buildNotificationTile(
            icon: Icons.pets,
            title: 'Mascotas',
            subtitle: 'Recordatorios de cuidados y salud',
            value: _notifMascotas,
            onChanged: (value) => setState(() => _notifMascotas = value),
          ),

          SizedBox(height: 8),

          // Notificaciones de eventos
          _buildNotificationTile(
            icon: Icons.event,
            title: 'Eventos',
            subtitle: 'Eventos y actividades cercanas',
            value: _notifEventos,
            onChanged: (value) => setState(() => _notifEventos = value),
          ),

          SizedBox(height: 8),

          // Notificaciones de promociones
          _buildNotificationTile(
            icon: Icons.local_offer,
            title: 'Promociones',
            subtitle: 'Ofertas y descuentos especiales',
            value: _notifPromociones,
            onChanged: (value) => setState(() => _notifPromociones = value),
          ),

          SizedBox(height: 8),

          // Notificaciones de mensajes
          _buildNotificationTile(
            icon: Icons.message,
            title: 'Mensajes',
            subtitle: 'Mensajes y chats',
            value: _notifMensajes,
            onChanged: (value) => setState(() => _notifMensajes = value),
          ),

          SizedBox(height: 24),

          TranslatedText(
            'Configuración de alertas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),

          SizedBox(height: 12),

          // Sonido
          _buildNotificationTile(
            icon: Icons.volume_up,
            title: 'Sonido',
            subtitle: 'Reproducir sonido de notificación',
            value: _sonido,
            onChanged: (value) => setState(() => _sonido = value),
          ),

          SizedBox(height: 8),

          // Vibración
          _buildNotificationTile(
            icon: Icons.vibration,
            title: 'Vibración',
            subtitle: 'Vibrar al recibir notificaciones',
            value: _vibracion,
            onChanged: (value) => setState(() => _vibracion = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: Color(0xFFFE8043)),
        title: TranslatedText(title),
        subtitle: TranslatedText(subtitle),
        activeColor: Color(0xFFFE8043),
      ),
    );
  }
}

// ============================================
// 3. PANTALLA DE AYUDA/SOPORTE
// ============================================

class HelpScreen extends StatelessWidget {
  final String whatsappNumber = '59169713273'; // Cambia por tu número
  final String email = 'soporte@ohanas.com'; // Cambia por tu email

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: TranslatedText(
          'Ayuda y Soporte',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Header con icono
          Center(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFFE8043).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.support_agent,
                    size: 60,
                    color: Color(0xFFFE8043),
                  ),
                ),
                SizedBox(height: 16),
                TranslatedText(
                  '¿En qué podemos ayudarte?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TranslatedText(
                  'Estamos aquí para resolver tus dudas',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // WhatsApp
          _buildContactCard(
            icon: Icons.send_rounded,
            iconColor: Color(0xFF25D366),
            title: 'WhatsApp',
            subtitle: 'Chatea con nosotros',
            onTap: () => _abrirWhatsApp("59169713273"),
          ),

          SizedBox(height: 12),

          // Email
          _buildContactCard(
            icon: Icons.email,
            iconColor: Color(0xFFFE8043),
            title: 'Correo electrónico',
            subtitle: email,
            onTap: () => _abrirEmail(email),
          ),

          SizedBox(height: 12),

          // Chat en vivo (opcional)
          _buildContactCard(
            icon: Icons.chat_bubble,
            iconColor: Colors.blue,
            title: 'Chat en vivo',
            subtitle: 'Habla con un agente ahora',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LiveChatScreen()),
              );
            },
          ),

          SizedBox(height: 32),

          // Preguntas frecuentes
          TranslatedText(
            'Preguntas frecuentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 12),

          _buildFAQTile(
            question: '¿Cómo cambiar mi contraseña?',
            answer:
                'Ve a Ajustes > Cuenta > Cambiar contraseña. Ingresa tu contraseña actual y la nueva contraseña.',
          ),

          _buildFAQTile(
            question: '¿Cómo desactivar las notificaciones?',
            answer:
                'Ve a Ajustes > Notificaciones y desactiva las notificaciones que no desees recibir.',
          ),

          _buildFAQTile(
            question: '¿Cómo eliminar mi cuenta?',
            answer:
                'Contacta con soporte para solicitar la eliminación de tu cuenta. Ten en cuenta que esta acción es irreversible.',
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: TranslatedText(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: TranslatedText(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildFAQTile({required String question, required String answer}) {
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 8),
      title: TranslatedText(
        question,
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: TranslatedText(
            answer,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Future<void> _abrirWhatsApp(String numero) async {
    final mensaje = Uri.encodeComponent('Hola, necesito ayuda con Wooheart');
    final url = Uri.parse('https://wa.me/$numero?text=$mensaje');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _abrirEmail(String email) async {
    final subject = Uri.encodeComponent('Soporte Ohanas');
    final body = Uri.encodeComponent('Hola, necesito ayuda con...');
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ============================================
// 4. PANTALLA DE CHAT EN VIVO (SIMPLE)
// ============================================
class LiveChatScreen extends StatefulWidget {
  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final _mensajeController = TextEditingController();
  final List<Map<String, dynamic>> _mensajes = [];

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida
    _mensajes.add({
      'texto':
          '¡Hola! Soy el asistente virtual de Ohanas. ¿En qué puedo ayudarte?',
      'esUsuario': false,
      'hora': TimeOfDay.now(),
    });
  }

  void _enviarMensaje() {
    if (_mensajeController.text.trim().isEmpty) return;

    setState(() {
      _mensajes.add({
        'texto': _mensajeController.text,
        'esUsuario': true,
        'hora': TimeOfDay.now(),
      });
    });

    // Simular respuesta automática
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _mensajes.add({
          'texto': 'Gracias por tu mensaje. Un agente te responderá pronto.',
          'esUsuario': false,
          'hora': TimeOfDay.now(),
        });
      });
    });

    _mensajeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFFFE8043),
        title: TranslatedText(
          'Chat en vivo',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _mensajes.length,
              itemBuilder: (context, index) {
                final mensaje = _mensajes[index];
                return _buildMensaje(
                  mensaje['texto'],
                  mensaje['esUsuario'],
                  mensaje['hora'],
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Color(0xFFFE8043),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _enviarMensaje,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMensaje(String texto, bool esUsuario, TimeOfDay hora) {
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: esUsuario ? Color(0xFFFE8043) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              texto,
              style: TextStyle(
                color: esUsuario ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${hora.hour}:${hora.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: esUsuario ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modelo de datos para los posts
class PhotoPost {
  final String id;
  final String username;
  final String description;
  final List<String> imageUrls; // <- CAMBIÓ: ahora es lista
  final String species; // <- NUEVO
  final String breed; // <- NUEVO
  final int age; // <- NUEVO
  final String adoptionStatus; // <- NUEVO
  int adopcion;
  int apoyo;
  int likes;
  int comments;
  final int shares;
  bool isLiked;

  PhotoPost({
    required this.id,
    required this.username,
    required this.description,
    required this.imageUrls, // <- CAMBIÓ
    required this.species,
    required this.breed,
    required this.age,
    required this.adoptionStatus,
    required this.adopcion,
    required this.apoyo,
    required this.likes,
    required this.comments,
    required this.shares,
    this.isLiked = false,
  });

  // Constructor para crear PhotoPost desde JSON del API
  factory PhotoPost.fromJson(Map<String, dynamic> json) {
    return PhotoPost(
      id: json['_id'] ?? '',
      username: json['name'] ?? 'Sin nombre',
      description: json['description'] ?? 'Sin descripción',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      species: json['species'] ?? 'unknown',
      breed: json['breed'] ?? 'unknown',
      age: json['age'] ?? 0,
      adoptionStatus: json['adoptionStatus'] ?? 'available',
      adopcion: 0,
      apoyo: 0,
      likes: 0,
      comments: 0,
      shares: 0,
      isLiked: false,
    );
  }
}
