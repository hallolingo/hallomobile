import 'package:flutter/material.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
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

class _VerificationCodePageState extends State<VerificationCodePage> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _remainingTime = 300;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupFocusNodes();
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
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
    if (value.length == 1 && index < 5) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    if (_isCodeComplete()) {
      _verifyCode();
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
      if (widget.provider == 'email') {
        final emailAuthService =
            Provider.of<EmailAuthService>(context, listen: false);
        await emailAuthService.registerWithEmail(
          email: widget.email,
          password: widget.password!,
          name: widget.name!,
          verificationCode: _getVerificationCode(),
        );
      } else if (widget.provider == 'google') {
        final googleAuthService =
            Provider.of<GoogleAuthService>(context, listen: false);
        await googleAuthService.verifyGoogleUser(
          widget.email,
          _getVerificationCode(),
        );
      }

      for (var controller in _codeControllers) {
        controller.clear();
      }

      Navigator.pushReplacementNamed(context, AppRouter.router);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kod gönderilemedi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'E-posta Doğrulama',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Doğrulama Kodunu Girin',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: ColorConstants.MAINCOLOR,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.email} adresine gönderilen 6 haneli kodu girin',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: ColorConstants.MAINCOLOR),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'E-postayı göremiyorsanız, lütfen spam veya gereksiz posta klasörünüzü kontrol edin.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) {
                  return Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _codeControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (value) => _onCodeChanged(index, value),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.MAINCOLOR,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Doğrula',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _remainingTime > 0
                      ? 'Tekrar gönder (${_formatTime(_remainingTime)})'
                      : 'Kodu tekrar gönder',
                  style: TextStyle(
                    fontSize: 16,
                    color: _remainingTime > 0
                        ? Colors.grey
                        : ColorConstants.MAINCOLOR,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_isResending && _remainingTime == 0)
                  TextButton(
                    onPressed: _resendCode,
                    child: Text(
                      'Gönder',
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorConstants.MAINCOLOR,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (_isResending)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ],
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
