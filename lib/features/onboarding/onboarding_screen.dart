import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Aquí va tu navegación final usando go_router
      //context.go('/home'); 
      print("Ir a la pantalla principal");
    }
  }

  void _skip() {
    _pageController.jumpToPage(onboardingData.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Fondo oscuro general
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: onboardingData.length,
        itemBuilder: (context, index) {
          final data = onboardingData[index];
          return Column(
            children: [
              // --- SECCIÓN SUPERIOR (Visual) ---
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: data.topColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: data.topVisual,
                    ),
                  ),
                ),
              ),
              
              // --- SECCIÓN INFERIOR (Textos y Botones) ---
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indicador de página
                      Row(
                        children: List.generate(
                          onboardingData.length,
                          (dotIndex) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: _currentPage == dotIndex ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == dotIndex 
                                  ? data.buttonColor 
                                  : Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Título
                      Text(
                        data.title,
                        style: TextStyle(
                          color: data.buttonColor, // El título toma el color de la página
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Descripción
                      Text(
                        data.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Botón Principal
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: data.buttonColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            data.buttonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      // Botón de Saltar (Solo se muestra si la data lo indica)
                      if (data.showSkip)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Center(
                            child: TextButton(
                              onPressed: _skip,
                              child: const Text(
                                "Saltar",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 56), // Espaciador para igualar alturas
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- MODELO DE DATOS Y WIDGETS FALSOS PARA REPLICAR TU DISEÑO ---

class OnboardingData {
  final Color topColor;
  final Color buttonColor;
  final Widget topVisual;
  final String title;
  final String description;
  final String buttonText;
  final bool showSkip;

  OnboardingData({
    required this.topColor,
    required this.buttonColor,
    required this.topVisual,
    required this.title,
    required this.description,
    required this.buttonText,
    this.showSkip = false,
  });
}

final List<OnboardingData> onboardingData = [
  // PÁGINA 1
  OnboardingData(
    topColor: const Color(0xFF194073), // Azul oscuro
    buttonColor: const Color(0xFF3865A7), // Azul botón
    title: "Bienvenido a\nHandWave",
    description: "La primera herramienta de comunicación para personas con discapacidad auditiva en retail peruano.",
    buttonText: "Siguiente",
    showSkip: true,
    topVisual: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF3865A7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.back_hand, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text("HandWave", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const Text("Comunicación sin barreras", style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    ),
  ),

  // PÁGINA 2
  OnboardingData(
    topColor: const Color(0xFF1D7863), // Verde/Teal
    buttonColor: const Color(0xFF1D7863),
    title: "Comunícate con señas",
    description: "Usa la cámara para hacer señas en Lengua de Señas Peruana. HandWave las traduce a texto automáticamente.",
    buttonText: "Siguiente",
    topVisual: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.touch_app, color: Colors.white, size: 80),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0D66E), // Amarillo Mostaza
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text("LSP Peruano", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    ),
  ),

  // PÁGINA 3
  OnboardingData(
    topColor: const Color(0xFF6729CC), // Morado
    buttonColor: const Color(0xFF6729CC),
    title: "El vendedor te\nresponde",
    description: "La respuesta aparece transcrita en pantalla en tiempo real. Sin barreras.",
    buttonText: "Siguiente",
    topVisual: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Simulación de chat bubble
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF8B4CF6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TÚ - LSP", style: TextStyle(color: Colors.white70, fontSize: 10)),
              SizedBox(height: 4),
              Text("¿Cuánto cuesta?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Icon(Icons.arrow_downward, color: Colors.white54),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF9E7CFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Vendedor -> Transcripción", style: TextStyle(color: Colors.white70, fontSize: 10)),
              SizedBox(height: 4),
              Text("Son S/. 89.90 ¿boleta?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    ),
  ),

  // PÁGINA 4
  OnboardingData(
    topColor: const Color(0xFF288540), // Verde brillante
    buttonColor: const Color(0xFF288540),
    title: "Encuentra locales\ninclusivos",
    description: "El Radar HandWave muestra qué tiendas tienen el sistema activo cerca de ti.",
    buttonText: "Empezar ahora",
    topVisual: Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white30, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Stack(
          children: [
             // Simulando las líneas del radar
             Center(child: VerticalDivider(color: Colors.white30, width: 1)),
             Center(child: Divider(color: Colors.white30, height: 1)),
             Positioned(top: 30, left: 30, child: Icon(Icons.circle, color: Colors.white54, size: 10)),
             Positioned(top: 60, left: 80, child: Icon(Icons.circle, color: Colors.pinkAccent, size: 12)),
             Positioned(top: 100, right: 40, child: Icon(Icons.circle, color: Colors.pinkAccent, size: 12)),
          ],
        ),
      ),
    ),
  ),
];
