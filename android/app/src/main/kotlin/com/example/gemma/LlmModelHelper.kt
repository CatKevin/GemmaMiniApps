package com.example.gemma

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.genai.llminference.GraphOptions
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

typealias ResultListener = (partialResult: String, done: Boolean) -> Unit

data class ModelInstance(val engine: LlmInference, var session: LlmInferenceSession)

class LlmModelHelper(private val context: Context) {
    private var modelInstance: ModelInstance? = null
    private var supportsImageModality = false
    private val TAG = "LlmModelHelper"

    suspend fun initialize(
        modelPath: String,
        maxTokens: Int = 1024,
        temperature: Float = 1.0f,
        topK: Int = 40,
        topP: Float = 0.95f,
        useGpu: Boolean = true,
        supportsImage: Boolean = false
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Initializing model from path: $modelPath")
            
            val preferredBackend = if (useGpu) {
                LlmInference.Backend.GPU
            } else {
                LlmInference.Backend.CPU
            }
            
            val optionsBuilder = LlmInference.LlmInferenceOptions.builder()
                .setModelPath(modelPath)
                .setMaxTokens(maxTokens)
                .setPreferredBackend(preferredBackend)
                .setMaxNumImages(if (supportsImage) 5 else 0) // Support up to 5 images
            
            val llmInference = LlmInference.createFromOptions(context, optionsBuilder.build())
            
            val session = LlmInferenceSession.createFromOptions(
                llmInference,
                LlmInferenceSession.LlmInferenceSessionOptions.builder()
                    .setTopK(topK)
                    .setTopP(topP)
                    .setTemperature(temperature)
                    .setGraphOptions(
                        GraphOptions.builder()
                            .setEnableVisionModality(supportsImage)
                            .build()
                    )
                    .build()
            )
            
            modelInstance = ModelInstance(engine = llmInference, session = session)
            supportsImageModality = supportsImage
            
            Log.d(TAG, "Model initialized successfully with image support: $supportsImage")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize model: ${e.message}", e)
            false
        }
    }

    suspend fun generateResponse(
        prompt: String,
        resultListener: ResultListener
    ) = withContext(Dispatchers.IO) {
        generateResponse(prompt, emptyList(), resultListener)
    }

    suspend fun generateResponse(
        prompt: String,
        images: List<ByteArray>,
        resultListener: ResultListener
    ) = withContext(Dispatchers.IO) {
        try {
            val instance = modelInstance ?: throw IllegalStateException("Model not initialized")
            
            Log.d(TAG, "Generating response for prompt: ${prompt.take(50)}... with ${images.size} images")
            
            // Use the existing session to maintain conversation context
            val session = instance.session
            Log.d(TAG, "Using existing session to maintain conversation context")
            Log.d(TAG, "Session hash: ${session.hashCode()}")
            
            // Add the prompt to the session
            if (prompt.trim().isNotEmpty()) {
                session.addQueryChunk(prompt)
                Log.d(TAG, "Added query chunk to session: '${prompt.take(50)}'...")
                Log.d(TAG, "This is query #${session.sizeInTokens(prompt)} in the current session")
            }
            
            // Add images if provided and supported
            if (images.isNotEmpty() && supportsImageModality) {
                for (imageBytes in images) {
                    try {
                        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                        if (bitmap != null) {
                            val mediaImage = BitmapImageBuilder(bitmap).build()
                            session.addImage(mediaImage)
                            Log.d(TAG, "Added image: ${bitmap.width}x${bitmap.height}")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to process image: ${e.message}")
                    }
                }
            }
            
            // CRITICAL FIX: MediaPipe returns INCREMENTAL text, not cumulative!
            // We need to accumulate the text ourselves
            var accumulatedText = ""
            var chunkCount = 0
            
            session.generateResponseAsync { partialResult, done ->
                chunkCount++
                
                // Accumulate the incremental text
                accumulatedText += partialResult
                
                Log.d(TAG, "📨 Chunk #$chunkCount - Incremental length: ${partialResult.length}, Accumulated: ${accumulatedText.length}, Done: $done")
                Log.d(TAG, "📝 Incremental content: ${partialResult.take(50)}...")
                Log.d(TAG, "📄 Accumulated preview: ${accumulatedText.take(100)}...")
                
                // Send the ACCUMULATED text to Flutter
                resultListener(accumulatedText, done)
                
                if (done) {
                    Log.d(TAG, "🎉 Generation complete - Total chunks: $chunkCount, Final accumulated length: ${accumulatedText.length}")
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to generate response: ${e.message}", e)
            throw e
        }
    }

    fun stopGeneration() {
        try {
            Log.d(TAG, "Stop generation requested")
            // MediaPipe async generation handles cancellation internally
            // The session can be reset if needed to stop ongoing generation
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop generation", e)
        }
    }

    suspend fun resetSession() = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Resetting session")
            
            val instance = modelInstance ?: return@withContext
            
            // Close current session
            instance.session.close()
            
            // Create new session with same parameters
            val inference = instance.engine
            val newSession = LlmInferenceSession.createFromOptions(
                inference,
                LlmInferenceSession.LlmInferenceSessionOptions.builder()
                    .setTopK(40)
                    .setTopP(0.95f)
                    .setTemperature(1.0f)
                    .setGraphOptions(
                        GraphOptions.builder()
                            .setEnableVisionModality(supportsImageModality)
                            .build()
                    )
                    .build()
            )
            
            instance.session = newSession
            
            Log.d(TAG, "Session reset successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to reset session: ${e.message}", e)
            throw e
        }
    }

    fun cleanup() {
        try {
            Log.d(TAG, "Cleaning up resources")
            
            modelInstance?.let { instance ->
                try {
                    instance.session.close()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to close session: ${e.message}")
                }
                
                try {
                    instance.engine.close()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to close engine: ${e.message}")
                }
            }
            
            modelInstance = null
            Log.d(TAG, "Cleanup completed")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cleanup: ${e.message}", e)
        }
    }
}