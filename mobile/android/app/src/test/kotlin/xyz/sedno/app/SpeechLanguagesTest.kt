package xyz.sedno.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SpeechLanguagesTest {
    @Test fun explicitDialectsDoNotSubstituteAnotherRegion() {
        assertTrue(SpeechLanguages.matches("en-US", "en_US"))
        assertFalse(SpeechLanguages.matches("en-US", "en-GB"))
        assertFalse(SpeechLanguages.matches("pt-PT", "pt-BR"))
        assertFalse(SpeechLanguages.matches("en-GB", "en-US"))
        assertFalse(SpeechLanguages.matches("fr-FR", "fr-CA"))
    }
    @Test fun bareAdvertisedLanguageAndLegacyNorwegianAreAccepted() {
        assertTrue(SpeechLanguages.matches("pt-PT", "pt"))
        assertTrue(SpeechLanguages.matches("nb-NO", "no-NO"))
        assertTrue(SpeechLanguages.matches("nb-NO", "no"))
        assertFalse(SpeechLanguages.matches("nb-NO", "nn-NO"))
        assertFalse(SpeechLanguages.matches("en-US", "english"))
    }
    @Test fun eachSelectedLocaleMatchesItself() {
        listOf("pl-PL", "en-GB", "en-US", "fr-FR", "de-DE", "it-IT", "es-ES", "pt-PT", "sk-SK", "cs-CZ", "ro-RO", "nb-NO", "sv-SE").forEach {
            assertTrue(SpeechLanguages.matches(it, it))
        }
    }
}
