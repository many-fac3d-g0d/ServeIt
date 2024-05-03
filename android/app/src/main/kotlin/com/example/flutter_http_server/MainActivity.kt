package com.vignesh.nandakumar.serveit

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.OutputStreamWriter
import android.content.Context
import android.net.Uri
import java.nio.charset.StandardCharsets
import android.util.Log
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vignesh.nandakumar.serveit/documentfile"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    try{
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        call, result ->
        if (call.method == "appendFile"){
          val fileUri = Uri.parse(call.argument<String>("fileUri"))
          val content = call.argument<ByteArray?>("content")
          val filename = call.argument<String?>("filename")
          val returnCode: Int = appendToFileSaf(fileUri, content, filename)
          Log.d("INFO", "fileUri: "+fileUri.toString())
          if(returnCode == 0){
              result.success(returnCode)
          }
          else{
              result.error("ERROR", "APPEND_FILE_FAILED", returnCode)
          }
        }
        else {
          result.notImplemented()
        } 
      }
    }
    catch(e: Exception){
        Log.d("ERROR", "Error in MethodChannel: "+e)
    }
    
  }
  fun appendToFileSaf(uri: Uri, content: ByteArray?, filename: String?): Int{
    try{
      val contentResolver = getApplicationContext().getContentResolver()
      val outputStream = contentResolver.openOutputStream(uri, "wa")
      outputStream?.write(content)
      outputStream?.close()
      return 0
    }
    catch(e: Exception){
      Log.d("ERROR", "Error in appendToFileSaf: "+e)
      return 1
    }
  }
}
