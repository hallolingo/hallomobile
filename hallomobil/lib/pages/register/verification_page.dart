import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/register/register_constants.dart';
import 'package:hallomobil/services/auth/email_auth_service.dart';
import 'package:hallomobil/services/google/google_auth_service.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';

class VerificationCodePage extends StatefulWidget {
  final String email;
  final String? name;
  final String? password;
  final String provider;

  const VerificationCodePage({
    super.key,
    required this.email,
    this.name,
    this.password,
    required this.provider,
  });

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _remainingTime = 300;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupFocusNodes();

    // Page animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _logoAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Card animation setup
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_remainingTime > 0 && mounted) {
        setState(() => _remainingTime--);
        _startTimer();
      }
    });
  }

  void _setupFocusNodes() {
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _codeControllers[i].text.isEmpty) {
          _codeControllers[i].text = '';
        }
      });
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index].unfocus();
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  bool _isCodeComplete() {
    return _codeControllers.every((controller) => controller.text.isNotEmpty);
  }

  String _getVerificationCode() {
    return _codeControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyCode() async {
    if (!_isCodeComplete() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final emailAuthService =
          Provider.of<EmailAuthService>(context, listen: false);

      final userCredential = await emailAuthService.registerWithEmail(
        email: widget.email,
        password: widget.password!,
        name: widget.name!,
        verificationCode: _getVerificationCode(),
      );

      Navigator.pushReplacementNamed(
        context,
        AppRouter.languageSelection,
        arguments: {
          'userId': userCredential.user!.uid,
          'userEmail': widget.email,
        },
      );
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Hata: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_isResending || _remainingTime > 0) return;

    setState(() {
      _isResending = true;
      _remainingTime = 300;
    });

    try {
      if (widget.provider == 'email') {
        final emailAuthService =
            Provider.of<EmailAuthService>(context, listen: false);
        await emailAuthService.sendVerificationCode(widget.email);
      } else if (widget.provider == 'google') {
        final googleAuthService =
            Provider.of<GoogleAuthService>(context, listen: false);
        await googleAuthService.sendVerificationCode(widget.email);
      }
      showCustomSnackBar(
        context: context,
        message: 'Yeni doğrulama kodu gönderildi',
        isError: false,
      );
      _startTimer();
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Kod gönderilemedi: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Widget _buildGlassmorphicCard({
    required Widget child,
    EdgeInsets? margin,
  }) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, childWidget) {
        return Transform.scale(
          scale: 0.8 + (_cardAnimation.value * 0.2),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: childWidget,
          ),
        );
      },
      child: Container(
        margin:
            margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.MAINCOLOR.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildCodeInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required int index,
  }) {
    return Container(
      width: 46,
      height: 60,
      decoration: BoxDecoration(
        color: ColorConstants.MAINCOLOR.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focusNode.hasFocus
              ? ColorConstants.MAINCOLOR
              : ColorConstants.MAINCOLOR.withOpacity(0.1),
          width: focusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ColorConstants.TEXT_COLOR,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onCodeChanged(index, value),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  ColorConstants.MAINCOLOR,
                  ColorConstants.SECONDARY_COLOR,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: ColorConstants.MAINCOLOR.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color:
                          isPrimary ? Colors.white : ColorConstants.MAINCOLOR,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorConstants.SECONDARY_COLOR.withOpacity(0.1),
              Colors.white,
              ColorConstants.MAINCOLOR.withOpacity(0.05),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGlassmorphicCard(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header Icon and Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      ColorConstants.MAINCOLOR,
                                      ColorConstants.SECONDARY_COLOR,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.verified_user,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'E-posta Doğrulama',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstants.TEXT_COLOR,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Main Title
                          Text(
                            'Doğrulama Kodunu Girin',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.MAINCOLOR,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Subtitle
                          Text(
                            '${widget.email} adresine gönderilen 6 haneli kodu girin',
                            style: TextStyle(
                              fontSize: 16,
                              color: ColorConstants.TEXT_COLOR.withOpacity(0.7),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Info Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ColorConstants.MAINCOLOR.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    ColorConstants.MAINCOLOR.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: ColorConstants.MAINCOLOR,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'E-postayı göremiyorsanız, lütfen spam veya gereksiz posta klasörünüzü kontrol edin.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: ColorConstants.TEXT_COLOR
                                          .withOpacity(0.8),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Code Input Fields
                          Wrap(
                            spacing: 6,
                            children: List.generate(
                              6,
                              (index) => _buildCodeInputField(
                                controller: _codeControllers[index],
                                focusNode: _focusNodes[index],
                                index: index,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Verify Button
                          _buildGradientButton(
                            text: 'Doğrula',
                            onPressed: _verifyCode,
                            isPrimary: true,
                          ),
                          const SizedBox(height: 24),

                          // Resend Code Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_remainingTime > 0) ...[
                                Text(
                                  'Tekrar gönder (${_formatTime(_remainingTime)})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: ColorConstants.TEXT_COLOR
                                        .withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else ...[
                                if (!_isResending) ...[
                                  Text(
                                    'Kodu alamadınız mı? ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: ColorConstants.TEXT_COLOR
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _resendCode,
                                    child: Text(
                                      'Tekrar Gönder',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: ColorConstants.MAINCOLOR,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: ColorConstants.MAINCOLOR,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Gönderiliyor...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: ColorConstants.MAINCOLOR,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
}
