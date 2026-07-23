import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../empresa/empresa_setup_screen.dart';
import '../main.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';
import 'nova_senha_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _emRecuperacaoSenha = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _emRecuperacaoSenha = true);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? supabase.auth.currentSession;
        if (session == null) {
          return const LoginScreen();
        }
        if (_emRecuperacaoSenha) {
          return NovaSenhaScreen(
            onConcluido: () => setState(() => _emRecuperacaoSenha = false),
          );
        }
        return const _EmpresaGate();
      },
    );
  }
}

class _EmpresaGate extends StatefulWidget {
  const _EmpresaGate();

  @override
  State<_EmpresaGate> createState() => _EmpresaGateState();
}

class _EmpresaGateState extends State<_EmpresaGate> {
  late Future<Map<String, dynamic>?> _empresaFuture;

  @override
  void initState() {
    super.initState();
    _empresaFuture = _carregarEmpresa();
  }

  Future<Map<String, dynamic>?> _carregarEmpresa() async {
    final rows = await supabase
        .from('empresas')
        .select('id, razao_social, nome_fantasia')
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  void _recarregar() {
    setState(() {
      _empresaFuture = _carregarEmpresa();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _empresaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final empresa = snapshot.data;
        if (empresa == null) {
          return EmpresaSetupScreen(onEmpresaCriada: _recarregar);
        }
        final nome = (empresa['nome_fantasia'] as String?)?.isNotEmpty == true
            ? empresa['nome_fantasia'] as String
            : empresa['razao_social'] as String;
        return MainShell(
          empresaId: empresa['id'] as String,
          nomeExibicao: nome,
        );
      },
    );
  }
}
