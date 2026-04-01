import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/presentation/pages/main_navigation_shell.dart';
import 'package:maternal_infant_care/presentation/pages/onboarding_page.dart';
import 'package:maternal_infant_care/presentation/pages/pregnancy_setup_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Wait for the animation and a minimum delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session != null) {
        final metadata = session.user.userMetadata;
        final isPregnant = metadata?['is_pregnant'] == true || metadata?['role'] == 'pregnant';
        final type = isPregnant ? UserProfileType.pregnant : UserProfileType.toddlerParent;
        
        // Update the state provider
        ref.read(userProfileProvider.notifier).state = type;
        
        // If they are pregnant but haven't finished setup (no start_date), go to setup
        final hasStartDate = metadata?['start_date'] != null;
        
        Widget nextStep;
        if (isPregnant && !hasStartDate) {
          nextStep = const PregnancySetupPage();
        } else {
          nextStep = const MainNavigationShell();
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextStep,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const OnboardingPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );      
      }
    } catch (e) {
      // Fallback to onboarding if something goes wrong
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/icons/logo.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.favorite, size: 80, color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Vatsalya',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
