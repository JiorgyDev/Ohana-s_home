import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: camel_case_types
class homepage extends StatelessWidget {
  const homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: MainScreen());
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
    CrearScreen(),
    // DiscoverScreen(),
    InboxScreen(),
    SettingsScreen(),
    // CreateScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black26,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color.fromARGB(255, 63, 63, 63),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),

          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange,
                // gradient: LinearGradient(colors: Colors.orange),
                borderRadius: BorderRadius.circular(80),
              ),
              child: Image.asset(
                'assets/icons/adopcion3.png',
                width: 30,
                height: 30,
              ),
            ),
            label: 'Adoptar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

// Pantalla Principal - Feed de Fotos
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  // Datos de ejemplo
  final List<PhotoPost> _posts = [
    PhotoPost(
      id: '1',
      username: 'CAPUCCINO',
      description:
          "Descripción:\nejemplo 1 - Animales\nemergencia: Perritos necesitan abrigo y comida caliente.\nnecesidades: 1 abrigo + alimentos calientes\nlugar: Zona: La Ceja, El Alto, Bolivia",
      imageUrl:
          'https://images.dog.ceo/breeds/retriever-golden/n02099601_3004.jpg',
      adopcion: 12,
      apoyo: 435,
      likes: 134,
      comments: 89,
      shares: 45,
      isLiked: false,
    ),
    PhotoPost(
      id: '2',
      username: 'JAGGER',
      description:
          "Descripción:\nejemplo 2 - Animales\nemergencia: Perrito herido necesita atención veterinaria.\nnecesidades: Medicinas + refugio temporal\nlugar: Zona: Achumani, La Paz, Bolivia",
      imageUrl:
          'https://images.dog.ceo/breeds/terrier-norwich/n02094258_2159.jpg',
      adopcion: 2,
      apoyo: 45,
      likes: 856,
      comments: 92,
      shares: 23,
      isLiked: true,
    ),
    PhotoPost(
      id: '3',
      username: 'CHAPUU',
      description:
          "Descripción:\nejemplo 3 - Animales\nemergencia: Cachorros huérfanos necesitan adopción responsable.\nnecesidades: Alimentos balanceados + vacunas\nlugar: Zona: San Miguel, Cochabamba, Bolivia",
      imageUrl: 'https://images.dog.ceo/breeds/beagle/n02088364_11136.jpg',
      adopcion: 20,
      apoyo: 43,
      likes: 2341,
      comments: 156,
      shares: 78,
      isLiked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _posts.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return PhotoPostWidget(
            post: _posts[index],
            onLike: () => _toggleLike(index),
          );
        },
      ),
    );
  }

  void _toggleLike(int index) {
    setState(() {
      _posts[index].isLiked = !_posts[index].isLiked;
      if (_posts[index].isLiked) {
        _posts[index].likes++;
      } else {
        _posts[index].likes--;
      }
    });
  }
}

// Widget para mostrar cada foto
class PhotoPostWidget extends StatelessWidget {
  final PhotoPost post;
  final VoidCallback onLike;

