package dev.rex.internal.rex_production

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val alias = "rex_session_v1"

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build()
        )
        return generator.generateKey()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rex/session_vault")
            .setMethodCallHandler { call, result ->
                val preferences = getSharedPreferences("rex_session_vault", MODE_PRIVATE)
                try {
                    when (call.method) {
                        "read" -> {
                            val stored = preferences.getString("ciphertext", null)
                            if (stored == null) {
                                result.success(null)
                            } else {
                                val parts = stored.split(":")
                                require(parts.size == 2)
                                val iv = Base64.decode(parts[0], Base64.NO_WRAP)
                                val bytes = Base64.decode(parts[1], Base64.NO_WRAP)
                                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                                cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, iv))
                                result.success(String(cipher.doFinal(bytes), Charsets.UTF_8))
                            }
                        }
                        "write" -> {
                            val value = call.arguments as? String
                            val editor = preferences.edit()
                            if (value == null) {
                                editor.remove("ciphertext")
                            } else {
                                require(value.toByteArray(Charsets.UTF_8).size <= 16384)
                                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                                cipher.init(Cipher.ENCRYPT_MODE, key())
                                val ciphertext = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
                                val iv = Base64.encodeToString(cipher.iv, Base64.NO_WRAP)
                                val encoded = Base64.encodeToString(ciphertext, Base64.NO_WRAP)
                                editor.putString("ciphertext", "$iv:$encoded")
                            }
                            check(editor.commit())
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    // No tokens, ciphertext, arguments or exception detail in logs.
                    result.error("vault_unavailable", "Secure session storage unavailable", null)
                }
            }
    }
}
