import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';
import 'blob_fetch_stub.dart' if (dart.library.html) 'blob_fetch_web.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum SpeakingStatus {
  idle,
  recording,
  recorded,
  uploading,
  uploaded,
  error,
}

class SpeakingState {
  const SpeakingState({
    this.status = SpeakingStatus.idle,
    this.audioPath,
    this.attemptId,
    this.errorMessage,
    this.amplitudes = const [],
  });

  final SpeakingStatus status;
  final String? audioPath;
  final String? attemptId;
  final String? errorMessage;
  final List<double> amplitudes; // 0.0–1.0, recent N samples

  SpeakingState copyWith({
    SpeakingStatus? status,
    String? audioPath,
    String? attemptId,
    String? errorMessage,
    List<double>? amplitudes,
  }) {
    return SpeakingState(
      status: status ?? this.status,
      audioPath: audioPath ?? this.audioPath,
      attemptId: attemptId ?? this.attemptId,
      errorMessage: errorMessage ?? this.errorMessage,
      amplitudes: amplitudes ?? this.amplitudes,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SpeakingSessionNotifier extends StateNotifier<SpeakingState> {
  SpeakingSessionNotifier() : super(const SpeakingState());

  final _recorder = AudioRecorder();

  // How many amplitude samples to keep for waveform display
  static const _maxAmplitudeSamples = 30;

  Future<bool> hasPermission() async {
    // Web doesn't need explicit permission request via this API
    if (kIsWeb) return true;
    return _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (state.status == SpeakingStatus.recording) return;

    final hasPerms = await hasPermission();
    if (!hasPerms) {
      state = state.copyWith(
        status: SpeakingStatus.error,
        errorMessage: 'Cần quyền truy cập micro. Vui lòng cho phép trong Cài đặt.',
      );
      return;
    }

    String path;
    if (kIsWeb) {
      path = 'speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';
    } else {
      final dir = await getTemporaryDirectory();
      path =
          '${dir.path}/speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    state = state.copyWith(
      status: SpeakingStatus.recording,
      audioPath: path,
      amplitudes: [],
    );

    // Poll amplitude for waveform
    _startAmplitudePolling();
  }

  Future<void> stopRecording() async {
    if (state.status != SpeakingStatus.recording) return;
    await _recorder.stop();
    state = state.copyWith(status: SpeakingStatus.recorded);
  }

  /// User pressed "Ghi lại" — deletes the temp file and resets to idle.
  void discardRecording() {
    final path = state.audioPath;
    if (path != null && !kIsWeb) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    state = const SpeakingState();
  }

  /// Reset UI state. Safe to call even during upload (called from dispose
  /// only when not uploading). After a successful upload the state stays at
  /// [SpeakingStatus.uploaded] until the next widget initialises.
  void resetToIdle() {
    state = const SpeakingState();
  }

  /// Restore state when navigating back to a previously answered question.
  /// [value] may be a local file path OR a UUID attempt_id (already uploaded).
  void restoreRecording(String value) {
    final isAttemptId = _looksLikeAttemptId(value);
    if (isAttemptId) {
      state = SpeakingState(
        status: SpeakingStatus.uploaded,
        attemptId: value,
      );
    } else {
      state = SpeakingState(
        status: SpeakingStatus.recorded,
        audioPath: value,
      );
    }
  }

  static bool _looksLikeAttemptId(String value) {
    // UUID v4 pattern — not a file path or blob URL
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidPattern.hasMatch(value);
  }

  Future<void> submitRecording({
    required String lessonId,
    required String questionId,
  }) async {
    if (!mounted) return;
    if (state.audioPath == null) return;

    state = state.copyWith(status: SpeakingStatus.uploading);

    final audioPath = state.audioPath!;
    try {
      String? resultAttemptId;

      if (kIsWeb) {
        resultAttemptId = await _uploadWeb(
          audioPath: audioPath,
          lessonId: lessonId,
          questionId: questionId,
        );
      } else {
        resultAttemptId = await _uploadNative(
          audioPath: audioPath,
          lessonId: lessonId,
          questionId: questionId,
        );
      }

      if (!mounted) return;
      state = state.copyWith(
        status: SpeakingStatus.uploaded,
        attemptId: resultAttemptId,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: SpeakingStatus.error,
        errorMessage: 'Không thể tải lên bài ghi âm. Vui lòng thử lại.',
      );
    }
  }

  Future<String> _uploadNative({
    required String audioPath,
    required String lessonId,
    required String questionId,
  }) async {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();
    return _callUploadFunction(
      bytes: bytes,
      lessonId: lessonId,
      questionId: questionId,
    );
  }

  Future<String> _uploadWeb({
    required String audioPath,
    required String lessonId,
    required String questionId,
  }) async {
    // Web: audioPath is a blob URL — fetch actual bytes before uploading.
    Uint8List bytes;
    try {
      bytes = await fetchBlobBytes(audioPath);
    } catch (_) {
      bytes = Uint8List(0);
    }
    return _callUploadFunction(
      bytes: bytes,
      lessonId: lessonId,
      questionId: questionId,
    );
  }

  Future<String> _callUploadFunction({
    required Uint8List bytes,
    required String lessonId,
    required String questionId,
  }) async {
    // Use a flag instead of re-throwing inside catch — that way genuine
    // network/HTTP failures still fall through to the DB insert fallback,
    // while an explicit "audio rejected" response from the edge function
    // propagates as an error to the caller.
    String? _audioRejectedReason;

    try {
      final response = await supabase.functions.invoke(
        'speaking-upload',
        body: {
          'lesson_id': lessonId,
          'question_id': questionId,
          'audio_b64': bytes.isNotEmpty ? base64Encode(bytes) : '',
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final attemptId = data?['attempt_id'] as String?;
      final responseError = data?['error'] as String?;
      if (attemptId != null && responseError == null) return attemptId;
      if (responseError != null) {
        _audioRejectedReason = responseError;
      }
    } catch (_) {
      // Network error or edge function not deployed — fall through to DB insert
    }

    // Edge function explicitly rejected the audio (e.g. empty bytes on web)
    if (_audioRejectedReason != null) {
      throw Exception(_audioRejectedReason);
    }

    // Fallback: insert ai_speaking_attempts row directly
    final userId = supabase.auth.currentUser?.id;
    final row = await supabase
        .from('ai_speaking_attempts')
        .insert({
          if (userId != null) 'user_id': userId,
          'audio_key':
              'speaking/$questionId/${DateTime.now().millisecondsSinceEpoch}.m4a',
          'status': 'processing',
        })
        .select('id')
        .maybeSingle();

    if (row != null) return (row as Map)['id'] as String;

    // Last resort — return a placeholder so the screen can still navigate
    return 'pending_${DateTime.now().millisecondsSinceEpoch}';
  }

  void reset() {
    discardRecording();
    state = const SpeakingState();
  }

  // ── Amplitude polling ────────────────────────────────────────────────────────

  void _startAmplitudePolling() async {
    while (state.status == SpeakingStatus.recording) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      if (state.status != SpeakingStatus.recording) return;

      try {
        final amp = await _recorder.getAmplitude();
        final normalized = _normalizeAmplitude(amp.current);
        final updated = [...state.amplitudes, normalized];
        if (updated.length > _maxAmplitudeSamples) {
          updated.removeAt(0);
        }
        state = state.copyWith(amplitudes: updated);
      } catch (_) {
        // Amplitude not available on all platforms — ignore
      }
    }
  }

  double _normalizeAmplitude(double db) {
    // dB range approximately -60 to 0; map to 0.0–1.0
    const minDb = -60.0;
    const maxDb = 0.0;
    if (db <= minDb) return 0.05;
    if (db >= maxDb) return 1.0;
    return ((db - minDb) / (maxDb - minDb)).clamp(0.05, 1.0);
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final speakingSessionProvider =
    StateNotifierProvider<SpeakingSessionNotifier, SpeakingState>(
  (_) => SpeakingSessionNotifier(),
);
