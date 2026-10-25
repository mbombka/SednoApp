package xyz.sedno.app

import java.util.Locale

/** Compare explicit dialects strictly. A recognizer may also advertise a bare language. */
internal object SpeechLanguages {
    private fun normalized(tag: String): String {
        val lower = tag.replace('_', '-').lowercase(Locale.ROOT)
        return if (lower == "no" || lower.startsWith("no-")) "nb" + lower.removePrefix("no") else lower
    }
    fun matches(requested: String, available: String): Boolean {
        val wanted = normalized(requested)
        val offered = normalized(available)
        return wanted == offered || offered == wanted.substringBefore('-')
    }
}
