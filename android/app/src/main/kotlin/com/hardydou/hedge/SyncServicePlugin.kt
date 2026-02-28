package com.hardydou.hedge

import android.os.FileObserver
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class SyncServicePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var fileObserver: VaultFileObserver? = null
    private var isWatching = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.hardydou.hedge/sync")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopWatching(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startWatching" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    startWatching(path, result)
                } else {
                    result.error("INVALID_ARGS", "Missing path", null)
                }
            }
            "stopWatching" -> stopWatching(result)
            "getSyncStatus" -> getSyncStatus(result)
            "hasConflict" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    hasConflict(path, result)
                } else {
                    result.error("INVALID_ARGS", "Missing path", null)
                }
            }
            "createConflictBackup" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    createConflictBackup(path, result)
                } else {
                    result.error("INVALID_ARGS", "Missing path", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun startWatching(path: String, result: Result) {
        if (isWatching) {
            result.success(null)
            return
        }

        try {
            val file = File(path)
            val parentPath = file.parentFile?.absolutePath ?: return

            fileObserver = VaultFileObserver(parentPath) { event ->
                // Notify Flutter about file change
                channel.invokeMethod("onFileChanged", mapOf(
                    "type" to when (event) {
                        FileObserver.MODIFY -> "modified"
                        FileObserver.DELETE -> "deleted"
                        FileObserver.CREATE -> "created"
                        else -> "modified"
                    },
                    "timestamp" to System.currentTimeMillis()
                ))
            }
            fileObserver?.startWatching()
            isWatching = true
            result.success(null)
        } catch (e: Exception) {
            result.error("WATCH_FAILED", e.message, null)
        }
    }

    private fun stopWatching(result: Result?) {
        try {
            fileObserver?.stopWatching()
            fileObserver = null
            isWatching = false
            result?.success(null)
        } catch (e: Exception) {
            result?.error("STOP_FAILED", e.message, null)
        }
    }

    private fun getSyncStatus(result: Result) {
        // Android doesn't have a direct iCloud status API
        // Return synced status for now
        result.success(mapOf("status" to "synced"))
    }

    private fun hasConflict(path: String, result: Result) {
        try {
            val file = File(path)
            val directory = file.parentFile ?: return result.success(false)
            val fileName = file.nameWithoutExtension
            val fileExtension = file.extension

            val hasBackup = directory.listFiles()?.any { f ->
                f.name.startsWith("${fileName}_") && f.extension == fileExtension && f.name != file.name
            } ?: false

            result.success(hasBackup)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun createConflictBackup(path: String, result: Result) {
        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "Vault file does not exist", null)
                return
            }

            val dateFormat = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault())
            val timestamp = dateFormat.format(Date())

            val directory = file.parentFile!!
            val fileName = file.nameWithoutExtension
            val fileExtension = file.extension

            val backupName = "${fileName}_$timestamp.$fileExtension"
            val backupFile = File(directory, backupName)

            file.copyTo(backupFile, overwrite = true)
            result.success(backupFile.absolutePath)
        } catch (e: Exception) {
            result.error("BACKUP_FAILED", e.message, null)
        }
    }

    inner class VaultFileObserver(
        private val path: String,
        private val onEvent: (Int) -> Unit
    ) : FileObserver(path, FileObserver.ALL_EVENTS) {

        override fun onEvent(event: Int, path: String?) {
            if (path?.endsWith(".db") == true) {
                when (event and FileObserver.ALL_EVENTS) {
                    MODIFY, CREATE, DELETE, MOVED_TO, MOVED_FROM -> onEvent(event)
                }
            }
        }
    }
}
