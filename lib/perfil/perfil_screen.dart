import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../shared/campo_rotulado.dart';
import '../shared/formatters.dart';
import '../shared/mascaras.dart';
import '../theme.dart';
import 'termos_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _razaoSocialController;
  late final TextEditingController _nomeFantasiaController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _cpfController;
  bool _carregando = true;
  bool _salvando = false;
  bool _excluindo = false;
  String? _erro;

  String get _email => supabase.auth.currentUser?.email ?? '';

  String get _iniciais => iniciaisDoNome(_razaoSocialController.text);

  @override
  void initState() {
    super.initState();
    _razaoSocialController = TextEditingController();
    _nomeFantasiaController = TextEditingController();
    _telefoneController = TextEditingController();
    _cnpjController = TextEditingController();
    _cpfController = TextEditingController();
    _carregar();
  }

  @override
  void dispose() {
    _razaoSocialController.dispose();
    _nomeFantasiaController.dispose();
    _telefoneController.dispose();
    _cnpjController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final empresa = await supabase
        .from('empresas')
        .select()
        .eq('id', widget.empresaId)
        .single();
    setState(() {
      _razaoSocialController.text = empresa['razao_social'] as String? ?? '';
      _nomeFantasiaController.text = empresa['nome_fantasia'] as String? ?? '';
      _telefoneController.text = empresa['telefone'] as String? ?? '';
      _cnpjController.text = empresa['cnpj'] as String? ?? '';
      _cpfController.text = empresa['cpf'] as String? ?? '';
      _carregando = false;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await supabase
          .from('empresas')
          .update({
            'razao_social': _razaoSocialController.text.trim(),
            'nome_fantasia': _nomeFantasiaController.text.trim().isEmpty
                ? null
                : _nomeFantasiaController.text.trim(),
            'telefone': _telefoneController.text.trim().isEmpty
                ? null
                : _telefoneController.text.trim(),
            'cnpj': _cnpjController.text.trim().isEmpty
                ? null
                : _cnpjController.text.trim(),
            'cpf': _cpfController.text.trim().isEmpty
                ? null
                : _cpfController.text.trim(),
          })
          .eq('id', widget.empresaId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil atualizado')));
      }
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _abrirTermos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TermosScreen()),
    );
  }

  Future<void> _confirmarExclusaoConta() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir sua conta?'),
        content: const Text(
          'Isso vai apagar permanentemente sua empresa, clientes, fornecedores, '
          'lançamentos, assinaturas e encarregados, além da sua conta de login. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.negative),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir minha conta'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    setState(() {
      _excluindo = true;
      _erro = null;
    });
    try {
      await supabase.functions.invoke('excluir-conta');
      await supabase.auth.signOut();
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _excluindo = false;
      });
    }
  }

  InputDecoration _decoracao(String hint) => InputDecoration(hintText: hint);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.surfaceAlt,
                            child: Text(
                              _iniciais,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _razaoSocialController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            _email,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const RotuloCard(
                      'INFORMAÇÕES PESSOAIS',
                      letterSpacing: 1,
                      negrito: true,
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CampoRotulado(
                            rotulo: 'Nome / Razão Social',
                            child: TextFormField(
                              controller: _razaoSocialController,
                              decoration: _decoracao('Ex: Padaria do João'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Obrigatório'
                                  : null,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CampoRotulado(
                            rotulo: 'Nome fantasia (opcional)',
                            child: TextFormField(
                              controller: _nomeFantasiaController,
                              decoration: _decoracao('Como o cliente te conhece'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const CampoRotulado(
                            rotulo: 'E-mail',
                            child: _CampoSomenteLeitura(),
                          ),
                          const SizedBox(height: 16),
                          CampoRotulado(
                            rotulo: 'Telefone (opcional)',
                            child: TextFormField(
                              controller: _telefoneController,
                              decoration: _decoracao('(00) 00000-0000'),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [TelefoneInputFormatter()],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                return telefoneValido(v)
                                    ? null
                                    : 'Telefone inválido';
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          CampoRotulado(
                            rotulo: 'CNPJ (opcional)',
                            child: TextFormField(
                              controller: _cnpjController,
                              decoration: _decoracao('00.000.000/0000-00'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [CpfCnpjInputFormatter()],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                return cnpjValido(v) ? null : 'CNPJ inválido';
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          CampoRotulado(
                            rotulo: 'CPF (opcional)',
                            child: TextFormField(
                              controller: _cpfController,
                              decoration: _decoracao('000.000.000-00'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [CpfCnpjInputFormatter()],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                return cpfValido(v) ? null : 'CPF inválido';
                              },
                            ),
                          ),
                          if (_erro != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _erro!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _salvando ? null : _salvar,
                            child: _salvando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Salvar'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const RotuloCard(
                      'SUPORTE & INFORMAÇÕES',
                      letterSpacing: 1,
                      negrito: true,
                    ),
                    const SizedBox(height: 8),
                    _ItemPerfil(
                      icon: Icons.description_outlined,
                      label: 'Termos de Uso e Privacidade',
                      onTap: _abrirTermos,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'ZONA DE PERIGO',
                      style: TextStyle(
                        color: AppColors.negative,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ItemPerfil(
                      icon: Icons.delete_forever_outlined,
                      label: 'Excluir Minha Conta',
                      corDestaque: AppColors.negative,
                      loading: _excluindo,
                      onTap: _excluindo ? null : _confirmarExclusaoConta,
                    ),
                    const SizedBox(height: 10),
                    _ItemPerfil(
                      icon: Icons.logout,
                      label: 'Sair',
                      onTap: () => supabase.auth.signOut(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CampoSomenteLeitura extends StatelessWidget {
  const _CampoSomenteLeitura();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        supabase.auth.currentUser?.email ?? '',
        style: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}

class _ItemPerfil extends StatelessWidget {
  const _ItemPerfil({
    required this.icon,
    required this.label,
    required this.onTap,
    this.corDestaque,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? corDestaque;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cor = corDestaque ?? AppColors.textPrimary;
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: corDestaque != null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: corDestaque!.withValues(alpha: 0.4)),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, size: 18, color: cor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(color: cor)),
              ),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right, size: 18, color: cor),
            ],
          ),
        ),
      ),
    );
  }
}
