package xyz.sedno.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.MethodChannel

/** Uses an installed voice for the selected language that does not require a network connection. */
class LocalTextPlaybackController(private val context: Context) {
    private val main = Handler(Looper.getMainLooper())
    private var engine: TextToSpeech? = null
    private var pending: MethodChannel.Result? = null
    private var generation = 0
    private var lastUtterance = ""
    private var initializationTimeout: Runnable? = null

    fun speak(text: String?, language: String, result: MethodChannel.Result) {
        stop()
        if (text.isNullOrBlank() || text.codePointCount(0, text.length) > 32000) {
            result.error("invalid_text", "Nieprawidłowy tekst.", null)
            return
        }
        pending = result
        val current = generation
        initializationTimeout = Runnable { if (generation == current) fail() }
        main.postDelayed(initializationTimeout!!, 10000)
        try {
            engine = TextToSpeech(context) { status ->
                main.post {
                    if (generation != current || pending == null) return@post
                    initializationTimeout?.let { main.removeCallbacks(it) }
                    val tts = engine
                    if (status != TextToSpeech.SUCCESS || tts == null) {
                        fail()
                        return@post
                    }
                    try {
                        val voice = tts.voices?.filter {
                            SpeechLanguages.matches(language, it.locale.toLanguageTag()) && !it.isNetworkConnectionRequired &&
                                !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED)
                        }?.sortedWith(compareBy({ if (it.locale.toLanguageTag().equals(language, true)) 0 else 1 }, { it.name }))?.firstOrNull()
                        if (voice == null || tts.setVoice(voice) != TextToSpeech.SUCCESS) {
                            fail()
                            return@post
                        }
                        tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                            override fun onStart(id: String?) {}
                            override fun onDone(id: String?) {
                                main.post {
                                    if (generation == current && id == lastUtterance) stop()
                                }
                            }
                            @Deprecated("Required by Android")
                            override fun onError(id: String?) {
                                main.post { if (generation == current) fail() }
                            }
                            override fun onError(id: String?, code: Int) = onError(id)
                        })
                        // Android's limit uses UTF-16 units; avoid cutting surrogate pairs.
                        val chunks = mutableListOf<String>()
                        var start = 0
                        val maxLength = TextToSpeech.getMaxSpeechInputLength()
                        while (start < text.length) {
                            var end = minOf(start + maxLength, text.length)
                            if (end < text.length && Character.isHighSurrogate(text[end - 1])) end--
                            chunks.add(text.substring(start, end))
                            start = end
                        }
                        lastUtterance = "$current-${chunks.lastIndex}"
                        chunks.forEachIndexed { index, chunk ->
                            if (tts.speak(chunk, TextToSpeech.QUEUE_ADD, null, "$current-$index") != TextToSpeech.SUCCESS) {
                                fail()
                                return@post
                            }
                        }
                    } catch (_: Exception) {
                        fail()
                    }
                }
            }
        } catch (_: Exception) {
            fail()
        }
    }

    private fun fail() {
        val result = pending
        pending = null
        stop()
        result?.error("unavailable", "Odczyt tekstu jest niedostępny.", null)
    }

    fun stop() {
        generation++
        initializationTimeout?.let { main.removeCallbacks(it) }
        initializationTimeout = null
        val tts = engine
        engine = null
        try {
            tts?.stop()
            tts?.shutdown()
        } catch (_: Exception) {
            // No content or engine exceptions are logged.
        }
        val result = pending
        pending = null
        result?.success(null)
    }
}
