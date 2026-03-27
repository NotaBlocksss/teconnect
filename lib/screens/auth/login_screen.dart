import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../user/user_home_screen.dart';
import '../worker/worker_home_screen.dart';
import '../admin/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _documentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _documentFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  Size? _fixedScreenSize;
  
  late AnimationController _particlesController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  Ticker? _waveTicker;
  final ValueNotifier<double> _waveTimeNotifier = ValueNotifier<double>(0.0);

  static const Color _bluePrimary = Color(0xFF2196F3);
  static const Color _blueDark = Color(0xFF1976D2);
  static const Color _blueLight = Color(0xFF64B5F6);

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final mediaQuery = MediaQuery.of(context);
        _fixedScreenSize = mediaQuery.size;
        setState(() {});
      }
    });
    
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    
    _waveTicker = Ticker((elapsed) {
      _waveTimeNotifier.value = elapsed.inMilliseconds.toDouble() / 1000.0;
    });
    _waveTicker?.start();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    _documentFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _documentController.dispose();
    _passwordController.dispose();
    _documentFocusNode.dispose();
    _passwordFocusNode.dispose();
    _particlesController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    _waveTicker?.dispose();
    _waveTimeNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithDocument(
        _documentController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        final user = authProvider.currentUser;
        if (user != null) {
          _navigateByRole(user.role);
        } else {
          _showErrorSnackBar('Error: Usuario no encontrado después del login');
        }
      } else {
        _showErrorSnackBar('Credenciales incorrectas');
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Error al iniciar sesión';
      if (e.toString().contains('Credenciales inválidas')) {
        errorMessage = 'Credenciales inválidas. Verifica tu número de documento y contraseña.';
      } else if (e.toString().contains('Usuario no encontrado')) {
        errorMessage = 'Usuario no encontrado en la base de datos. Contacta al administrador.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Contraseña incorrecta.';
      } else if (e.toString().contains('user-not-found')) {
        errorMessage = 'Usuario no encontrado.';
      }
      
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(20),
        elevation: 10,
      ),
    );
  }

  void _navigateByRole(String role) {
    Widget screen;
    switch (role) {
      case 'admin':
        screen = const AdminHomeScreen();
        break;
      case 'worker':
        screen = const WorkerHomeScreen();
        break;
      default:
        screen = const UserHomeScreen();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = _fixedScreenSize ?? mediaQuery.size;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: screenSize.width,
            height: screenSize.height,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _bluePrimary,
                    _blueDark,
                    const Color(0xFF1565C0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          
          Positioned(
            left: 0,
            top: 0,
            width: screenSize.width,
            height: screenSize.height,
            child: AnimatedBuilder(
              animation: Listenable.merge([_particlesController, _waveController, _glowController]),
              builder: (context, child) {
                return CustomPaint(
                  size: screenSize,
                  painter: EnhancedBackgroundPainter(
                    particlesProgress: _particlesController.value,
                    waveProgress: _waveController.value,
                    glowProgress: _glowController.value,
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            left: 0,
            top: 0,
            width: screenSize.width,
            height: screenSize.height,
            child: AnimatedBuilder(
              animation: _waveTimeNotifier,
              builder: (context, child) {
                return CustomPaint(
                  size: screenSize,
                  painter: RefinedWavePainter(waveTime: _waveTimeNotifier.value),
                );
              },
            ),
          ),
          
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          
                          const SizedBox(height: 48),
                          
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildDocumentField(),
                                
                                const SizedBox(height: 24),
                                
                                _buildPasswordField(),
                                
                                const SizedBox(height: 32),
                                
                                _buildLoginButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: _bluePrimary.withOpacity(0.4),
                blurRadius: 50,
                spreadRadius: 15,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logologin.png',
            width: 90,
            height: 90,
            fit: BoxFit.contain,
          ),
        ),
        
        const SizedBox(height: 32),
        
        Text(
          'Hola!',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1.5,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        Text(
          'Inicia sesión en tu cuenta',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.3,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDocumentField() {
    final hasFocus = _documentFocusNode.hasFocus;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: hasFocus
                ? _bluePrimary.withOpacity(0.25)
                : Colors.black.withOpacity(0.08),
            blurRadius: hasFocus ? 25 : 12,
            offset: Offset(0, hasFocus ? 10 : 5),
            spreadRadius: hasFocus ? 3 : 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: _documentController,
        focusNode: _documentFocusNode,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) {
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        },
        style: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'C.C',
          hintText: '1234567890',
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.black38,
          ),
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasFocus ? _bluePrimary : Colors.black54,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: hasFocus
                  ? LinearGradient(
                      colors: [
                        _bluePrimary.withOpacity(0.15),
                        _blueLight.withOpacity(0.1),
                      ],
                    )
                  : null,
              color: hasFocus ? null : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: hasFocus
                  ? Border.all(
                      color: _bluePrimary.withOpacity(0.3),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Icon(
              Icons.badge_outlined,
              color: hasFocus ? _bluePrimary : Colors.black54,
              size: 24,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: _bluePrimary,
              width: 2.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppTheme.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppTheme.error,
              width: 2.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingresa tu número de documento';
          }
          if (value.length < 7) {
            return 'Número de documento inválido';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    final hasFocus = _passwordFocusNode.hasFocus;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: hasFocus
                ? _bluePrimary.withOpacity(0.25)
                : Colors.black.withOpacity(0.08),
            blurRadius: hasFocus ? 25 : 12,
            offset: Offset(0, hasFocus ? 10 : 5),
            spreadRadius: hasFocus ? 3 : 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        focusNode: _passwordFocusNode,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _handleLogin(),
        style: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: '••••••••',
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.black38,
            letterSpacing: 2,
          ),
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasFocus ? _bluePrimary : Colors.black54,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: hasFocus
                  ? LinearGradient(
                      colors: [
                        _bluePrimary.withOpacity(0.15),
                        _blueLight.withOpacity(0.1),
                      ],
                    )
                  : null,
              color: hasFocus ? null : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: hasFocus
                  ? Border.all(
                      color: _bluePrimary.withOpacity(0.3),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: hasFocus ? _bluePrimary : Colors.black54,
              size: 24,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.only(right: 14, top: 14, bottom: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.withOpacity(0.12),
                        Colors.grey.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.black54,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: _bluePrimary,
              width: 2.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppTheme.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppTheme.error,
              width: 2.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingresa tu contraseña';
          }
          if (value.length < 6) {
            return 'Mínimo 6 caracteres';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLoginButton() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          height: 62,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _bluePrimary,
                _blueDark,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _bluePrimary.withOpacity(0.5 + _glowController.value * 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: _bluePrimary.withOpacity(0.3 + _glowController.value * 0.1),
                blurRadius: 50,
                offset: const Offset(0, 25),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _handleLogin,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.login_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Iniciar Sesión',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class EnhancedBackgroundPainter extends CustomPainter {
  final double particlesProgress;
  final double waveProgress;
  final double glowProgress;

  EnhancedBackgroundPainter({
    required this.particlesProgress,
    required this.waveProgress,
    required this.glowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particleCount = 30;
    final random = math.Random(456);

    for (int i = 0; i < particleCount; i++) {
      final baseX = size.width * (random.nextDouble());
      final baseY = size.height * (random.nextDouble());
      final phase = (particlesProgress + i / particleCount) % 1.0;
      
      final x = baseX + math.sin(phase * 2 * math.pi + i) * 25;
      final y = baseY + math.cos(phase * 2 * math.pi + i) * 25;
      final particleSize = 2.5 + random.nextDouble() * 3.5;
      final opacity = (0.12 + random.nextDouble() * 0.18) * (1 - phase * 0.4);

      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }

    final centerX = size.width * 0.3;
    final centerY = size.height * 0.2;
    final glowRadius = 150.0 + glowProgress * 50;

    final glowRect = Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: glowRadius,
    );

    final glowGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.white.withOpacity(0.15 * glowProgress),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    );

    final glowPaint = Paint()
      ..shader = glowGradient.createShader(glowRect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), glowRadius, glowPaint);
  }

  @override
  bool shouldRepaint(EnhancedBackgroundPainter oldDelegate) {
    return oldDelegate.particlesProgress != particlesProgress ||
        oldDelegate.waveProgress != waveProgress ||
        oldDelegate.glowProgress != glowProgress;
  }
}

class RefinedWavePainter extends CustomPainter {
  final double waveTime;

  RefinedWavePainter({required this.waveTime});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final waveSpeed = 0.35;
    final waveOffset = waveTime * waveSpeed * 2 * math.pi;
    
    final startY = size.height * 0.48;

    final path = Path();
    path.moveTo(0, startY);
    
    final waveOffset1 = waveOffset;
    final waveOffset2 = waveTime * waveSpeed * 1.25 * 2 * math.pi;
    final waveOffset3 = waveTime * waveSpeed * 1.6 * 2 * math.pi;
    final waveOffset4 = waveTime * waveSpeed * 2.0 * 2 * math.pi;
    final waveOffset5 = waveTime * waveSpeed * 2.45 * 2 * math.pi;
    
    final points = <Offset>[];
    
    for (double x = 0; x <= size.width; x += 0.5) {
      final progress = x / size.width;
      
      final freq1 = progress * 2 * math.pi * 1.6;
      final wave1 = math.sin(freq1 + waveOffset1) * 26.0;
      
      final freq2 = progress * 2 * math.pi * 2.2;
      final wave2 = math.sin(freq2 + waveOffset2) * 22.0;
      
      final freq3 = progress * 2 * math.pi * 3.0;
      final wave3 = math.sin(freq3 + waveOffset3) * 18.0;
      
      final freq4 = progress * 2 * math.pi * 3.9;
      final wave4 = math.sin(freq4 + waveOffset4) * 14.0;
      
      final freq5 = progress * 2 * math.pi * 5.1;
      final wave5 = math.sin(freq5 + waveOffset5) * 10.0;
      
      final amplitudeVariation = 1.0 + math.sin(progress * math.pi * 2.5 + waveTime * 0.25) * 0.12;
      
      final combinedWave = (wave1 * 0.32 + wave2 * 0.26 + wave3 * 0.22 + wave4 * 0.13 + wave5 * 0.07) * amplitudeVariation;
      final y = startY + combinedWave;
      
      points.add(Offset(x, y));
    }
    
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      
      for (int i = 1; i < points.length; i++) {
        final prevPoint = points[i - 1];
        final currentPoint = points[i];
        
        final controlPointX = (prevPoint.dx + currentPoint.dx) / 2;
        final controlPointY = (prevPoint.dy + currentPoint.dy) / 2;
        
        if (i == 1) {
          path.lineTo(controlPointX, controlPointY);
        }
        
        path.quadraticBezierTo(
          prevPoint.dx,
          prevPoint.dy,
          controlPointX,
          controlPointY,
        );
      }
      
      path.lineTo(points.last.dx, points.last.dy);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RefinedWavePainter oldDelegate) {
    return oldDelegate.waveTime != waveTime;
  }
}
