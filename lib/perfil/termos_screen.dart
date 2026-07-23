import 'package:flutter/material.dart';

import '../theme.dart';

class TermosScreen extends StatelessWidget {
  const TermosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos de Uso e Privacidade')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Última atualização: julho de 2026',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                SizedBox(height: 20),
                _Secao(
                  titulo: '1. Quem somos',
                  texto:
                      'O spokfinRM é um aplicativo de gestão financeira voltado para '
                      'Microempreendedores Individuais (MEI). Dúvidas, solicitações ou '
                      'reclamações sobre privacidade podem ser enviadas para '
                      'spokfin@gmail.com.',
                ),
                _Secao(
                  titulo: '2. Quais dados coletamos',
                  texto:
                      'Do dono da conta: e-mail de login, razão social, nome fantasia, '
                      'telefone, CNPJ e/ou CPF (estes últimos opcionais). '
                      'Dos clientes e fornecedores que você cadastra no app: nome, '
                      'telefone e, no caso de fornecedores, chave PIX. Também '
                      'registramos os lançamentos financeiros (valores, categorias, '
                      'datas e descrições) que você insere.',
                ),
                _Secao(
                  titulo: '3. Para que usamos esses dados',
                  texto:
                      'Exclusivamente para operar o app: autenticação, exibição do seu '
                      'histórico financeiro, cálculo de saldo/balanço, geração de '
                      'recibos e relatórios, e para que a extração automática de '
                      'lançamentos por texto ou voz funcione. Não vendemos nem '
                      'compartilhamos seus dados com terceiros para fins de '
                      'publicidade.',
                ),
                _Secao(
                  titulo: '4. Com quem compartilhamos',
                  texto:
                      'Supabase: hospeda o banco de dados, autenticação e as funções '
                      'de servidor do app. OpenAI: processa, sob demanda, o texto ou '
                      'áudio que você envia para transformar em um lançamento '
                      'estruturado (recurso "Anotar"/"Falar") — nenhuma outra tela do '
                      'app envia dados para a OpenAI. Nenhum desses dois provedores '
                      'usa seus dados para treinar modelos ou para fins próprios.',
                ),
                _Secao(
                  titulo: '5. Por quanto tempo guardamos seus dados',
                  texto:
                      'Enquanto sua conta existir. Se você excluir sua conta pelo '
                      'próprio app (Perfil → Excluir Minha Conta), todos os dados '
                      'listados acima são apagados de forma imediata e definitiva — '
                      'não existe período de carência nem cópia de segurança mantida '
                      'após a exclusão.',
                ),
                _Secao(
                  titulo: '6. Seus direitos',
                  texto:
                      'Você pode acessar, corrigir ou excluir seus dados a qualquer '
                      'momento diretamente no app (telas de Clientes, Perfil) ou '
                      'solicitando por e-mail em spokfin@gmail.com. A exclusão da '
                      'conta é imediata e irreversível.',
                ),
                _Secao(
                  titulo: '7. Você também é responsável pelos dados que cadastra',
                  texto:
                      'Ao cadastrar clientes ou fornecedores no app (nome, telefone, '
                      'chave PIX), você atua como controlador desses dados perante a '
                      'LGPD — o spokfinRM apenas armazena essas informações a seu '
                      'pedido. Cabe a você garantir que tem uma base legal (ex: '
                      'relação comercial existente) para tratar os dados dessas '
                      'pessoas, e atender eventuais pedidos delas de acesso ou '
                      'exclusão.',
                ),
                _Secao(
                  titulo: '8. Termos de uso',
                  texto:
                      'O spokfinRM é uma ferramenta de apoio à gestão financeira e não '
                      'substitui um contador ou consultor tributário — os cálculos e '
                      'relatórios do app não têm valor fiscal ou contábil oficial. O '
                      'uso do app é de sua responsabilidade, incluindo a exatidão dos '
                      'lançamentos e informações inseridas.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
