import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../theme.dart';
import 'ia_service.dart';
import 'revisar_lancamento_screen.dart';
import 'wav_encoder.dart';
import 'waveform.dart';

const _sampleRate = 16000;

class FalarScreen extends StatefulWidget {
  const FalarScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<FalarScreen> createState() => _FalarScreenState();
}

class _FalarScreenState extends State<FalarScreen> {
  static const _limiteSegundos = 40;
  static const _quantidadeBarras = 28;

  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final BytesBuilder _audioBytes = BytesBuilder();
  Timer? _limiteTimer;
  List<double> _niveis = List.filled(_quantidadeBarras, 0.05);
  bool _gravando = false;
  bool _processando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciarGravacao();
  }

  Future<void> _iniciarGravacao() async {
    try {
      if (!await _recorder.hasPermission()) {
        setState(() => _error = 'Permissão de microfone negada.');
        return;
      }
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );
      if (!mounted) return;
      setState(() => _gravando = true);
      _subscription = stream.listen((chunk) => _audioBytes.add(chunk));
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amp) {
            final nivel = ((amp.current + 45) / 45).clamp(0.0, 1.0);
            setState(() {
              _niveis = [..._niveis.skip(1), nivel];
            });
          });
      var segundosDecorridos = 0;
      _limiteTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        segundosDecorridos++;
        if (segundosDecorridos >= _limiteSegundos) {
          timer.cancel();
          _concluir();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Não consegui acessar o microfone: $e');
      }
    }
  }

  Future<LancamentoExtraido?> _processarComRetry(Uint8List wavBytes) async {
    for (var tentativa = 0; tentativa < 2; tentativa++) {
      try {
        final texto = await transcreverAudio(wavBytes, mimeType: 'audio/wav');
        return await extrairLancamento(texto);
      } catch (_) {
        if (tentativa == 1) return null;
      }
    }
    return null;
  }

  Future<void> _concluir() async {
    _limiteTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    await _subscription?.cancel();
    await _recorder.stop();
    if (!mounted) return;

    final bytes = _audioBytes.takeBytes();
    if (bytes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _gravando = false;
      _processando = true;
    });

    final wavBytes = envolverPcmEmWav(
      bytes,
      sampleRate: _sampleRate,
      numChannels: 1,
    );
    final lancamento = await _processarComRetry(wavBytes);
    if (!mounted) return;
    setState(() => _processando = false);

    final entrada =
        lancamento ??
        LancamentoExtraido(
          tipo: 'entrada',
          valor: 0,
          descricao: '',
          categoria: '',
          status: 'pago',
          querNotaFiscal: false,
        );
    if (lancamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não consegui entender o áudio — preencha manualmente.',
          ),
        ),
      );
    }

    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RevisarLancamentoScreen(
          empresaId: widget.empresaId,
          lancamento: entrada,
        ),
      ),
    );
    if (salvou == true && mounted) Navigator.of(context).pop();
  }

  void _sair() {
    _limiteTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _subscription?.cancel();
    _recorder.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _limiteTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _subscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_gravando ? 'Escutando...' : 'Falar'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _sair),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_gravando) ...[
                  const Text(
                    'ESCUTANDO...',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Waveform(niveis: _niveis),
                  const SizedBox(height: 12),
                  Text(
                    'Fale naturalmente...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ] else if (_processando) ...[
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Processando...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ] else if (_error == null) ...[
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Preparando microfone...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() => _error = null);
                      _iniciarGravacao();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _processando ? null : _concluir,
                  child: _processando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Concluir'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
