import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../routes/app_routes.dart';
import '../../services/api/api_exception.dart';
import '../../services/api/auth_api_service.dart';
import '../../services/storage/secure_storage_service.dart';
import 'phone_input_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();
  final SecureStorageService _storageService = SecureStorageService();

  bool _isSubmitting = false;
  String? _errorMessage;
  late OtpVerificationScreenArgs _args;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is OtpVerificationScreenArgs) {
      _args = arguments;
    } else {
      _args = const OtpVerificationScreenArgs(phoneNumber: '');
    }
    _didInit = true;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification du code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Un code a ete envoye au ${_args.phoneNumber}. Entrez-le pour vous connecter.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Code OTP',
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_open_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le code recu.';
                  }
                  if (value.trim().length < 4) {
                    return 'Code OTP invalide.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: Text(_isSubmitting ? 'Verification...' : 'Valider'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: const Text('Modifier le numero'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final code = _otpController.text.trim();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _authApiService.verifyOtp(
        phoneNumber: _args.phoneNumber,
        otpCode: code,
      );

      await _storageService.saveSession(
        token: result.token,
        role: result.role,
        phoneNumber: _args.phoneNumber,
      );

      if (!mounted) return;
      _navigateAccordingToRole(result.role);
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } on UnimplementedError {
      setState(() {
        _errorMessage = 'Verification OTP non disponible pour le moment.';
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Impossible de verifier le code. Reessayez.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _navigateAccordingToRole(UserRole role) {
    final String target;
    if (role == UserRole.artisan) {
      target = AppRoutes.artisanDashboard;
    } else {
      target = AppRoutes.home;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(target, (route) => false);
  }
}
