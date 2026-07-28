import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      titleGray: 'Bienvenue sur',
      titleGreen: 'Myreklam',
      image: 'assets/images/onboarding/o1 1.png',
      description:
          'Bons plans, emplois, formations et événements partagés entre membres de confiance.',
    ),
    OnboardingData(
      titleGray: 'Sur Myreklam, votre engagement est valorisé',
      titleGreen: 'Comment ca marche?',
      image: 'assets/images/onboarding/o1 1 (1).png',
      description:
          'Trouvez, partagez et recommandez des services de confiance au sein d\'un réseau local fiable.',
    ),
    OnboardingData(
      titleGray: 'Transformer vos recommandations en',
      titleGreen: 'Réseau digital',
      image: 'assets/images/onboarding/o1 1 (2).png',
      description:
          'Recommandez des professionnels et créez des connexions utiles. Votre réseau grandit à chaque interaction.',
    ),
    OnboardingData(
      titleGray: 'Chaque action',
      titleGreen: 'vous récompense',
      image: 'assets/images/onboarding/Group 164 1.png',
      description:
          'Partagez, postulez, recommandez ou participez et gagnez des my\'s à chaque action.',
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _skip();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (Back and Skip)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: _back,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1B8D4B),
                          size: 20,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                  GestureDetector(
                    onTap: _skip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Découvrir Myreklam',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            page.titleGray,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Manjari',

                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            page.titleGreen,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontFamily: 'Manjari',

                              color: Color(0xFF1B8D4B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Image.asset(
                            page.image,
                            height: 250,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 40),
                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Manjari',

                              color: Colors.grey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer (Indicators and Next Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: _currentPage == _pages.length - 1
                  ? SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _skip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8D4B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Découvrir Myreklam',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dot Indicators
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? const Color(0xFF1B8D4B)
                                    : const Color(0xFFEEEEEE),
                              ),
                            ),
                          ),
                        ),

                        // Next Button
                        GestureDetector(
                          onTap: _next,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1B8D4B),
                              border: Border.all(
                                color: const Color(
                                  0xFF1B8D4B,
                                ).withValues(alpha: 0.2),
                                width: 4,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String titleGray;
  final String titleGreen;
  final String image;
  final String description;

  OnboardingData({
    required this.titleGray,
    required this.titleGreen,
    required this.image,
    required this.description,
  });
}
