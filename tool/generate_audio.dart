import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate Sound Effects', () {
    final dir = Directory('assets/audio');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

  const sampleRate = 44100;

  // 1. Generate Crow Caw Sound (Realistic throaty, resonant, modulated caws)
  final crowSamples = <double>[];
  crowSamples.addAll(List.filled((sampleRate * 0.05).toInt(), 0.0));

  List<double> generateCaw(double duration, double baseFreq) {
    final n = (sampleRate * duration).toInt();
    final list = <double>[];
    final random = Random(42);

    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final progress = i / n;
      final env = pow(sin(pi * progress), 0.75).toDouble();
      
      final f = baseFreq * (1.0 - 0.22 * progress);
      
      final vibrato = sin(2 * pi * 36 * t) * 0.35;
      final harm1 = sin(2 * pi * f * t + vibrato);
      final harm2 = sin(2 * pi * (f * 2.08) * t) * 0.65;
      final harm3 = sin(2 * pi * (f * 3.12) * t) * 0.45;
      final harm4 = sin(2 * pi * (f * 4.15) * t) * 0.25;
      final harshNoise = (random.nextDouble() * 2 - 1) * 0.3;
      
      final val = (harm1 + harm2 + harm3 + harm4 + harshNoise) * 0.32 * env;
      list.add(val);
    }
    return list;
  }

  // Double caw: "Caw! ... Caw!"
  crowSamples.addAll(generateCaw(0.42, 660));
  crowSamples.addAll(List.filled((sampleRate * 0.12).toInt(), 0.0));
  crowSamples.addAll(generateCaw(0.48, 600));

  writeWavFile('assets/audio/crow_caw.wav', crowSamples, sampleRate);
  print('Saved assets/audio/crow_caw.wav (${crowSamples.length} samples)');

  // 2. Generate Ocean Waves Sound (Gentle rolling tide & surf swell)
  final oceanSamples = <double>[];
  const oceanDur = 3.5;
  final nOcean = (sampleRate * oceanDur).toInt();
  final random = Random(123);
  double noiseAccum = 0.0;

  for (int i = 0; i < nOcean; i++) {
    final t = i / sampleRate;
    final progress = i / nOcean;
    final env = pow(sin(pi * progress), 1.6).toDouble();
    final tide = (sin(2 * pi * 0.35 * t) + 1.2) * 0.5;
    
    final white = random.nextDouble() * 2 - 1;
    noiseAccum = (noiseAccum * 0.96) + (white * 0.04);
    
    final hiss = (random.nextDouble() * 2 - 1) * 0.06 * (1.0 - progress * 0.4);
    final val = (noiseAccum * 2.8 + hiss) * env * tide * 0.45;
    oceanSamples.add(val);
  }

  writeWavFile('assets/audio/ocean_waves.wav', oceanSamples, sampleRate);
  print('Saved assets/audio/ocean_waves.wav (${oceanSamples.length} samples)');

  // 3. Generate Ship Bell Chime (Crisp double strike for interaction)
  final bellSamples = <double>[];
  List<double> generateBell(double duration, double freq) {
    final n = (sampleRate * duration).toInt();
    final list = <double>[];
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = exp(-4.5 * t);
      final val = (sin(2 * pi * freq * t) +
                   0.6 * sin(2 * pi * freq * 2.76 * t) +
                   0.3 * sin(2 * pi * freq * 5.4 * t)) * env * 0.3;
      list.add(val);
    }
    return list;
  }

  bellSamples.addAll(generateBell(0.8, 1200));
  bellSamples.addAll(List.filled((sampleRate * 0.1).toInt(), 0.0));
  bellSamples.addAll(generateBell(1.2, 1200));
  writeWavFile('assets/audio/ship_bell.wav', bellSamples, sampleRate);
  print('Saved assets/audio/ship_bell.wav (${bellSamples.length} samples)');
  });
}

void writeWavFile(String path, List<double> samples, int sampleRate) {
  final numSamples = samples.length;
  final byteData = ByteData(44 + numSamples * 2);

  // RIFF header
  byteData.setUint8(0, 0x52); // 'R'
  byteData.setUint8(1, 0x49); // 'I'
  byteData.setUint8(2, 0x46); // 'F'
  byteData.setUint8(3, 0x46); // 'F'
  byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
  byteData.setUint8(8, 0x57);  // 'W'
  byteData.setUint8(9, 0x41);  // 'A'
  byteData.setUint8(10, 0x56); // 'V'
  byteData.setUint8(11, 0x45); // 'E'

  // fmt chunk
  byteData.setUint8(12, 0x66); // 'f'
  byteData.setUint8(13, 0x6D); // 'm'
  byteData.setUint8(14, 0x74); // 't'
  byteData.setUint8(15, 0x20); // ' '
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little);
  byteData.setUint16(22, 1, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);

  // data chunk
  byteData.setUint8(36, 0x64); // 'd'
  byteData.setUint8(37, 0x61); // 'a'
  byteData.setUint8(38, 0x74); // 't'
  byteData.setUint8(39, 0x61); // 'a'
  byteData.setUint32(40, numSamples * 2, Endian.little);

  int offset = 44;
  for (final s in samples) {
    final clamped = s.clamp(-1.0, 1.0);
    final pcm = (clamped * 32767).round();
    byteData.setInt16(offset, pcm, Endian.little);
    offset += 2;
  }

  File(path).writeAsBytesSync(byteData.buffer.asUint8List());
}
