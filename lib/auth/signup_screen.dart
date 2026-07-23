import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../perfil/termos_screen.dart';
import '../shared/campo_rotulado.dart';
import '../theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _confirmationSent = false;
  bool _aceitouTermos = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _abrirTermos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TermosScreen()),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_aceitouTermos) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'termos_aceitos_em': DateTime.now().toUtc().toIso8601String()},
      );
      if (res.session == null) {
        setState(() => _confirmationSent = true);
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _confirmationSent
                ? const Text(
                    'Enviamos um e-mail de confirmação. Confirme para poder entrar.',
                    textAlign: TextAlign.center,
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CampoRotulado(
                          rotulo: 'E-mail',
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              hintText: 'voce@exemplo.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'E-mail inválido'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CampoRotulado(
                          rotulo: 'Senha',
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              hintText: '••••••',
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _aceitouTermos,
                              onChanged: (v) =>
                                  setState(() => _aceitouTermos = v ?? false),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _aceitouTermos = !_aceitouTermos,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Li e aceito os '),
                                        TextSpan(
                                          text:
                                              'Termos de Uso e a Política de Privacidade',
                                          style: const TextStyle(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          recognizer:
                                              (TapGestureRecognizer()
                                                ..onTap = _abrirTermos),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: (_loading || !_aceitouTermos)
                              ? null
                              : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Criar conta'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
