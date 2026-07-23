import 'dart:typed_data';

/// Envolve PCM16 cru (sem cabeçalho) num arquivo WAV válido, para envio ao Whisper.
Uint8List envolverPcmEmWav(
  Uint8List pcm, {
  int sampleRate = 16000,
  int numChannels = 1,
  int bitsPerSample = 16,
}) {
  final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  final blockAlign = numChannels * bitsPerSample ~/ 8;
  final dataSize = pcm.length;
  final chunkSize = 36 + dataSize;

  final header = BytesBuilder();
  void escreverAscii(String s) => header.add(s.codeUnits);
  void escreverUint32(int v) => header.add(
    Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little),
  );
  void escreverUint16(int v) => header.add(
    Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little),
  );

  escreverAscii('RIFF');
  escreverUint32(chunkSize);
  escreverAscii('WAVE');
  escreverAscii('fmt ');
  escreverUint32(16);
  escreverUint16(1); // PCM
  escreverUint16(numChannels);
  escreverUint32(sampleRate);
  escreverUint32(byteRate);
  escreverUint16(blockAlign);
  escreverUint16(bitsPerSample);
  escreverAscii('data');
  escreverUint32(dataSize);

  return Uint8List.fromList([...header.toBytes(), ...pcm]);
}
