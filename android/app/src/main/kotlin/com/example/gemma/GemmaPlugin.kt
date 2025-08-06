package com.example.gemma

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import kotlinx.coroutines.delay

class GemmaPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private lateinit var modelHelper: LlmModelHelper
    private var eventSink: EventChannel.EventSink? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        // Setup method channel
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "gemma_plugin")
        methodChannel.setMethodCallHandler(this)
        
        // Setup event channel for streaming responses
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "gemma_plugin/stream")
        eventChannel.setStreamHandler(this)
        
        // Initialize model helper
        modelHelper = LlmModelHelper(context)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        android.util.Log.d("GemmaPlugin", "onMethodCall: ${call.method}")
        when (call.method) {
            "testEventChannel" -> {
                // Simple test to verify EventChannel works
                android.util.Log.d("GemmaPlugin", "testEventChannel called")
                coroutineScope.launch {
                    for (i in 1..5) {
                        delay(500)
                        withContext(Dispatchers.Main) {
                            android.util.Log.d("GemmaPlugin", "Sending test event $i")
                            eventSink?.success(mapOf(
                                "text" to "Test message $i",
                                "done" to (i == 5)
                            ))
                        }
                    }
                }
                result.success(true)
            }
            
            "initializeModel" -> {
                val modelPath = call.argument<String>("modelPath") ?: ""
                val maxTokens = call.argument<Int>("maxTokens") ?: 1024
                val temperature = call.argument<Double>("temperature") ?: 1.0
                val topK = call.argument<Int>("topK") ?: 40
                val topP = call.argument<Double>("topP") ?: 0.95
                val useGpu = call.argument<Boolean>("useGpu") ?: true
                val supportsImage = call.argument<Boolean>("supportsImage") ?: false
                
                coroutineScope.launch {
                    try {
                        val success = modelHelper.initialize(
                            modelPath = modelPath,
                            maxTokens = maxTokens,
                            temperature = temperature.toFloat(),
                            topK = topK,
                            topP = topP.toFloat(),
                            useGpu = useGpu,
                            supportsImage = supportsImage
                        )
                        withContext(Dispatchers.Main) {
                            result.success(success)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("INIT_ERROR", "Failed to initialize model: ${e.message}", null)
                        }
                    }
                }
            }
            
            "generateResponse" -> {
                val prompt = call.argument<String>("prompt") ?: ""
                val images = call.argument<List<ByteArray>>("images") ?: emptyList()
                
                android.util.Log.d("GemmaPlugin", "generateResponse called with prompt: ${prompt.take(50)}")
                android.util.Log.d("GemmaPlugin", "eventSink is null? ${eventSink == null}")
                
                if (eventSink == null) {
                    android.util.Log.e("GemmaPlugin", "Event stream not initialized!")
                    result.error("STREAM_ERROR", "Event stream not initialized", null)
                    return
                }
                
                coroutineScope.launch {
                    try {
                        android.util.Log.d("GemmaPlugin", "Starting model generation...")
                        var eventCount = 0
                        
                        // NOTE: LlmModelHelper now handles text accumulation internally
                        // and returns accumulated text, not incremental
                        modelHelper.generateResponse(prompt, images) { accumulatedResult, done ->
                            eventCount++
                            android.util.Log.d("GemmaPlugin", "Callback #$eventCount - Accumulated text length: ${accumulatedResult.length}, Done: $done")
                            
                            // Ensure event sink calls happen on main thread
                            coroutineScope.launch(Dispatchers.Main) {
                                val eventData = mapOf(
                                    "text" to accumulatedResult,  // This is now accumulated text
                                    "done" to done
                                )
                                android.util.Log.d("GemmaPlugin", "Sending accumulated text: length=${accumulatedResult.length}, done=$done")
                                eventSink?.success(eventData)
                                
                                if (done) {
                                    android.util.Log.d("GemmaPlugin", "Generation complete, sent $eventCount events, final length: ${accumulatedResult.length}")
                                }
                            }
                        }
                        withContext(Dispatchers.Main) {
                            android.util.Log.d("GemmaPlugin", "generateResponse completed successfully")
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("GemmaPlugin", "Error in generateResponse", e)
                        withContext(Dispatchers.Main) {
                            result.error("GENERATE_ERROR", "Failed to generate response: ${e.message}", null)
                            eventSink?.error("GENERATE_ERROR", "Failed to generate response: ${e.message}", null)
                        }
                    }
                }
            }
            
            "stopGeneration" -> {
                coroutineScope.launch {
                    modelHelper.stopGeneration()
                    withContext(Dispatchers.Main) {
                        result.success(true)
                    }
                }
            }
            
            "resetSession" -> {
                coroutineScope.launch {
                    try {
                        modelHelper.resetSession()
                        withContext(Dispatchers.Main) {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("RESET_ERROR", "Failed to reset session: ${e.message}", null)
                        }
                    }
                }
            }
            
            "cleanup" -> {
                coroutineScope.launch {
                    modelHelper.cleanup()
                    withContext(Dispatchers.Main) {
                        result.success(true)
                    }
                }
            }
            
            "checkModelFile" -> {
                val modelPath = call.argument<String>("modelPath") ?: ""
                val file = java.io.File(modelPath)
                result.success(mapOf(
                    "exists" to file.exists(),
                    "size" to if (file.exists()) file.length() else 0
                ))
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        android.util.Log.d("GemmaPlugin", "onListen called, eventSink set: ${events != null}")
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        android.util.Log.d("GemmaPlugin", "onCancel called, clearing eventSink")
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        coroutineScope.cancel()
    }
}