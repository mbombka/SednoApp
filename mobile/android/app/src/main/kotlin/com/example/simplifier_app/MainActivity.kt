package com.example.simplifier_app

import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "simplyfi_it/play_integrity")
        channel.setMethodCallHandler { call, result ->
            if (call.method != "requestToken") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val projectNumber = call.argument<Number>("cloudProjectNumber")?.toLong()
            val requestHash = call.argument<String>("requestHash")
            if (projectNumber == null || projectNumber <= 0 || requestHash.isNullOrEmpty()) {
                result.error("invalid_request", "Nieprawidłowe żądanie weryfikacji.", null)
                return@setMethodCallHandler
            }
            val manager = IntegrityManagerFactory.createStandard(applicationContext)
            manager.prepareIntegrityToken(
                StandardIntegrityManager.PrepareIntegrityTokenRequest.builder()
                    .setCloudProjectNumber(projectNumber).build()
            ).addOnSuccessListener { provider ->
                provider.request(
                    StandardIntegrityManager.StandardIntegrityTokenRequest.builder()
                        .setRequestHash(requestHash).build()
                ).addOnSuccessListener { token -> result.success(token.token()) }
                    .addOnFailureListener {
                        result.error("integrity_failed", "Nie można potwierdzić instalacji.", null)
                    }
            }.addOnFailureListener {
                result.error("integrity_failed", "Nie można potwierdzić instalacji.", null)
            }
        }
    }
}
