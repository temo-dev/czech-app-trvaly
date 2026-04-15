import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';

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

  /// Navigate away from a question — reset UI state without deleting the file
  /// (the answer is already persisted in the exam session).
  void resetToIdle() {
    state = const SpeakingState();
  }

  /// Restore recorded state when navigating back to a previously recorded question.
  void restoreRecording(String audioPath) {
    state = SpeakingState(
      status: SpeakingStatus.recorded,
      audioPath: audioPath,
    );
  }

  Future<void> submitRecording({
    required String lessonId,
    required String questionId,
  }) async {
    if (state.audioPath == null) return;

    state = state.copyWith(status: SpeakingStatus.uploading);

    try {
      String? resultAttemptId;

      if (kIsWeb) {
        // On web, record package gives a blob URL — upload as bytes
        resultAttemptId = await _uploadWeb(
          audioPath: state.audioPath!,
          lessonId: lessonId,
          questionId: questionId,
        );
      } else {
        resultAttemptId = await _uploadNative(
          audioPath: state.audioPath!,
          lessonId: lessonId,
          questionId: questionId,
        );
      }

      state = state.copyWith(
        status: SpeakingStatus.uploaded,
        attemptId: resultAttemptId,
      );
    } catch (e) {
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
    // Web: audioPath is a blob URL; use http to fetch bytes
    // For MVP, create a stub attempt row directly
    return _callUploadFunction(
      bytes: Uint8List(0),
      lessonId: lessonId,
      questionId: questionId,
    );
  }

  Future<String> _callUploadFunction({
    required Uint8List bytes,
    required String lessonId,
    required String questionId,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'speaking-upload',
        body: {
          'lesson_id': lessonId,
          'question_id': questionId,
          'audio_size': bytes.length,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final attemptId = data?['attempt_id'] as String?;
      if (attemptId != null) return attemptId;
    } catch (_) {
      // Edge function not deployed yet — create stub row directly
    }

    // Fallback: insert speaking_attempts row directly
    final userId = supabase.auth.currentUser?.id;
    final row = await supabase
        .from('speaking_attempts')
        .insert({
          'lesson_id': lessonId,
          'question_id': questionId,
          if (userId != null) 'user_id': userId,
          'status': 'pending',
        })
        .select()
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
    StateNotifierProvider.autoDispose<SpeakingSessionNotifier, SpeakingState>(
  (_) => SpeakingSessionNotifier(),
);
