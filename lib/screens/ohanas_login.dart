import 'package:flutter/material.dart';
import 'package:ohanas_app/screens/homePage.dart';

class OhanasHome extends StatelessWidget {
  const OhanasHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const homepage());
  }
}

class OhanasLogin extends StatefulWidget {
  const OhanasLogin({super.key});

  @override
  State<OhanasLogin> createState() => _OhanasLoginState();
}

class _OhanasLoginState extends State<OhanasLogin> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _celularController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _correoController = TextEditingController();
  String _codigoPais = '+591 🇧🇴'; // Bolivia por defecto
  String _paisSeleccionado = 'Bolivia';

  final Map<String, String> _codigosPais = {
    'Afganistán': '+93 🇦🇫',
    'Albania': '+355 🇦🇱',
    'Alemania': '+49 🇩🇪',
    'Andorra': '+376 🇦🇩',
    'Angola': '+244 🇦🇴',
    'Argentina': '+54 🇦🇷',
    'Armenia': '+374 🇦🇲',
    'Australia': '+61 🇦🇺',
    'Austria': '+43 🇦🇹',
    'Azerbaiyán': '+994 🇦🇿',
    'Bahamas': '+1242 🇧🇸',
    'Bangladés': '+880 🇧🇩',
    'Barbados': '+1246 🇧🇧',
    'Bélgica': '+32 🇧🇪',
    'Belice': '+501 🇧🇿',
    'Benín': '+229 🇧🇯',
    'Bielorrusia': '+375 🇧🇾',
    'Bolivia': '+591 🇧🇴',
    'Bosnia y Herzegovina': '+387 🇧🇦',
    'Botsuana': '+267 🇧🇼',
    'Brasil': '+55 🇧🇷',
    'Brunéi': '+673 🇧🇳',
    'Bulgaria': '+359 🇧🇬',
    'Burkina Faso': '+226 🇧🇫',
    'Burundi': '+257 🇧🇮',
    'Bután': '+975 🇧🇹',
    'Cabo Verde': '+238 🇨🇻',
    'Camboya': '+855 🇰🇭',
    'Camerún': '+237 🇨🇲',
    'Canadá': '+1 🇨🇦',
    'Catar': '+974 🇶🇦',
    'Chad': '+235 🇹🇩',
    'Chile': '+56 🇨🇱',
    'China': '+86 🇨🇳',
    'Chipre': '+357 🇨🇾',
    'Colombia': '+57 🇨🇴',
    'Comoras': '+269 🇰🇲',
    'Congo': '+242 🇨🇬',
    'Corea del Norte': '+850 🇰🇵',
    'Corea del Sur': '+82 🇰🇷',
    'Costa Rica': '+506 🇨🇷',
    'Croacia': '+385 🇭🇷',
    'Cuba': '+53 🇨🇺',
    'Dinamarca': '+45 🇩🇰',
    'Dominica': '+1767 🇩🇲',
    'Ecuador': '+593 🇪🇨',
    'Egipto': '+20 🇪🇬',
    'El Salvador': '+503 🇸🇻',
    'Emiratos Árabes Unidos': '+971 🇦🇪',
    'Eritrea': '+291 🇪🇷',
    'Eslovaquia': '+421 🇸🇰',
    'Eslovenia': '+386 🇸🇮',
    'España': '+34 🇪🇸',
    'Estados Unidos': '+1 🇺🇸',
    'Estonia': '+372 🇪🇪',
    'Etiopía': '+251 🇪🇹',
    'Filipinas': '+63 🇵🇭',
    'Finlandia': '+358 🇫🇮',
    'Fiyi': '+679 🇫🇯',
    'Francia': '+33 🇫🇷',
    'Gabón': '+241 🇬🇦',
    'Gambia': '+220 🇬🇲',
    'Georgia': '+995 🇬🇪',
    'Ghana': '+233 🇬🇭',
    'Granada': '+1473 🇬🇩',
    'Grecia': '+30 🇬🇷',
    'Guatemala': '+502 🇬🇹',
    'Guinea': '+224 🇬🇳',
    'Guinea-Bisáu': '+245 🇬🇼',
    'Guinea Ecuatorial': '+240 🇬🇶',
    'Guyana': '+592 🇬🇾',
    'Haití': '+509 🇭🇹',
    'Honduras': '+504 🇭🇳',
    'Hungría': '+36 🇭🇺',
    'India': '+91 🇮🇳',
    'Indonesia': '+62 🇮🇩',
    'Irak': '+964 🇮🇶',
    'Irán': '+98 🇮🇷',
    'Irlanda': '+353 🇮🇪',
    'Islandia': '+354 🇮🇸',
    'Islas Marshall': '+692 🇲🇭',
    'Islas Salomón': '+677 🇸🇧',
    'Israel': '+972 🇮🇱',
    'Italia': '+39 🇮🇹',
    'Jamaica': '+1876 🇯🇲',
    'Japón': '+81 🇯🇵',
    'Jordania': '+962 🇯🇴',
    'Kazajistán': '+7 🇰🇿',
    'Kenia': '+254 🇰🇪',
    'Kirguistán': '+996 🇰🇬',
    'Kiribati': '+686 🇰🇮',
    'Kuwait': '+965 🇰🇼',
    'Laos': '+856 🇱🇦',
    'Lesoto': '+266 🇱🇸',
    'Letonia': '+371 🇱🇻',
    'Líbano': '+961 🇱🇧',
    'Liberia': '+231 🇱🇷',
    'Libia': '+218 🇱🇾',
    'Liechtenstein': '+423 🇱🇮',
    'Lituania': '+370 🇱🇹',
    'Luxemburgo': '+352 🇱🇺',
    'Madagascar': '+261 🇲🇬',
    'Malasia': '+60 🇲🇾',
    'Malaui': '+265 🇲🇼',
    'Maldivas': '+960 🇲🇻',
    'Malí': '+223 🇲🇱',
    'Malta': '+356 🇲🇹',
    'Marruecos': '+212 🇲🇦',
    'Mauricio': '+230 🇲🇺',
    'Mauritania': '+222 🇲🇷',
    'México': '+52 🇲🇽',
    'Micronesia': '+691 🇫🇲',
    'Moldavia': '+373 🇲🇩',
    'Mónaco': '+377 🇲🇨',
    'Mongolia': '+976 🇲🇳',
    'Montenegro': '+382 🇲🇪',
    'Mozambique': '+258 🇲🇿',
    'Myanmar': '+95 🇲🇲',
    'Namibia': '+264 🇳🇦',
    'Nauru': '+674 🇳🇷',
    'Nepal': '+977 🇳🇵',
    'Nicaragua': '+505 🇳🇮',
    'Níger': '+227 🇳🇪',
    'Nigeria': '+234 🇳🇬',
    'Noruega': '+47 🇳🇴',
    'Nueva Zelanda': '+64 🇳🇿',
    'Omán': '+968 🇴🇲',
    'Países Bajos': '+31 🇳🇱',
    'Pakistán': '+92 🇵🇰',
    'Palaos': '+680 🇵🇼',
    'Panamá': '+507 🇵🇦',
    'Papúa Nueva Guinea': '+675 🇵🇬',
    'Paraguay': '+595 🇵🇾',
    'Perú': '+51 🇵🇪',
    'Polonia': '+48 🇵🇱',
    'Portugal': '+351 🇵🇹',
    'Reino Unido': '+44 🇬🇧',
    'República Centroafricana': '+236 🇨🇫',
    'República Checa': '+420 🇨🇿',
    'República Democrática del Congo': '+243 🇨🇩',
    'República Dominicana': '+1809 🇩🇴',
    'Ruanda': '+250 🇷🇼',
    'Rumania': '+40 🇷🇴',
    'Rusia': '+7 🇷🇺',
    'Samoa': '+685 🇼🇸',
    'San Cristóbal y Nieves': '+1869 🇰🇳',
    'San Marino': '+378 🇸🇲',
    'San Vicente y las Granadinas': '+1784 🇻🇨',
    'Santa Lucía': '+1758 🇱🇨',
    'Santo Tomé y Príncipe': '+239 🇸🇹',
    'Senegal': '+221 🇸🇳',
    'Serbia': '+381 🇷🇸',
    'Seychelles': '+248 🇸🇨',
    'Sierra Leona': '+232 🇸🇱',
    'Singapur': '+65 🇸🇬',
    'Siria': '+963 🇸🇾',
    'Somalia': '+252 🇸🇴',
    'Sri Lanka': '+94 🇱🇰',
    'Suazilandia': '+268 🇸🇿',
    'Sudáfrica': '+27 🇿🇦',
    'Sudán': '+249 🇸🇩',
    'Sudán del Sur': '+211 🇸🇸',
    'Suecia': '+46 🇸🇪',
    'Suiza': '+41 🇨🇭',
    'Surinam': '+597 🇸🇷',
    'Tailandia': '+66 🇹🇭',
    'Tanzania': '+255 🇹🇿',
    'Tayikistán': '+992 🇹🇯',
    'Timor Oriental': '+670 🇹🇱',
    'Togo': '+228 🇹🇬',
    'Tonga': '+676 🇹🇴',
    'Trinidad y Tobago': '+1868 🇹🇹',
    'Túnez': '+216 🇹🇳',
    'Turkmenistán': '+993 🇹🇲',
    'Turquía': '+90 🇹🇷',
    'Tuvalu': '+688 🇹🇻',
    'Ucrania': '+380 🇺🇦',
    'Uganda': '+256 🇺🇬',
    'Uruguay': '+598 🇺🇾',
    'Uzbekistán': '+998 🇺🇿',
    'Vanuatu': '+678 🇻🇺',
    'Venezuela': '+58 🇻🇪',
    'Vietnam': '+84 🇻🇳',
    'Yemen': '+967 🇾🇪',
    'Yibuti': '+253 🇩🇯',
    'Zambia': '+260 🇿🇲',
    'Zimbabue': '+263 🇿🇼',
  };
  String _generoSeleccionado = '';
  bool _aceptaTerminos = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.pets,
                        size: 40,
                        color: Colors.orange[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'REGISTRATE ES\nGRATIS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Formulario
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre y Apellidos',
                icon: Icons.person,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _apellidosController,
                label: 'Usuario',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 16),

              // Número de celular con código de país
              _buildPhoneField(),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _fechaNacimientoController,
                label: 'Fecha de Nacimiento',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _fechaNacimientoController.text =
                        '${date.day}/${date.month}/${date.year}';
                  }
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _correoController,
                label: 'Correo',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              _buildDropdown(
                value: _generoSeleccionado,
                label: 'Género',
                icon: Icons.person,
                items: ['Masculino', 'Femenino', 'Otro'],
                onChanged: (value) {
                  setState(() {
                    _generoSeleccionado = value ?? '';
                  });
                },
              ),

              const SizedBox(height: 24),

              // Términos y Condiciones
              Row(
                children: [
                  Checkbox(
                    value: _aceptaTerminos,
                    onChanged: (value) {
                      setState(() {
                        _aceptaTerminos = value ?? false;
                      });
                    },
                    activeColor: Colors.orange[600],
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _aceptaTerminos = !_aceptaTerminos;
                        });
                      },
                      child: Text(
                        'Acepto los Términos y Condiciones',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botón Registrarse
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _aceptaTerminos
                      ? () {
                          if (_formKey.currentState!.validate()) {
                            // Navegar a la siguiente pantalla
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const homepage(),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Registrarme',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Row(
      children: [
        // Dropdown para código de país
        Container(
          width: 80, // Reducido de 100 a 80
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: _codigoPais,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 6,
              ), // Reducido padding
            ),
            items:
                _codigosPais.values.toSet().map((code) {
                  // Solo códigos únicos
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(
                      code,
                      style: const TextStyle(fontSize: 13), // Texto más pequeño
                    ),
                  );
                }).toList()..sort(
                  (a, b) => a.value!.compareTo(b.value!),
                ), // Ordenar códigos
            onChanged: (value) {
              setState(() {
                _codigoPais = value ?? '+591 🇧🇴';
                // Encontrar el primer país con este código
                _paisSeleccionado = _codigosPais.entries
                    .firstWhere(
                      (entry) => entry.value == _codigoPais,
                      orElse: () => const MapEntry('Bolivia', '+591 🇧🇴'),
                    )
                    .key;
              });
            },
            icon: const Icon(
              Icons.arrow_drop_down,
              size: 16,
            ), // Icono más pequeño
            style: TextStyle(color: Colors.orange[600], fontSize: 13),
            isExpanded: true, // Para que el texto se ajuste mejor
          ),
        ),
        // Campo de número de teléfono
        Expanded(
          child: TextFormField(
            controller: _celularController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Número Celular',
              prefixIcon: Icon(Icons.phone, color: Colors.orange[600]),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                borderSide: BorderSide(color: Colors.orange[600]!),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[600]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[600]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _celularController.dispose();
    _fechaNacimientoController.dispose();
    _correoController.dispose();
    super.dispose();
  }
}
