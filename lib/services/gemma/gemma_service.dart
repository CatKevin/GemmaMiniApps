import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class GemmaService {
  static const MethodChannel _channel = MethodChannel('gemma_plugin');
  static const EventChannel _streamChannel = EventChannel('gemma_plugin/stream');
  
  static GemmaService? _instance;
  StreamController<GemmaResponse>? _responseController;
  StreamSubscription? _eventSubscription;

  factory GemmaService() {
    _instance ??= GemmaService._internal();
    return _instance!;
  }

  GemmaService._internal();

  Future<bool> initializeModel({
    required String modelPath,
    int maxTokens = 1024,
    double temperature = 1.0,
    int topK = 40,
    double topP = 0.95,
    bool useGpu = true,
    bool supportsImage = false,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('initializeModel', {
        'modelPath': modelPath,
        'maxTokens': maxTokens,
        'temperature': temperature,
        'topK': topK,
        'topP': topP,
        'useGpu': useGpu,
        'supportsImage': supportsImage,
      });
      return result ?? false;
    } catch (e) {
      print('Failed to initialize model: $e');
      return false;
    }
  }

  Stream<GemmaResponse> generateResponse(String prompt, {List<Uint8List>? images}) {
    print('🚀 GemmaService.generateResponse called');
    print('📝 Prompt: ${prompt.substring(0, prompt.length.clamp(0, 50))}...');
    
    // Cancel previous subscription and close controller if exists
    _eventSubscription?.cancel();
    _eventSubscription = null;
    
    // Close previous controller safely
    if (_responseController != null && !_responseController!.isClosed) {
      _responseController!.close();
    }
    
    // Create new controller
    _responseController = StreamController<GemmaResponse>.broadcast();
    
    // Track if controller has been closed to prevent double closing
    bool controllerClosed = false;
    
    void closeControllerSafely() {
      if (!controllerClosed && _responseController != null && !_responseController!.isClosed) {
        controllerClosed = true;
        _responseController!.close();
        print('🔒 Stream controller closed safely');
      }
    }
    
    _eventSubscription = _streamChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        print('📨 Native event received: ${event.toString().substring(0, event.toString().length.clamp(0, 100))}...');
        if (!controllerClosed && event is Map) {
          final response = GemmaResponse(
            text: event['text'] ?? '',
            isDone: event['done'] ?? false,
          );
          print('📦 Parsed - Text length: ${response.text.length}, Done: ${response.isDone}');
          
          if (!_responseController!.isClosed) {
            _responseController!.add(response);
          }
          
          if (response.isDone) {
            print('✅ Response complete, will close stream controller after delay');
            // Add a small delay before closing to ensure the last message is processed
            Future.delayed(const Duration(milliseconds: 100), () {
              closeControllerSafely();
            });
          }
        } else if (!event is Map) {
          print('⚠️ Event is not a Map: ${event.runtimeType}');
        }
      },
      onError: (error) {
        print('❌ Stream error: $error');
        if (!controllerClosed && !_responseController!.isClosed) {
          _responseController!.addError(error);
        }
        closeControllerSafely();
      },
      onDone: () {
        print('🏁 Stream done');
        closeControllerSafely();
      },
    );
    
    final Map<String, dynamic> params = {'prompt': prompt};
    if (images != null && images.isNotEmpty) {
      params['images'] = images;
      print('🖼️ Including ${images.length} images');
    }
    
    print('📤 Calling native method: generateResponse');
    _channel.invokeMethod('generateResponse', params).then((result) {
      print('✅ Native method call succeeded: $result');
    }).catchError((error) {
      print('❌ Failed to generate response: $error');
      if (!controllerClosed && !_responseController!.isClosed) {
        _responseController!.addError(error);
      }
      closeControllerSafely();
    });
    
    return _responseController!.stream;
  }

  Future<bool> stopGeneration() async {
    try {
      _eventSubscription?.cancel();
      _responseController?.close();
      final result = await _channel.invokeMethod<bool>('stopGeneration');
      return result ?? false;
    } catch (e) {
      print('Failed to stop generation: $e');
      return false;
    }
  }

  Future<bool> resetSession() async {
    try {
      final result = await _channel.invokeMethod<bool>('resetSession');
      return result ?? false;
    } catch (e) {
      print('Failed to reset session: $e');
      return false;
    }
  }

  Future<bool> cleanup() async {
    try {
      _eventSubscription?.cancel();
      _responseController?.close();
      final result = await _channel.invokeMethod<bool>('cleanup');
      return result ?? false;
    } catch (e) {
      print('Failed to cleanup: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> checkModelFile(String modelPath) async {
    try {
      final result = await _channel.invokeMethod<Map>('checkModelFile', {
        'modelPath': modelPath,
      });
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      print('Failed to check model file: $e');
      return {'exists': false, 'size': 0};
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _responseController?.close();
  }
}

class GemmaResponse {
  final String text;
  final bool isDone;

  GemmaResponse({
    required this.text,
    required this.isDone,
  });
}