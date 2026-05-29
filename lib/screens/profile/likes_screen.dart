import 'package:flutter/material.dart';
import '../../data/model/pet_model.dart';
import '../../services/pet_service.dart';
import '../../widgets/translated_text.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({Key? key}) : super(key: key);

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  late Future<List<PetModel>> _likedPetsFuture;

  @override
  void initState() {
    super.initState();
    _loadLikedPets();
  }

  void _loadLikedPets() {
    setState(() {
      _likedPetsFuture = PetService.fetchLikedPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Mis Likes',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Color(0xFFFE8043),
        onRefresh: () async {
          _loadLikedPets();
          await _likedPetsFuture;
        },
        child: FutureBuilder<List<PetModel>>(
          future: _likedPetsFuture,
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
                      'Cargando tus likes...',
                      style: TextStyle(color: Colors.grey),
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
                      'Error al cargar likes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '${snapshot.error}',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadLikedPets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFE8043),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: TranslatedText(
                        'Reintentar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            // CASO 3: Sin likes
            final likedPets = snapshot.data ?? [];
            if (likedPets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    TranslatedText(
                      'Aún no tienes likes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    TranslatedText(
                      'Explora y da like a las mascotas que te gusten',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // CASO 4: Grid de likes estilo TikTok
            return Column(
              children: [
                // Header con contador
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, color: Color(0xFFB42C1C), size: 20),
                      SizedBox(width: 8),
                      TranslatedText(
                        '${likedPets.length} ${likedPets.length == 1 ? "mascota" : "mascotas"}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Grid 3x3
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(2),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 1,
                    ),
                    itemCount: likedPets.length,
                    itemBuilder: (context, index) {
                      final pet = likedPets[index];
                      return _buildPetThumbnail(pet, index, likedPets);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPetThumbnail(PetModel pet, int index, List<PetModel> allPets) {
    return GestureDetector(
      onTap: () => _openPetDetail(pet, index, allPets),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen
          pet.imageUrls.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: pet.imageUrls[0],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFE8043),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[400],
                    child: Icon(Icons.error, color: Colors.white),
                  ),
                )
              : Container(
                  color: Colors.grey[400],
                  child: Icon(Icons.pets, color: Colors.white, size: 40),
                ),

          // Overlay con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
              ),
            ),
          ),

          // Nombre de la mascota
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Text(
              pet.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openPetDetail(PetModel pet, int startIndex, List<PetModel> allPets) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LikedPetsViewer(
          pets: allPets, // ❌ ERROR: snapshot no existe aquí
          initialIndex: startIndex,
          onLikeRemoved: _loadLikedPets,
        ),
      ),
    );
  }
}

// ============================================
// VISOR DE MASCOTAS LIKED (Estilo TikTok)
// ============================================
class LikedPetsViewer extends StatefulWidget {
  final List<PetModel> pets;
  final int initialIndex;
  final VoidCallback onLikeRemoved;

  const LikedPetsViewer({
    Key? key,
    required this.pets,
    required this.initialIndex,
    required this.onLikeRemoved,
  }) : super(key: key);

  @override
  State<LikedPetsViewer> createState() => _LikedPetsViewerState();
}

class _LikedPetsViewerState extends State<LikedPetsViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<PetModel> _pets = [];

  @override
  void initState() {
    super.initState();
    _pets = List.from(widget.pets);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final pet = _pets[_currentIndex];

    // Optimistic update
    setState(() {
      pet.isLiked = false;
    });

    final result = await PetService.toggleLike(pet.id);

    if (result['success']) {
      // Quitar de la lista
      setState(() {
        _pets.removeAt(_currentIndex);
      });

      // Si ya no hay más mascotas, volver
      if (_pets.isEmpty) {
        widget.onLikeRemoved();
        Navigator.pop(context);
        return;
      }

      // Ajustar índice si es necesario
      if (_currentIndex >= _pets.length) {
        _currentIndex = _pets.length - 1;
        _pageController.jumpToPage(_currentIndex);
      }
    } else {
      // Revertir si falló
      setState(() {
        pet.isLiked = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al quitar like'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pets.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFE8043)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView de mascotas
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _pets.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final pet = _pets[index];
              return _buildPetPage(pet);
            },
          ),

          // Botón de cerrar
          SafeArea(
            child: Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () {
                  widget.onLikeRemoved();
                  Navigator.pop(context);
                },
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetPage(PetModel pet) {
    return Stack(
      children: [
        // Imagen de la mascota
        Center(
          child: pet.imageUrls.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: pet.imageUrls[0],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(color: Color(0xFFFE8043)),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.error, color: Colors.white, size: 60),
                  ),
                )
              : Center(child: Icon(Icons.pets, color: Colors.white, size: 80)),
        ),

        // Gradiente inferior
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),
        ),

        // Información de la mascota
        Positioned(
          bottom: 20,
          left: 12,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pet.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                pet.description,
                style: TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Botón de like
        Positioned(
          right: 12,
          bottom: 30,
          child: GestureDetector(
            onTap: _toggleLike,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Color(0xFFB42C1C),
                    size: 32,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${pet.likes}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
