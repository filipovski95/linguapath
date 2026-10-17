import 'dart:js_interop';
import 'dart:js_interop_unsafe';

// Safari on iPhone only lets a page start speech or sound from inside a tap.
// Plugin calls finish after several awaits, which can lose the tap, so in the
// browser these call the Web APIs directly and synchronously.

JSObject? get _synth => globalContext['speechSynthesis'] as JSObject?;

JSObject? _utterance(String text) {
  final ctor = globalContext['SpeechSynthesisUtterance'] as JSFunction?;
  return ctor?.callAsConstructor<JSObject>(text.toJS);
}

/// Speaks [text] right away. Returns false when the browser has no speech.
bool webSpeak(String text, String locale, double rate, String? voiceName) {
  try {
    final synth = _synth;
    final u = _utterance(text);
    if (synth == null || u == null) return false;
    u['lang'] = locale.toJS;
    // Phone engines treat 0.5 as normal speed; browsers use 1.0.
    u['rate'] = (rate * 2).clamp(0.3, 1.5).toJS;
    u['pitch'] = 1.05.toJS;
    final voices = (synth.callMethod<JSArray<JSObject>>('getVoices'.toJS)).toDart;
    final lang = locale.toLowerCase().replaceAll('_', '-');
    JSObject? pick;
    for (final v in voices) {
      final name = (v['name'] as JSString?)?.toDart;
      final vl = ((v['lang'] as JSString?)?.toDart ?? '').toLowerCase().replaceAll('_', '-');
      if (voiceName != null && name == voiceName) {
        pick = v;
        break;
      }
      if (pick == null && vl == lang) pick = v;
    }
    if (pick != null) u['voice'] = pick;
    synth.callMethod('cancel'.toJS);
    synth.callMethod('speak'.toJS, u);
    return true;
  } catch (_) {
    return false;
  }
}

final Map<String, JSObject> _audio = {};

/// Plays a bundled sound right away. Returns false if it can't.
bool webPlaySound(String url) {
  try {
    final ctor = globalContext['Audio'] as JSFunction?;
    if (ctor == null) return false;
    final a = _audio[url] ??= ctor.callAsConstructor<JSObject>(url.toJS);
    a['currentTime'] = 0.toJS;
    a.callMethod('play'.toJS);
    return true;
  } catch (_) {
    return false;
  }
}

bool _unlocked = false;

/// Called on the first tap: a silent utterance and silent sound unlock audio
/// for the rest of the visit on iPhone.
void webUnlockMedia() {
  if (_unlocked) return;
  _unlocked = true;
  try {
    final synth = _synth;
    final u = _utterance(' ');
    if (synth != null && u != null) {
      u['volume'] = 0.toJS;
      synth.callMethod('speak'.toJS, u);
    }
    for (final name in ['correct', 'wrong', 'complete']) {
      final url = 'assets/assets/sounds/$name.wav';
      final ctor = globalContext['Audio'] as JSFunction?;
      if (ctor == null) break;
      final a = _audio[url] ??= ctor.callAsConstructor<JSObject>(url.toJS);
      a['muted'] = true.toJS;
      final p = a.callMethod<JSAny?>('play'.toJS);
      // Pause and unmute once the silent play has started.
      if (p != null && p.isA<JSPromise>()) {
        (p as JSPromise).toDart.then((_) {
          a.callMethod('pause'.toJS);
          a['currentTime'] = 0.toJS;
          a['muted'] = false.toJS;
        }, onError: (_) {
          a['muted'] = false.toJS;
        });
      } else {
        a['muted'] = false.toJS;
      }
    }
  } catch (_) {}
}
