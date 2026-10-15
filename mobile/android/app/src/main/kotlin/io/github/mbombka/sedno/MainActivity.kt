package io.github.mbombka.sedno

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.KeyStore
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val channelName = "pl.sedno/history"
    // Keep this alias for history encrypted by earlier builds.
    private val alias = "simplyfi_history_v1"
    private val version: Byte = 1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "read" -> result.success(readHistory())
                        "write" -> {
                            val text = call.arguments as? String
                                ?: throw IllegalArgumentException("Invalid history document")
                            writeHistory(text)
                            result.success(null)
                        }
                        "clear" -> {
                            file().delete()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: AEADBadTagException) {
                    result.error("CORRUPT", "Nie można odczytać historii.", null)
                } catch (_: CorruptHistoryException) {
                    result.error("CORRUPT", "Nie można odczytać historii.", null)
                } catch (_: Exception) {
                    result.error("STORAGE", "Nie można zapisać lub odczytać historii.", null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sedno/play_integrity")
            .setMethodCallHandler { call, result ->
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

    private fun file() = File(noBackupFilesDir, "history.enc")

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build()
        )
        return generator.generateKey()
    }

    private fun readHistory(): String? {
        val target = file()
        if (!target.exists()) return null
        val bytes = AtomicFile(target).openRead().use { it.readBytes() }
        if (bytes.size < 1 + 12 + 16 || bytes[0] != version) throw CorruptHistoryException()
        val iv = bytes.copyOfRange(1, 13)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, iv))
        return cipher.doFinal(bytes.copyOfRange(13, bytes.size)).toString(Charsets.UTF_8)
    }

    private fun writeHistory(text: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val data = byteArrayOf(version) + cipher.iv + cipher.doFinal(text.toByteArray(Charsets.UTF_8))
        val atomic = AtomicFile(file())
        val stream = atomic.startWrite()
        try {
            stream.write(data)
            atomic.finishWrite(stream)
        } catch (error: Exception) {
            atomic.failWrite(stream)
            throw error
        }
    }

    private class CorruptHistoryException : Exception()
}
