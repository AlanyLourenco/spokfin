import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spokfin/lancamentos/wav_encoder.dart';

void main() {
  group('envolverPcmEmWav', () {
    test('produz um cabeçalho WAV de 44 bytes seguido dos dados PCM', () {
      final pcm = Uint8List.fromList(List.generate(100, (i) => i % 256));
      final wav = envolverPcmEmWav(pcm, sampleRate: 16000, numChannels: 1);

      expect(wav.length, 44 + pcm.length);
      expect(wav.sublist(44), pcm);
    });

    test('marca RIFF/WAVE/fmt /data nos offsets corretos', () {
      final pcm = Uint8List.fromList([1, 2, 3, 4]);
      final wav = envolverPcmEmWav(pcm);

      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(wav.sublist(12, 16)), 'fmt ');
      expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    });

    test('grava sampleRate, numChannels e bitsPerSample corretamente', () {
      final pcm = Uint8List.fromList([0, 0]);
      final wav = envolverPcmEmWav(
        pcm,
        sampleRate: 44100,
        numChannels: 2,
        bitsPerSample: 16,
      );
      final data = wav.buffer.asByteData();

      expect(data.getUint16(22, Endian.little), 2); // numChannels
      expect(data.getUint32(24, Endian.little), 44100); // sampleRate
      expect(data.getUint16(34, Endian.little), 16); // bitsPerSample
      // byteRate = sampleRate * numChannels * bitsPerSample / 8
      expect(data.getUint32(28, Endian.little), 44100 * 2 * 16 ~/ 8);
      // blockAlign = numChannels * bitsPerSample / 8
      expect(data.getUint16(32, Endian.little), 2 * 16 ~/ 8);
    });

    test('grava o tamanho dos dados PCM no chunk "data"', () {
      final pcm = Uint8List.fromList(List.filled(1000, 7));
      final wav = envolverPcmEmWav(pcm);
      final data = wav.buffer.asByteData();

      expect(data.getUint32(40, Endian.little), pcm.length);
      expect(data.getUint32(4, Endian.little), 36 + pcm.length);
    });

    test('funciona com PCM vazio', () {
      final wav = envolverPcmEmWav(Uint8List(0));
      expect(wav.length, 44);
    });
  });
}
