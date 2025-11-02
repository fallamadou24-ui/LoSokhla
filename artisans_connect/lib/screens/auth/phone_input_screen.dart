import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/api/api_exception.dart';
import '../../services/api/auth_api_service.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion par telephone')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrez votre numero de telephone pour recevoir un code de connexion.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numero de telephone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un numero de telephone.';
                  }
                  if (value.trim().length < 8) {
                    return 'Numero de telephone invalide.';
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_to_mobile_outlined),
                  label: Text(_isSubmitting ? 'Envoi du code...' : 'Recevoir le code'),
                ),
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

    final phone = _phoneController.text.trim();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _authApiService.requestOtp(phoneNumber: phone);
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        AppRoutes.authOtp,
        arguments: OtpVerificationScreenArgs(phoneNumber: phone),
      );
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } on UnimplementedError {
      setState(() {
        _errorMessage = 'Service OTP non disponible pour le moment.';
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Une erreur est survenue. Merci de reessayer.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

class OtpVerificationScreenArgs {
  const OtpVerificationScreenArgs({required this.phoneNumber});

  final String phoneNumber;
}
