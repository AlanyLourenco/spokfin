import 'package:flutter/material.dart';

import '../perfil/perfil_screen.dart';
import '../theme.dart';

/// A bolinha de perfil da barra superior.
///
/// Substitui o `IconButton(Icons.logout)` que estava em 4 telas de aba e
/// deslogava **sem confirmação** ao primeiro toque — sair da conta é ação
/// destrutiva e não pertence à barra principal, ao lado de ações comuns.
/// O logout continua existindo, dentro do Perfil, que é onde se procura por
/// ele.
class AvatarPerfil extends StatelessWidget {
  const AvatarPerfil({super.key, required this.empresaId, this.iniciais});

  final String empresaId;

  /// Iniciais do nome de exibição; quando ausente, mostra o ícone de pessoa.
  final String? iniciais;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Tooltip(
        message: 'Perfil',
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PerfilScreen(empresaId: empresaId),
            ),
          ),
          customBorder: const CircleBorder(),
          child: Semantics(
            button: true,
            label: 'Abrir perfil',
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
              ),
              child: iniciais == null
                  ? const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: AppColors.textMuted,
                    )
                  : Text(
                      iniciais!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
