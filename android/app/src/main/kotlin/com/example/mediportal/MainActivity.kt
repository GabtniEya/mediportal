package com.example.mediportal

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.os.Parcelable
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "mediportal/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")
                val text = call.argument<String>("text") ?: ""
                val subject = call.argument<String>("subject") ?: ""

                if (path.isNullOrBlank()) {
                    result.error("MISSING_PATH", "PDF introuvable", null)
                    return@setMethodCallHandler
                }

                try {
                    when (call.method) {
                        "sendWhatsAppPdf" -> {
                            sendPdfToWhatsApp(path, text)
                            result.success(true)
                        }
                        "sendEmailPdf" -> {
                            sendPdfToEmail(path, subject, text)
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: ActivityNotFoundException) {
                    result.error("NO_APP", "Application non disponible", e.message)
                } catch (e: Exception) {
                    result.error("SHARE_FAILED", "Envoi impossible", e.message)
                }
            }
    }

    private fun pdfUri(path: String): Uri {
        val file = File(path)
        return FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file
        )
    }

    private fun basePdfIntent(uri: Uri, text: String): Intent {
        return Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, text)
            clipData = ClipData.newUri(contentResolver, "fiche_avc.pdf", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun sendPdfToWhatsApp(path: String, text: String) {
        val uri = pdfUri(path)
        val packages = listOf("com.whatsapp", "com.whatsapp.w4b")

        for (packageName in packages) {
            val intent = basePdfIntent(uri, text).apply {
                setPackage(packageName)
            }

            try {
                grantUriPermission(packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                startActivity(intent)
                return
            } catch (_: ActivityNotFoundException) {
                continue
            }
        }

        throw ActivityNotFoundException("WhatsApp non installe")
    }

    private fun sendPdfToEmail(path: String, subject: String, text: String) {
        val uri = pdfUri(path)
        val emailProbe = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:")
        }
        val emailApps = packageManager.queryIntentActivities(emailProbe, 0)

        if (emailApps.isEmpty()) {
            throw ActivityNotFoundException("Aucune application e-mail installee")
        }

        val emailIntents = emailApps.map { resolveInfo ->
            val packageName = resolveInfo.activityInfo.packageName
            grantUriPermission(packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            basePdfIntent(uri, text).apply {
                setPackage(packageName)
                putExtra(Intent.EXTRA_SUBJECT, subject)
            }
        }

        val chooser = Intent.createChooser(emailIntents.first(), "Envoyer par e-mail").apply {
            putExtra(
                Intent.EXTRA_INITIAL_INTENTS,
                emailIntents.drop(1).toTypedArray<Parcelable>()
            )
        }

        startActivity(chooser)
    }
}