  const PhotoPostWidget({Key? key, required this.post, required this.onLike})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Imagen de fondo
        Container(
          width: double.infinity,
          height: double.infinity,
          child: Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[800],
                child: Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
                ),
              );
            },
          ),
        ),

        // Gradiente para mejorar legibilidad
        Container(
          width: double.infinity,
          height: double.infinity,

          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
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
                  width: 40,
                  height: 40,
                ),
                label: _formatNumber(post.adopcion),
                onTap: () => _adoptarPost(context),
              ),
              SizedBox(height: 10),
              _buildActionButton(
                customIcon: Image.asset(
                  'assets/icons/apoyar2.png',
                  width: 40,
                  height: 40,
                ),
                label: _formatNumber(post.apoyo),
                onTap: () => _apoyarPost(context),
              ),
              SizedBox(height: 10),
              _buildActionButton(
                customIcon: Image.asset(
                  'assets/icons/like.png',
                  width: 600,
                  height: 600,
                  color: post.isLiked
                      ? Colors.red
                      : Colors.white, // <- cambia según estado
                ),
                label: _formatNumber(post.likes),
                onTap: onLike,
              ),

              SizedBox(height: 10),
              _buildActionButton(
                customIcon: Image.asset(
                  'assets/icons/escribiendo.png',
                  width: 40,
                  height: 40,
                  color: Colors.white,
                ),

                label: _formatNumber(post.comments),
                onTap: () => _showComments(context),
              ),

              SizedBox(height: 10),
              _buildActionButton(
                customIcon: Image.asset(
                  'assets/icons/compartir2.png',

                  color: Colors.white,
                ),
                label: _formatNumber(post.shares),
                onTap: _sharePostToWhatsApp,
                // onTap: () => _sharePost(context),
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
              Row(
                children: [
                  Text(
                    '${post.username}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
              SizedBox(height: 8),

              // Descripción
              Text(
                post.description,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              SizedBox(height: 12),

              // Información de la canción
              // Row(
              //   children: [
              //     Icon(Icons.music_note, color: Colors.white, size: 16),
              //     SizedBox(width: 4),
              //     Expanded(
              //       child: Text(
              //         // post.songName,
              //         style: TextStyle(color: Colors.white, fontSize: 12),
              //         overflow: TextOverflow.ellipsis,
              //       ),
              //     ),
              //   ],
              // ),
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
          Container(
            width: iconSize + 15,
            height: iconSize + 15,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
            child: customIcon ?? Icon(iconData, color: color, size: iconSize),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Comentarios',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildComment('usuario1', 'Increíble foto! 📸'),
                  _buildComment('usuario2', 'Me encanta este lugar'),
                  _buildComment('usuario3', '¿Dónde fue tomada?'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final mensaje = Uri.encodeComponent(
      '¡Mira este post en Ohana\'s App! 🐶❤️ ',
    );
    final url = 'https://wa.me/?text=te invito a descargar esta app...';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo abrir WhatsApp');
    }
  }

  void _sharePost(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compartir funcionalidad'),
        backgroundColor: Colors.pink,
      ),
    );
  }

  void _apoyarPost(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('apoyaste'), backgroundColor: Colors.pink),
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
        backgroundColor: Colors.black,
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

//pantalla crear
class CrearScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Logo
            Image.asset('assets/icons/adopcion.png', width: 60, height: 60),
            const SizedBox(height: 12),

            // Título
            const Text(
              'Ohana’s Home',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Descripción principal
            const Text(
              'Suscríbete a Ohana’s Home y'
              'Cada mes, recibirás una tarjeta virtual con el rostro de quien ayudaste: '
              'un perrito que ahora tiene alimento, un gatito con un refugio cálido, o una persona que recuperó esperanza.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              '¿Quieres ser parte de esta cadena de amor?',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Título de suscripción
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SUSCRÍBETE MENSUALMENTE SEGÚN TU PRESUPUESTO Y SÉ PARTE DE OHANA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botones de suscripción
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                _priceButton('2 usd / mes', Colors.purple),

                _priceButton('5 usd / mes', Colors.blue),

                _priceButton('10 usd / mes', Colors.green),
                _priceButton('15 usd / mes', Colors.orange),
                _priceButton('30 usd / mes', Colors.red),
              ],
            ),
            const SizedBox(height: 20),

            // Notas motivadoras
            const Text(
              '“Así podrás ver tu primera tarjeta de impacto este mes”',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta es Max, el perrito que ayudaste con tu suscripción. Cada mes te enviaremos una imagen con una nota especial de la persona/animal que ayudaste.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Imagen con mensaje personalizado
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icons/mapache.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Juan Perez yo comeré\nhoy gracias a ti...',

                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

Widget _priceButton(String label, Color color) {
  return ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    child: Text(label),
  );
}

// Pantalla de Crear
class CreateScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Post', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Selecciona una foto',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Abrir galería')));
              },
              icon: Icon(Icons.photo_library),
              label: Text('Galería'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Abrir cámara')));
              },
              icon: Icon(Icons.camera_alt),
              label: Text('Cámara'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla de Mensajes
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco en toda la pantalla
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
      body: ListView.separated(
        itemCount: 6,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) =>
            const Divider(color: Colors.grey, height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 8,
            ),
            leading: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFF3F3F3),
              child: Icon(Icons.person, color: Colors.orange, size: 24),
            ),
            title: Text(
              'Usuario ${index + 1}',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Último mensaje...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            trailing: Text(
              '${index + 1}h',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              // Acción al tocar el mensaje
            },
          );
        },
      ),
    );
  }
}

// Pantalla de Perfil
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header del perfil
          Container(
            padding: EdgeInsets.all(30),
            child: Column(
              children: [
                SizedBox(height: 16),
                Icon(
                  Icons.person_outline_outlined,
                  color: Colors.black,
                  size: 50,
                ),
                SizedBox(height: 16),

                Text(
                  '@JuanPerez19',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Amante de la fotografía 📸',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 75, 75, 75),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('123', '🐾 Ahijados'),
                    _buildStatColumn('456', '🐕‍🦺 Apoyos'),
                    _buildStatColumn('78', '🫶 Me encanta'),
                  ],
                ),
                SizedBox(height: 28),
                Text(
                  '🌟 "¿Listo para marcar la diferencia?\nCon solo [Monto]/mes, puedes convertirte en el héroe de [un perrito/una persona necesitada].\nCada mes recibirás tu tarjeta de impacto, recordándote el bien que estás haciendo.❤️ Tú puedes ser la razón por la que alguien no pierda la esperanza.\n¡Sumate Hoy!',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 75, 75, 75),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50),
          // Tabs
          Container(
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: Tab(
                    child: Text("TODOS", style: TextStyle(color: Colors.white)),
                  ),
                ),
                Expanded(
                  child: Tab(
                    child: Text(
                      "AHIJADOS",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: Tab(
                    child: Text("APOYO", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),

          // Grid de posts del usuario
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(2),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 15,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Icon(Icons.image, color: Colors.white, size: 30),
                  ),
                );
              },
            ),
          ),
        ],
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
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}

//pantalla ajustes
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
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
          const ListTile(
            leading: Icon(Icons.person, color: Colors.black54),
            title: Text("Cuenta"),
            subtitle: Text("Actualizar información personal"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.notifications, color: Colors.black54),
            title: Text("Notificaciones"),
            subtitle: Text("Administrar notificaciones"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.lock, color: Colors.black54),
            title: Text("Privacidad"),
            subtitle: Text("Cambiar contraseña o privacidad"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.language, color: Colors.black54),
            title: Text("Idioma"),
            subtitle: Text("Seleccionar idioma"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.help_outline, color: Colors.black54),
            title: Text("Ayuda"),
            subtitle: Text("Centro de soporte"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Cerrar sesión",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              // Acción al cerrar sesión
            },
          ),
        ],
      ),
    );
  }
}

// Modelo de datos para los posts
class PhotoPost {
  final String id;
  final String username;
  final String description;
  final String imageUrl;
  int adopcion;
  int apoyo;
  int likes;
  final int comments;
  final int shares;
  // final String songName;
  bool isLiked;

  PhotoPost({
    required this.id,
    required this.username,
    required this.description,
    required this.imageUrl,
    required this.adopcion,
    required this.apoyo,
    required this.likes,
    required this.comments,
    required this.shares,
    // required this.songName,
    this.isLiked = false,
  });
}
