import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:ohanas_app/services/auth_service.dart';
import 'package:ohanas_app/services/pet_service.dart'; // ✅ AGREGAR ESTA LÍNEA
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/like_notifier.dart';
import '../data/model/comment.dart';
import '../data/model/conversation.dart';
import '../data/model/pet_model.dart';
import '../services/comment_services.dart';
import '../services/messaging_service.dart';
import '../services/translation_cache.dart';
import '../utils/logger.dart';
import '../utils/formatters.dart';
import '../services/socket_service.dart';
import '../services/translation_service.dart';
import '../services/payment_service.dart';
import '../data/model/payment_history_service.dart'; // ← NUEVO
import '../data/model/payment_models.dart'; // ← NUEVO
import '../config/stripe_config.dart';
import '../config/app_colors.dart';
import '../widgets/language_selection_screen.dart';
import '../widgets/translated_text.dart';
import '../widgets/benefit_item.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';
import './profile/likes_screen.dart';
import './profile/adopted_pets_screen.dart';
import './profile/supported_pets_screen.dart';

// ignore: camel_case_types
class homepage extends StatelessWidget {
  const homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScreen(); // ← Solo devuelve MainScreen, sin MaterialApp
  }
}
// b30be4bc415c6d167cb99c8e62a18dfdb3e86079

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  // PageController _pageController = PageController();

  final List<Widget> _screens = [
    HomeScreen(),
    ProfileScreen(),
    SuscScreen(),
    InboxScreen(),
    SettingsScreen(),
  ];

  // ✅ AGREGAR ESTE MÉTODO COMPLETO AQUÍ
  Widget _getScreen(int index) {
    if (index == 1) {
      // Forzar rebuild de ProfileScreen cada vez que se selecciona
      return ProfileScreen(key: ValueKey(DateTime.now()));
    }
    return _screens[index];
  }

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
        body: _getScreen(_currentIndex),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.secondary, // ✅
          selectedItemColor: AppColors.textWhite, // ✅
          unselectedItemColor: AppColors.textDarkGrey, // ✅
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

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  // PageController _pageController = PageController();
  late PageController _pageController;
  int _currentPage = 0;

  late Future<List<PetModel>> _petsFuture;
  List<PetModel> _petsCache = [];
  static const int _maxCacheSize = 100;
  // ✅✅✅ AGREGAR ESTAS 3 LÍNEAS AQUÍ ✅✅✅

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadPets();
  }

  // ✅ NUEVO: Método para cargar y cachear mascotas
  void _loadPets() {
    Logger.info('Cargando mascotas desde el servidor...');
    _petsFuture = PetService.fetchPets();
    _petsFuture
        .then((pets) async {
          if (mounted) {
            setState(() {
              _petsCache = pets;
            });
            Logger.success('${pets.length} mascotas cargadas correctamente');

            // ✅ PRECACHEAR traducciones en background
            if (TranslationService().currentLanguage != 'es') {
              final descriptions = pets.map((p) => p.description).toList();
              TranslationCache()
                  .precacheDescriptions(descriptions)
                  .then((_) {
                    Logger.success('Traducciones precacheadas');
                  })
                  .catchError((e) {
                    Logger.warning('Error precacheando traducciones: $e');
                  });
            }
          }
        })
        .catchError((error) {
          Logger.error('Error al cargar mascotas', error);
        });
  }

  // ✅ NUEVO: Actualizar una mascota en el cache
  void _updatePetInCache(String petId, PetModel updatedPet) {
    setState(() {
      final index = _petsCache.indexWhere((pet) => pet.id == petId);
      if (index != -1) {
        _petsCache[index] = updatedPet;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          _loadPets(); // ✅ CAMBIO: Usar el método centralizado
          await _petsFuture;
        },
        child: FutureBuilder<List<PetModel>>(
          future: _petsFuture,
          builder: (context, snapshot) {
            // CASO 1: Cargando
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
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
                        backgroundColor: AppColors.primary,
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
            // CASO 4: Mostrar datos
            final posts = _petsCache.isNotEmpty ? _petsCache : snapshot.data!;

            // ✅ NUEVO: Calcular itemCount seguro
            // Permitimos 1000 repeticiones del feed (más que suficiente)
            final int? totalItems = null;

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: totalItems, // ← null = infinito
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                // ✅ OPTIMIZACIÓN: Módulo para ciclo infinito
                final actualIndex = index % posts.length;

                return PhotoPostWidget(
                  post: posts[actualIndex],
                  onLike: () => _toggleLike(actualIndex),
                  onCommentAdded: () {
                    final updatedPet = posts[actualIndex].copyWith(
                      comments: posts[actualIndex].comments + 1,
                    );
                    _updatePetInCache(posts[actualIndex].id, updatedPet);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _toggleLike(int index) async {
    if (_petsCache.isEmpty) return;

    final pet = _petsCache[index];
    final petId = pet.id;
    final previousLikes = pet.likes;
    final previousIsLiked = pet.isLiked;

    // Optimistic update en el cache
    final updatedPet = pet.copyWith(
      isLiked: !previousIsLiked,
      likes: previousIsLiked ? previousLikes - 1 : previousLikes + 1,
    );
    _updatePetInCache(petId, updatedPet);

    try {
      // Llamar al backend con timeout
      final result = await PetService.toggleLike(
        petId,
      ).timeout(Duration(seconds: 10));

      if (!result['success']) {
        // Revertir en el cache si falla
        final revertedPet = pet.copyWith(
          isLiked: previousIsLiked,
          likes: previousLikes,
        );
        _updatePetInCache(petId, revertedPet);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al dar like'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // ✅ CAMBIO PRINCIPAL: Recargar desde el servidor para garantizar persistencia
        try {
          final freshPets = await PetService.fetchPets();
          final freshPet = freshPets.firstWhere(
            (p) => p.id == petId,
            orElse: () => updatedPet,
          );

          // Actualizar con datos frescos del servidor
          _updatePetInCache(petId, freshPet);

          // Actualizar todo el cache con los datos frescos (opcional pero recomendado)
          if (mounted) {
            setState(() {
              // Actualizar solo los pets que cambiaron
              for (var freshPet in freshPets) {
                _updatePetInCache(freshPet.id, freshPet);
              }
            });
          }

          likeNotifier.notifyLikeChanged();
        } catch (e) {
          // Si falla la recarga, usar datos del response
          final serverLikesCount = result['likesCount'] ?? updatedPet.likes;
          final serverIsLiked = result['isLiked'] ?? updatedPet.isLiked;

          final syncedPet = pet.copyWith(
            isLiked: serverIsLiked,
            likes: serverLikesCount,
          );
          _updatePetInCache(petId, syncedPet);
          likeNotifier.notifyLikeChanged();
        }
      }
    } on TimeoutException {
      // Si tarda más de 10 segundos
      final revertedPet = pet.copyWith(
        isLiked: previousIsLiked,
        likes: previousLikes,
      );
      _updatePetInCache(petId, revertedPet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conexión lenta. Intenta de nuevo'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Cualquier otro error
      debugPrint('Error en toggleLike: $e');

      final revertedPet = pet.copyWith(
        isLiked: previousIsLiked,
        likes: previousLikes,
      );
      _updatePetInCache(petId, revertedPet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sin conexión. Revisa tu internet'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // ✅ FIX: Asegurar dispose seguro
    if (_pageController.hasClients) {
      _pageController.dispose();
    }
    _petsCache.clear();
    Logger.info('HomeScreen disposed correctamente');
    super.dispose();
  }
}

class PhotoPostWidget extends StatefulWidget {
  final PetModel post;
  final VoidCallback onLike;
  final VoidCallback? onCommentAdded; // ✅ NUEVO

  const PhotoPostWidget({
    Key? key,
    required this.post,
    required this.onLike,
    this.onCommentAdded, // ✅ NUEVO
  }) : super(key: key);

  @override
  _PhotoPostWidgetState createState() => _PhotoPostWidgetState();
}

class _PhotoPostWidgetState extends State<PhotoPostWidget> {
  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;
  late int _sharesCount;
  late PageController _imagePageController; // ✅ AGREGAR
  int _currentImageIndex = 0; // ✅ AGREGAR
  bool _isDescriptionExpanded = false; // ✅ AGREGAR
  String? _translatedDescription; // ✅ AGREGAR
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false; // ✅ AGREGAR
  final TextEditingController _commentController =
      TextEditingController(); // ✅ AGREGAR

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked; // ✅ CAMBIO
    _likesCount = widget.post.likes; // ✅ CAMBIO
    _commentsCount = widget.post.comments; // ✅ CAMBIO
    _sharesCount = widget.post.shares; // ✅ CAMBIO
    _imagePageController = PageController();
    _loadDescription(); // ← AÑADIR ESTA LÍNEA
  }

  // ← AÑADIR ESTE MÉTODO COMPLETO
  Future<void> _loadDescription() async {
    // ✅ USAR CACHE en vez de TranslationService directo
    final translated = await TranslationCache().translate(
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

    // ✅ OPTIMIZACIÓN: Actualizar SOLO lo que cambió
    bool needsUpdate = false;

    if (oldWidget.post.isLiked != widget.post.isLiked) {
      _isLiked = widget.post.isLiked;
      needsUpdate = true;
      Logger.info('Like actualizado: $_isLiked');
    }

    if (oldWidget.post.likes != widget.post.likes) {
      _likesCount = widget.post.likes;
      needsUpdate = true;
      Logger.info('Contador likes actualizado: $_likesCount');
    }

    if (oldWidget.post.comments != widget.post.comments) {
      _commentsCount = widget.post.comments;
      needsUpdate = true;
      Logger.info('Contador comments actualizado: $_commentsCount');
    }

    if (oldWidget.post.shares != widget.post.shares) {
      _sharesCount = widget.post.shares;
      needsUpdate = true;
      Logger.info('Contador shares actualizado: $_sharesCount');
    }

    // Solo hacer setState si ALGO cambió
    if (needsUpdate && mounted) {
      setState(() {});
    }

    // ✅ FIX MEMORY LEAK: Recrear PageController cuando cambia la mascota
    if (oldWidget.post.id != widget.post.id) {
      // 1. LIMPIAR el viejo controller
      _imagePageController.dispose();

      // 2. CREAR uno nuevo desde cero
      _imagePageController = PageController();

      // 3. Resetear índice
      _currentImageIndex = 0;

      // 4. Cargar nueva descripción
      _loadDescription();

      Logger.info(
        'PageController recreado para nueva mascota: ${widget.post.name}',
      );
    }
  }

  @override
  void dispose() {
    // ✅ FIX: Dispose seguro + limpieza completa
    if (_imagePageController.hasClients) {
      _imagePageController.dispose();
    }
    _commentController.dispose();

    // Limpiar listeners si existen
    _imagePageController.removeListener(() {});

    _comments.clear();

    Logger.info('PhotoPostWidget disposed: ${widget.post.name}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ AGREGAR ESTA LÍNEA AL INICIO
    final imageUrls = widget.post.imageUrls;

    return Stack(
      children: [
        // Carrusel de imágenes
        imageUrls
                .isNotEmpty // ✅ CAMBIO: usar imageUrls
            ? GestureDetector(
                onPanUpdate: (details) {
                  if (details.delta.dx.abs() > details.delta.dy.abs()) {}
                },
                child: PageView.builder(
                  controller: _imagePageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length, // ✅ CAMBIO
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
                        child: CachedNetworkImage(
                          imageUrl: imageUrls[index],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,

                          // Mientras carga
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3,
                            ),
                          ),

                          // Si hay error
                          errorWidget: (context, url, error) => Container(
                            color: Color(0xFF7C4C48).withOpacity(0.5),
                            child: Center(
                              child: Icon(
                                Icons.error,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
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
                  AppColors.darkBackgroundWithOpacity(0.3), // ✅
                  AppColors.darkBackgroundWithOpacity(0.8),
                ],
              ),
            ),
          ),
        ),

        // Indicadores de página (puntitos)
        if (imageUrls.length > 1) // ✅ CAMBIO
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length, // ✅ CAMBIO
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
                label: Formatters.formatNumber(widget.post.adopcion),
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
                label: Formatters.formatNumber(widget.post.apoyo), // ✅
                onTap: () => _apoyarPost(context),
              ),
              SizedBox(height: 10),
              _buildActionButton(
                customIcon: Image.asset(
                  _isLiked ? 'assets/icons/like7.png' : 'assets/icons/like.png',
                  width: 55,
                  height: 55,
                  fit: BoxFit.contain,
                  color: _isLiked ? AppColors.likeActive : AppColors.textWhite,
                ),
                label: Formatters.formatNumber(_likesCount),
                onTap: widget
                    .onLike, // ✅ CAMBIO SIMPLE: Llamar al callback del padre
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
                label: Formatters.formatNumber(_commentsCount),
                onTap: () => _showComments(context, widget.post.id), // ✅
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
                label: Formatters.formatNumber(_sharesCount), // ✅
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
                widget.post.name, // ✅ // ← Nombre de usuario, NO traducir
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),

              // Descripción del post traducida
              Text(
                _translatedDescription ?? widget.post.description,
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.justify,
                maxLines: _isDescriptionExpanded ? null : 3,
                overflow: _isDescriptionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (widget.post.description.length > 100) // ✅
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

  // String _formatNumber(int number) {
  //   if (number >= 1000000) {
  //     return '${(number / 1000000).toStringAsFixed(1)}M';
  //   } else if (number >= 1000) {
  //     return '${(number / 1000).toStringAsFixed(1)}K';
  //   }
  //   return number.toString();
  // }

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
                              comment['username'] ?? 'Usuario', // ✅
                              comment['content'] ?? '', // ✅
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
  // ============================================
  // BUSCA Y REEMPLAZA LA FUNCIÓN _loadComments COMPLETA
  // ============================================

  Future<void> _loadComments(String petId) async {
    if (_loadingComments) return;

    setState(() {
      _loadingComments = true;
    });

    try {
      final comments = await PetService.getComments(
        petId,
      ).timeout(Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _comments = comments;
          _loadingComments = false;
        });
      }
    } on TimeoutException {
      Logger.warning('Timeout al cargar comentarios');
      if (mounted) {
        setState(() {
          _comments = [];
          _loadingComments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La carga está tardando mucho'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error cargando comentarios', e);
      if (mounted) {
        setState(() {
          _comments = [];
          _loadingComments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron cargar los comentarios'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _loadComments(petId),
            ),
          ),
        );
      }
    }
  }

  /// ============================================
  // BUSCA Y REEMPLAZA LA FUNCIÓN _sendComment COMPLETA
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
      final result = await PetService.createComment(
        petId: petId,
        content: content,
      ).timeout(Duration(seconds: 15));

      if (result['success']) {
        _commentController.clear();

        final newCommentsCount = result['commentsCount'] ?? _commentsCount + 1;

        setState(() {
          _commentsCount = newCommentsCount;
        });

        await _loadComments(petId);
        widget.onCommentAdded?.call();

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
    } on TimeoutException {
      Logger.warning('Timeout al enviar comentario');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La conexión está tardando mucho'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      Logger.error('Error enviando comentario', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión. Intenta de nuevo'),
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

  // ============================================
  // BUSCA Y REEMPLAZA _sharePostToWhatsApp COMPLETA
  // ============================================

  void _sharePostToWhatsApp() async {
    final imageUrls = widget.post.imageUrls;

    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay imagen para compartir'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

    try {
      // Incrementar contador
      try {
        final shareResult = await PetService.incrementShare(
          widget.post.id,
        ).timeout(Duration(seconds: 5));

        if (shareResult['success']) {
          setState(() {
            _sharesCount = shareResult['shares'] ?? _sharesCount + 1;
          });
          Logger.success('Share incrementado correctamente');
        }
      } catch (e) {
        Logger.error('Error al incrementar share', e);
      }

      // Descargar imagen con timeout
      final response = await http
          .get(Uri.parse(imageUrls.first))
          .timeout(Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Error al descargar imagen (${response.statusCode})');
      }

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/share_${widget.post.id}.jpg';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(response.bodyBytes);

      final description = widget.post.description;
      final text =
          '''
🐶 ¡Mira a ${widget.post.name}!

${description.length > 100 ? '${description.substring(0, 100)}...' : description}

❤️ Descarga Wooheart App y ayúdanos a encontrarle un hogar.
''';

      await Share.shareXFiles([XFile(imagePath)], text: text);

      Future.delayed(Duration(seconds: 3), () {
        if (imageFile.existsSync()) {
          imageFile.deleteSync();
        }
      });
    } on TimeoutException {
      Logger.warning('Timeout al descargar imagen para compartir');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La descarga está tardando mucho'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } on SocketException {
      Logger.error('Sin conexión a internet al compartir');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sin conexión a internet'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al compartir: e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo compartir. Intenta de nuevo'),
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
      MaterialPageRoute(
        builder: (context) => CrearScreen(
          petId: widget.post.id, // ← AGREGAR
          petName: widget.post.name, // ← AGREGAR
          petImage: widget.post.imageUrls.isNotEmpty
              ? widget.post.imageUrls[0]
              : null, // ← AGREGAR
        ),
      ),
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
  final String? petId; // ← AGREGAR
  final String? petName; // ← AGREGAR
  final String? petImage; // ← AGREGAR

  const CrearScreen({
    Key? key,
    this.petId, // ← AGREGAR
    this.petName, // ← AGREGAR
    this.petImage, // ← AGREGAR
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 36),
            // ✅ AGREGAR: Mostrar nombre de la mascota si existe
            if (petName != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Adoptando a: $petName',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A1617),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Logo
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity(0.1),
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
                color: AppColors.primary,
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
                gradient: AppColors.darkGradient,
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
                  BenefitItem(
                    text: '📸 Álbum mensual personalizado de tu ahijado/a',
                  ),
                  BenefitItem(text: '🎥 Videos exclusivos de progreso'),
                  BenefitItem(text: '📧 Cartas virtuales mensuales'),
                  BenefitItem(text: '🏆 Certificado digital de adopción'),
                  BenefitItem(
                    text: '💝 Regalo de cumpleaños para tu ahijado/a',
                  ),
                  BenefitItem(text: '👥 Acceso a grupo VIP de adoptantes'),
                  BenefitItem(text: '🎟️ Invitación a eventos especiales'),
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
              context: context,
              priceId: StripeConfig.adoptarGuardian,
              title: 'Plan Guardián',
              price: '5',
              description: 'Ideal para comenzar',
              benefits: [
                'Actualización mensual',
                'Fotos exclusivas',
                'Certificado digital',
              ],
              color: AppColors.purple,
              isPopular: false,
              petId: petId, // ← AGREGAR
              petName: petName, // ← AGREGAR
            ),

            _buildPlanCard(
              context: context,
              priceId: StripeConfig.adoptarProtector,
              title: 'Plan Protector',
              price: '10',
              description: 'El más popular',
              benefits: [
                'Todo del Plan Guardián',
                'Videos mensuales',
                'Cartas personalizadas',
                'Acceso grupo VIP',
              ],
              color: AppColors.primary,
              isPopular: true,
              petId: petId, // ← AGREGAR
              petName: petName, // ← AGREGAR
            ),

            _buildPlanCard(
              context: context,
              priceId: StripeConfig.adoptarAngel,
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
              color: AppColors.likeActive,
              isPopular: false,
              petId: petId, // ← AGREGAR
              petName: petName, // ← AGREGAR
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
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.favorite, color: AppColors.likeActive, size: 32),
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

  Widget _buildPlanCard({
    required BuildContext context,
    required String priceId, // Ya no lo usamos, usamos price directamente
    required String title,
    required String price,
    required String description,
    required List<String> benefits,
    required Color color,
    required bool isPopular,
    String? petId, // ← AGREGAR
    String? petName,
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
                      '\$',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      price,
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

                // ✅ BOTÓN ACTUALIZADO CON MÉTODO CORRECTO
                // ✅ BOTÓN CORREGIDO
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Mostrar loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(
                          child: CircularProgressIndicator(color: color),
                        ),
                      );

                      // ✅ UNA SOLA LLAMADA CON petId
                      final result = await PaymentService()
                          .createAdopcionSubscription(
                            context: context,
                            plan: price,
                            planName: title,
                            petId: petId, // ← ESTO ES LO CRÍTICO
                          );

                      // Cerrar loading
                      Navigator.pop(context);

                      // Mostrar resultado
                      PaymentService.showPaymentResult(context, result);

                      // ✅ Si fue exitoso, volver al feed
                      if (result['success'] == true) {
                        Navigator.pop(context); // Cerrar pantalla de adopción
                      }
                    },
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
class AdoptarScreen extends StatefulWidget {
  @override
  State<AdoptarScreen> createState() => _AdoptarScreenState();
}

class _AdoptarScreenState extends State<AdoptarScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    // ✅ FIX: Limpiar texto antes de dispose
    _amountController.clear();
    _amountController.dispose();

    Logger.info('AdoptarScreen disposed correctamente');
    super.dispose();
  }

  Future<void> _processPayment() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText('Por favor ingresa un monto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText('Ingresa un monto válido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (amount < 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText('El monto mínimo es \$0.50 USD'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await PaymentService()
          .createOneTimePayment(
            context: context,
            amount: amount,
            description: 'Apoyo a WooHeart - \$$amount USD',
          )
          .timeout(Duration(seconds: 60));

      if (mounted) {
        PaymentService.showPaymentResult(context, result);

        if (result['success'] == true) {
          _amountController.clear();
        }
      }
    } on TimeoutException {
      Logger.warning('Timeout en el pago - Usuario esperó más de 60s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El pago está tardando más de lo esperado. '
              'Revisa tu historial en unos minutos',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } on SocketException {
      Logger.error('Sin conexión durante el pago');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sin conexión a internet'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error en el pago: e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pago. Intenta de nuevo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

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
                color: AppColors.primaryWithOpacity(0.1),
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
                color: AppColors.primary,
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

            // Mensaje motivacional
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.favorite, color: AppColors.likeActive, size: 40),
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

            // Campo de monto personalizado
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFFE8043), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TranslatedText(
                    '💝 ¿Cuánto quieres aportar?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: !_isProcessing,
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
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isProcessing
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : TranslatedText(
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
                  Icon(Icons.verified, color: AppColors.success, size: 20),
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
              'Suscríbete y "Cada mes, recibirás una tarjeta virtual con el rostro de quien ayudaste: un perrito que ahora tiene alimento, un gatito con un refugio cálido, o una persona que recuperó esperanza. No es solo un recuerdo... es la prueba de que tu suscripción silenciosa cambia vidas. ¿Quieres ser parte de esta cadena de amor?"',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 15, height: 1.5),
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
              'Pago mensual - Cancela cuando quieras',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Opciones de contribución
            _buildContributionCard(
              context: context,
              priceId: StripeConfig.suscribir5, // ← NUEVO
              amount: '5',
              title: 'Granito de arena',
              description: 'Alimenta a un peludito por 1 día',
              icon: Icons.restaurant,
              color: Color(0xFF9C27B0),
            ),
            _buildContributionCard(
              context: context,
              priceId: StripeConfig.suscribir10, // ← NUEVO
              amount: '10',
              title: 'Luz de esperanza',
              description: 'Alimenta a un peludito por 2 días',
              icon: Icons.restaurant,
              color: Color(0xFF9C27B0),
            ),
            _buildContributionCard(
              context: context,
              priceId: StripeConfig.suscribir60, // ← NUEVO
              amount: '60',
              title: 'Ángel de la guarda',
              description: 'Alimenta a un peludito por 12 días',
              icon: Icons.restaurant,
              color: Color(0xFF9C27B0),
            ),
            _buildContributionCard(
              context: context,
              priceId: StripeConfig.suscribir150, // ← NUEVO
              amount: '150',
              title: 'Corazón dorado',
              description: 'Alimenta a un peludito por 30 días',
              icon: Icons.restaurant,
              color: Color(0xFF9C27B0),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Reemplaza SOLO esta función en SuscScreen (línea ~2810)

  Widget _buildContributionCard({
    required BuildContext context,
    required String priceId, // Este ahora será '5', '10', '60', '150'
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
          onTap: () async {
            // Mostrar loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  Center(child: CircularProgressIndicator(color: color)),
            );

            // ✅ CAMBIO PRINCIPAL: Usar el nuevo método
            final result = await PaymentService().createSuscripcionSubscription(
              context: context,
              plan: amount, // Usar el monto (5, 10, 60, 150)
              planName: title,
            );

            // Cerrar loading
            Navigator.pop(context);

            // Mostrar resultado
            PaymentService.showPaymentResult(context, result);
          },
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
                      '\$$amount',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'USD',
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
              child: CircularProgressIndicator(color: AppColors.primary),
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
              color: AppColors.primary,
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
                          backgroundColor: AppColors.primary,
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

// ============================================
// PANTALLA DE PERFIL CON BADGE PREMIUM
// ============================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  int _selectedTab = 0;
  String _username = 'Usuario';
  String _email = '';
  int _likesCount = 0;
  int _serverLikesCount = 0;

  // ✅ DATOS DE PAGOS
  PaymentHistoryData? _paymentHistory;
  bool _isLoadingPayments = false;
  String? _paymentError;
  List<PetModel>? _petsCache;
  Future<List<PetModel>>? _petsFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLikesCount();
    _loadServerLikesCount();
    _loadPaymentHistory();
    likeNotifier.addListener(_loadLikesCount);
  }

  @override
  bool get wantKeepAlive => true;

  // @override
  // void didUpdateWidget(ProfileScreen oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   _loadLikesCount();
  // }

  @override
  void dispose() {
    // ✅ REMOVER LISTENER
    likeNotifier.removeListener(_loadLikesCount);

    // ✅ LIMPIAR CACHE DE MASCOTAS
    _petsCache?.clear();

    // ✅ CANCELAR FUTURE EN PROGRESO (si existe)
    _petsFuture = null;

    Logger.info('ProfileScreen disposed correctamente');
    super.dispose();
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

      if (mounted) {
        setState(() {
          _likesCount = totalLikes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _likesCount = 0;
        });
      }
    }
  }

  // ✅ NUEVA FUNCIÓN: Cargar likes desde el servidor
  Future<void> _loadServerLikesCount() async {
    try {
      final likedPets = await PetService.fetchLikedPets();

      if (mounted) {
        setState(() {
          _serverLikesCount = likedPets.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverLikesCount = 0;
        });
      }
    }
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoadingPayments = true;
      _paymentError = null;
    });

    try {
      final result = await PaymentHistoryService().getPaymentHistory();

      if (result['success']) {
        setState(() {
          _paymentHistory = result['data'] as PaymentHistoryData?;
          _isLoadingPayments = false;
        });
      } else {
        setState(() {
          _paymentError = result['message'];
          _isLoadingPayments = false;
        });
      }
    } catch (e) {
      setState(() {
        _paymentError = 'Error al cargar historial';
        _isLoadingPayments = false;
      });
    }
  }

  // ✅ NUEVO: Cargar mascotas UNA SOLA VEZ
  Future<void> _loadPetsOnce() async {
    // Si ya están cargadas, no hacer nada
    if (_petsCache != null) return;

    // Si ya hay una carga en proceso, esperar
    if (_petsFuture != null) {
      await _petsFuture;
      return;
    }

    // Iniciar carga
    _petsFuture = PetService.fetchPets();

    try {
      final pets = await _petsFuture!;
      if (mounted) {
        setState(() {
          _petsCache = pets;
        });
        Logger.success('Mascotas cargadas en ProfileScreen: ${pets.length}');
      }
    } catch (e) {
      Logger.error('Error cargando mascotas en ProfileScreen', e);
      if (mounted) {
        setState(() {
          _petsCache = []; // Lista vacía para evitar reintentos infinitos
        });
      }
    }
  }

  // ✅ NUEVO: Determinar si el usuario es premium
  bool get _isPremium {
    if (_paymentHistory == null) return false;
    return _paymentHistory!.hasActiveSubscription ||
        _paymentHistory!.hasAdoptions;
  }

  // ✅ NUEVO: Obtener el plan más alto activo
  String get _premiumPlanName {
    if (_paymentHistory == null) return '';

    // Prioridad: Adopciones > Suscripción General
    if (_paymentHistory!.hasAdoptions) {
      final activeAdoptions = _paymentHistory!.adoptions
          .where((a) => a.isActive)
          .toList();

      if (activeAdoptions.isNotEmpty) {
        // Buscar el plan más alto
        activeAdoptions.sort(
          (a, b) => int.parse(b.plan).compareTo(int.parse(a.plan)),
        );
        return activeAdoptions.first.planName;
      }
    }

    if (_paymentHistory!.hasActiveSubscription) {
      return _paymentHistory!.generalSubscription!.planName;
    }

    return '';
  }

  // ✅ NUEVO: Obtener icono del plan
  String get _premiumIcon {
    if (_paymentHistory == null) return '';

    if (_paymentHistory!.hasAdoptions) {
      return '🐾'; // Icono para adopciones
    }

    if (_paymentHistory!.hasActiveSubscription) {
      return '⭐'; // Icono para suscripciones
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← AGREGAR ESTA LÍNEA (CRÍTICO)
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadLikesCount();
          await _loadServerLikesCount();
          await _loadPaymentHistory();
        },
        child: Column(
          children: [
            // Header del perfil con badge premium
            Container(
              padding: EdgeInsets.all(30),
              decoration: _isPremium
                  ? BoxDecoration(gradient: AppColors.premiumBackgroundGradient)
                  : null,
              child: Column(
                children: [
                  SizedBox(height: 36),

                  // Avatar con badge premium
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.person_outline_outlined,
                        color: Colors.black,
                        size: 50,
                      ),

                      // ✅ BADGE PREMIUM
                      if (_isPremium)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: AppColors.premiumGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Username
                  Text(
                    '$_username',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  // ✅ BADGE DE PLAN PREMIUM
                  if (_isPremium)
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_premiumIcon, style: TextStyle(fontSize: 14)),
                          SizedBox(width: 6),
                          Text(
                            _premiumPlanName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Descripción
                  TranslatedText(
                    'Amante de los animales 🐶',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 75, 75, 75),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Estadísticas
                  _buildStatsRow(),
                  SizedBox(height: 18),

                  // Mensaje motivacional (cambia si es premium)
                  _isPremium
                      ? TranslatedText(
                          '💫 ¡Gracias por ser parte de nuestra familia premium!\nTu apoyo está cambiando vidas. 🙏',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 75, 75, 75),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.justify,
                        )
                      : TranslatedText(
                          '🌟 "¿Listo para marcar la diferencia? Con [Monto]/mes apoyás a quien más lo necesita.\nRecibirás una tarjeta de impacto mensual con lo que ayudaste ❤️ Tu aporte cambia vidas.\n¡Sumate Hoy!',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 75, 75, 75),
                          ),
                          textAlign: TextAlign.justify,
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
                    index: 2,
                    icon: Icons.star,
                    label: 'Suscripción',
                  ),
                  _buildCategoryButton(
                    index: 4,
                    icon: Icons.thumb_up,
                    label: 'Likes',
                  ),
                ],
              ),
            ),

            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
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
        TranslatedText(
          label,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
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
              color: isSelected ? AppColors.primary : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          SizedBox(height: 4),
          TranslatedText(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ✅ NUEVO: Stats con iconos y mejor diseño
  // ============================================
  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Adoptados
          _buildStatCard(
            icon: Icons.pets,
            iconColor: AppColors.primary,
            count: '${_paymentHistory?.adoptions.length ?? 0}',
            label: 'Adoptados',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdoptedPetsScreen()),
              ).then((_) {
                if (mounted) {
                  _loadPaymentHistory();
                }
              });
            },
          ),

          // Divider vertical
          Container(height: 50, width: 1, color: Colors.grey[300]),

          // ✅ NUEVO: Apoyos
          _buildStatCard(
            icon: Icons.volunteer_activism,
            iconColor: Colors.purple,
            count: '${_paymentHistory?.donations.length ?? 0}',
            label: 'Apoyos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SupportedPetsScreen()),
              ).then((_) {
                if (mounted) {
                  _loadPaymentHistory();
                }
              });
            },
          ),

          // Divider vertical
          Container(height: 50, width: 1, color: Colors.grey[300]),

          // Me encanta
          _buildStatCard(
            icon: Icons.favorite,
            iconColor: AppColors.likeActive,
            count: '$_serverLikesCount',
            label: 'Me encanta',
            onTap: () {
              setState(() => _selectedTab = 4);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ), // ✅ REDUCIDO de 24/12 a 16/10
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 18), // ✅ REDUCIDO de 20 a 18
                SizedBox(width: 4), // ✅ REDUCIDO de 6 a 4
                Text(
                  count,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20, // ✅ REDUCIDO de 24 a 20
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2), // ✅ REDUCIDO de 4 a 2
            TranslatedText(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11, // ✅ REDUCIDO de 12 a 11<
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildAdoptedPetsTab();
      case 1:
        return _buildDonationsTab();
      case 2:
        return _buildSubscriptionTab();
      case 4:
        return _buildLikesTab();
      default:
        return Center(child: Text('Pestaña no implementada'));
    }
  }

  Widget _buildAdoptedPetsTab() {
    if (_isLoadingPayments) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_paymentError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            SizedBox(height: 16),
            Text('Error: $_paymentError'),
          ],
        ),
      );
    }

    final adoptions = _paymentHistory?.adoptions ?? [];

    // ✅ MOSTRAR INFO DE DEBUG
    print('🔍 Total adoptions: ${adoptions.length}');
    print('🔍 Payment history: $_paymentHistory');
    print('🔍 Adoptions data: $adoptions');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${adoptions.length}',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8),
          TranslatedText(
            adoptions.length == 1 ? 'Mascota Adoptada' : 'Mascotas Adoptadas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          // ✅ MOSTRAR INFO DE DEBUG EN PANTALLA
          SizedBox(height: 10),

          if (adoptions.isEmpty) ...[
            SizedBox(height: 16),
            TranslatedText(
              'Haz una adopción para ver tus mascotas aquí',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            // ✅ BOTÓN PARA PROBAR LA LLAMADA AL BACKEND
            ElevatedButton(
              onPressed: () async {
                try {
                  final pets = await PetService.fetchAdoptedPets();
                  print('✅ Mascotas desde backend: ${pets.length}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backend retornó: ${pets.length} mascotas'),
                    ),
                  );
                } catch (e) {
                  print('❌ Error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Probar Endpoint'),
            ),
          ] else ...[
            // SizedBox(height: 32),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => AdoptedPetsScreen()),
            //     );
            //   },
            //   icon: Icon(Icons.grid_view, color: Colors.white),
            //   label: Text('Ver Galería', style: TextStyle(color: Colors.white)),
            //   // style: ElevatedButton.styleFrom(
            //   //   backgroundColor: AppColors.primary,
            //   //   padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            //   // ),
            // ),
          ],
        ],
      ),
    );
  }

  // ✅ NUEVO: Card de adopción con galería de fotos
  Widget _buildAdoptionCard(AdoptionInfo adoption, PetModel pet) {
    return Card(
      margin: EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con info del plan
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryWithOpacity(0.8)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.favorite, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adoption.planName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        adoption.formattedAmount,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: adoption.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    adoption.statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nombre de la mascota
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.pets, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  pet.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // ✅ GALERÍA DE FOTOS
          if (pet.imageUrls.isNotEmpty)
            Container(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: pet.imageUrls.length,
                itemBuilder: (context, photoIndex) {
                  return GestureDetector(
                    onTap: () {
                      // Abrir modal con foto ampliada
                      _showPhotoModal(context, pet, photoIndex);
                    },
                    child: Container(
                      width: 160,
                      margin: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: pet.imageUrls[photoIndex],
                              fit: BoxFit.cover,

                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),

                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[600],
                                  size: 50,
                                ),
                              ),
                            ),
                            // Overlay para indicar que se puede tocar
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Info adicional
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Divider(),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Desde',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          adoption.formattedStartDate,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (adoption.isActive && adoption.nextPayment != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Próximo pago',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            adoption.formattedNextPayment,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Modal para mostrar foto ampliada
  void _showPhotoModal(BuildContext context, PetModel pet, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Carrusel de fotos
            Center(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                child: PageView.builder(
                  controller: PageController(initialPage: initialIndex),
                  itemCount: pet.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: pet.imageUrls[index],
                          fit: BoxFit.contain,

                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFE8043),
                            ),
                          ),

                          errorWidget: (context, url, error) =>
                              Icon(Icons.error, color: Colors.white, size: 60),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Botón de cerrar
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),

            // Nombre de la mascota
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pet.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationsTab() {
    // Navegar automáticamente cuando se selecciona el tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SupportedPetsScreen()),
      ).then((_) {
        // Al volver, recargar y cambiar tab
        if (mounted) {
          _loadPaymentHistory();
          setState(() {
            _selectedTab = 0; // Volver a Inicio
          });
        }
      });
    });

    // Mostrar loading mientras navega
    return Center(child: CircularProgressIndicator(color: AppColors.primary));
  }

  Widget _buildSubscriptionTab() {
    if (_isLoadingPayments) {
      return Center(child: CircularProgressIndicator(color: Color(0xFFFE8043)));
    }

    if (_paymentError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            SizedBox(height: 16),
            TranslatedText(
              'Error al cargar suscripción',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              _paymentError!,
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final subscription = _paymentHistory?.generalSubscription;

    if (subscription == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            TranslatedText(
              'No tienes una suscripción activa',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            TranslatedText(
              'Suscríbete para apoyar mensualmente',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryWithOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: 48),
                SizedBox(height: 16),
                TranslatedText(
                  'Plan Activo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  subscription.planName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subscription.formattedAmount,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 24),
                Divider(color: Colors.white.withOpacity(0.3)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Desde',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subscription.formattedStartDate,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Próximo cargo',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subscription.formattedNextPayment,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: subscription.isActive
                        ? Colors.white.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subscription.statusText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLikesTab() {
    // Navegar automáticamente cuando se selecciona el tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LikesScreen()),
      ).then((_) {
        // Al volver, recargar el contador y cambiar tab
        if (mounted) {
          _loadServerLikesCount(); // ✅ AGREGAR ESTA LÍNEA
          setState(() {
            _selectedTab = 0; // Volver a Inicio
          });
        }
      });
    });

    // Mostrar loading mientras navega
    return Center(child: CircularProgressIndicator(color: Color(0xFFFE8043)));
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
              icon: Icon(Icons.edit, color: AppColors.primary),
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
                        color: AppColors.primary,
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
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
                  prefixIcon: Icon(Icons.person, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
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
                  prefixIcon: Icon(Icons.email, color: AppColors.primary),
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
                leading: Icon(Icons.lock, color: AppColors.primary),
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
    // ✅ FIX: Limpiar + dispose en orden inverso
    _celularController.clear();
    _celularController.dispose();

    _emailController.clear();
    _emailController.dispose();

    _nombreController.clear();
    _nombreController.dispose();

    Logger.info('AccountScreen disposed correctamente');
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
              activeColor: AppColors.primary,
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
        secondary: Icon(icon, color: AppColors.primary),
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
                    color: AppColors.primaryWithOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.support_agent,
                    size: 60,
                    color: AppColors.primary,
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
            iconColor: AppColors.primary,
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

  @override
  void dispose() {
    // ✅ LIMPIAR CONTROLLER Y MENSAJES
    _mensajeController.dispose();
    _mensajes.clear();

    Logger.info('LiveChatScreen disposed correctamente');
    super.dispose();
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
        backgroundColor: AppColors.primary,
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
          color: esUsuario ? AppColors.primary : AppColors.textWhite,
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
