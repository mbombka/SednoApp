package xyz.sedno.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SpeechEndpointTest {
    @Test fun initialSilenceDoesNotEndRecording() {
        val endpoint = SpeechEndpoint(0)
        for (time in 0L..59_980L step 20) assertFalse(endpoint.accept(50.0, time))
    }

    @Test fun endsAt1500MillisecondsAfterSpeech() {
        val endpoint = SpeechEndpoint(0)
        for (time in 0L..100L step 20) assertFalse(endpoint.accept(2000.0, time))
        for (time in 120L..1580L step 20) assertFalse(endpoint.accept(50.0, time))
        assertTrue(endpoint.accept(50.0, 1600))
    }

    @Test fun resumedSpeechResetsSilenceWindow() {
        val endpoint = SpeechEndpoint(0)
        for (time in 0L..100L step 20) endpoint.accept(2000.0, time)
        for (time in 120L..1000L step 20) assertFalse(endpoint.accept(50.0, time))
        for (time in 1020L..1200L step 20) assertFalse(endpoint.accept(2000.0, time))
        for (time in 1220L..2680L step 20) assertFalse(endpoint.accept(50.0, time))
        assertTrue(endpoint.accept(50.0, 2700))
    }

    @Test fun maximumDurationEndsEvenContinuousSpeech() {
        val endpoint = SpeechEndpoint(1000)
        for (time in 1000L..60_980L step 20) assertFalse(endpoint.accept(2000.0, time))
        assertTrue(endpoint.accept(2000.0, 61_000))
    }

    @Test fun maximumDurationAlsoEndsInitialSilence() {
        val endpoint = SpeechEndpoint(0)
        assertFalse(endpoint.accept(50.0, 59_999))
        assertTrue(endpoint.accept(50.0, 60_000))
    }

    @Test fun microphoneClickDoesNotArmSilenceDetection() {
        val endpoint = SpeechEndpoint(0)
        endpoint.accept(3000.0, 0)
        for (time in 20L..5000L step 20) assertFalse(endpoint.accept(50.0, time))
    }
}
