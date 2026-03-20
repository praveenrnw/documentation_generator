import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class VideoProcessingService {
  Future<List<ExtractedFrame>> extractFrames({
    required String videoPath,
    int intervalSeconds = 3,
    int maxFrames = 20,
  }) async {
    final isWindows = Platform.isWindows;
    final checkCmd = isWindows ? 'where' : 'which';
    final which = await Process.run(checkCmd, ['ffmpeg']);
    if (which.exitCode != 0) {
      throw Exception(
        'ffmpeg not found. Please install ffmpeg:\n'
        '  macOS: brew install ffmpeg\n'
        '  Linux: sudo apt install ffmpeg\n'
        '  Windows: choco install ffmpeg',
      );
    }

    final duration = await _getVideoDuration(videoPath);
    if (duration == null) {
      throw Exception('Could not determine video duration');
    }

    final totalSeconds = duration.inSeconds;
    final actualInterval = totalSeconds > maxFrames * intervalSeconds
        ? (totalSeconds / maxFrames).ceil()
        : intervalSeconds;

    final tempDir = await getTemporaryDirectory();
    final framesDir = Directory(
      '${tempDir.path}/docgen_frames_${DateTime.now().millisecondsSinceEpoch}',
    );
    await framesDir.create(recursive: true);

    final frames = <ExtractedFrame>[];

    for (int i = 0; i < totalSeconds; i += actualInterval) {
      if (frames.length >= maxFrames) break;

      final outputPath = '${framesDir.path}/frame_$i.jpg';
      final timestamp = Duration(seconds: i);

      final result = await Process.run('ffmpeg', [
        '-ss',
        '$i',
        '-i',
        videoPath,
        '-vframes',
        '1',
        '-q:v',
        '2',
        '-y',
        outputPath,
      ]);

      if (result.exitCode == 0 && await File(outputPath).exists()) {
        final bytes = await File(outputPath).readAsBytes();
        frames.add(
          ExtractedFrame(
            bytes: bytes,
            timestamp: timestamp,
            index: frames.length,
          ),
        );
      }
    }

    return frames;
  }

  Future<Duration?> _getVideoDuration(String videoPath) async {
    final result = await Process.run('ffprobe', [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'default=noprint_wrappers=1:nokey=1',
      videoPath,
    ]);

    if (result.exitCode == 0) {
      final seconds = double.tryParse((result.stdout as String).trim());
      if (seconds != null) {
        return Duration(milliseconds: (seconds * 1000).round());
      }
    }
    return null;
  }
}

class ExtractedFrame {
  final Uint8List bytes;
  final Duration timestamp;
  final int index;

  ExtractedFrame({
    required this.bytes,
    required this.timestamp,
    required this.index,
  });
}
