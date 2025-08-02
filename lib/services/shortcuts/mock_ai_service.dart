import 'dart:math';

/// Mock AI service for simulating AI responses
class MockAIService {
  static final _random = Random();
  
  /// Simulate sending a prompt to AI and getting a response
  static Future<String> sendPrompt(String prompt) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 1500 + _random.nextInt(1500)));
    
    // Generate a mock response based on prompt content
    return _generateMockResponse(prompt);
  }
  
  /// Generate a mock response based on prompt analysis
  static String _generateMockResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    
    // Check for specific keywords and generate appropriate responses
    if (lowerPrompt.contains('article') || lowerPrompt.contains('write')) {
      return _generateArticleResponse(prompt);
    } else if (lowerPrompt.contains('code') || lowerPrompt.contains('programming')) {
      return _generateCodeResponse(prompt);
    } else if (lowerPrompt.contains('translate')) {
      return _generateTranslationResponse(prompt);
    } else if (lowerPrompt.contains('analyze') || lowerPrompt.contains('analysis')) {
      return _generateAnalysisResponse(prompt);
    } else if (lowerPrompt.contains('summarize') || lowerPrompt.contains('summary')) {
      return _generateSummaryResponse(prompt);
    } else {
      return _generateGenericResponse(prompt);
    }
  }
  
  static String _generateArticleResponse(String prompt) {
    return '''
# Generated Article

Based on your request, here's the article:

## Introduction

This is a mock article generated for demonstration purposes. In a real implementation, the Gemma AI model would generate contextually relevant content based on your specific requirements.

## Main Content

The article would contain several paragraphs of relevant information, properly structured with headings and subheadings. Each section would address different aspects of your topic.

### Key Points

1. **First Point**: Detailed explanation of the first key concept
2. **Second Point**: Analysis of the second important aspect
3. **Third Point**: Discussion of additional considerations

## Conclusion

The article would conclude with a summary of the main points and potential next steps or recommendations based on the topic.

---

*Note: This is a mock response. The actual AI would generate content specific to your prompt: "${prompt.substring(0, prompt.length > 100 ? 100 : prompt.length)}..."*
''';
  }
  
  static String _generateCodeResponse(String prompt) {
    return '''
```dart
// Mock code generation based on your request

class GeneratedCode {
  // This is a demonstration of code generation
  
  void exampleMethod() {
    // The actual AI would generate relevant code
    print('This code would implement: ${prompt.substring(0, 50)}...');
  }
  
  Future<void> asyncExample() async {
    // Simulated async operation
    await Future.delayed(Duration(seconds: 1));
    // Process results
  }
}

// Usage example
void main() {
  final instance = GeneratedCode();
  instance.exampleMethod();
}
```

**Explanation**: This is a mock code response. The actual Gemma AI would generate specific code based on your requirements, including proper implementation details, error handling, and best practices.
''';
  }
  
  static String _generateTranslationResponse(String prompt) {
    return '''
## Translation Result

**Original Text**: [Extracted from your prompt]

**Translated Text**: 
This is a mock translation. In a real implementation, the AI would provide an accurate translation of your text into the requested language.

**Notes**:
- Cultural context has been considered
- Idiomatic expressions have been adapted
- Technical terms have been preserved where appropriate

*Mock response for: "${prompt.substring(0, prompt.length > 80 ? 80 : prompt.length)}..."*
''';
  }
  
  static String _generateAnalysisResponse(String prompt) {
    return '''
## Analysis Report

### Overview
Based on the provided information, here's a comprehensive analysis:

### Key Findings
1. **Primary Observation**: Initial analysis reveals important patterns
2. **Secondary Finding**: Additional factors contribute to the situation
3. **Tertiary Insight**: Further considerations may impact outcomes

### Data Points
- Metric A: 85% (above average)
- Metric B: 62% (within normal range)
- Metric C: 91% (exceptional)

### Recommendations
1. Continue monitoring the positive trends
2. Address areas showing potential for improvement
3. Implement suggested optimizations

### Conclusion
This analysis provides actionable insights based on the available data.

*This is a mock analysis for demonstration. Actual AI would provide specific analysis based on: "${prompt.substring(0, 60)}..."*
''';
  }
  
  static String _generateSummaryResponse(String prompt) {
    return '''
## Summary

Here's a concise summary of the key points:

**Main Topics**:
• Core concept discussed in the content
• Supporting arguments and evidence
• Implications and conclusions

**Key Takeaways**:
1. Most important finding or recommendation
2. Secondary insight worth noting
3. Action items or next steps

**Brief Overview**:
The content primarily focuses on the main theme, providing detailed exploration of various aspects while maintaining clarity and coherence throughout.

*Mock summary generated for: "${prompt.substring(0, 70)}..."*
''';
  }
  
  static String _generateGenericResponse(String prompt) {
    final responses = [
      '''
I understand your request. Here's a thoughtful response:

Based on what you've asked, I would approach this by first considering the main objectives and then developing a comprehensive solution that addresses each aspect systematically.

The key factors to consider include:
- Primary requirements and constraints
- Available resources and timeline
- Desired outcomes and success metrics

Moving forward, I recommend:
1. Establishing clear goals
2. Creating a structured plan
3. Implementing with regular checkpoints
4. Evaluating results and iterating

This approach ensures thorough coverage while maintaining flexibility for adjustments as needed.
''',
      '''
Thank you for your query. Here's my response:

Your request touches on several important aspects that deserve careful consideration. Let me address each component:

First, it's essential to understand the context and background. This provides the foundation for developing an effective approach.

Second, we should examine the various options available, weighing their respective advantages and potential challenges.

Third, implementation requires attention to detail while maintaining sight of the bigger picture.

I hope this helps clarify the path forward. The actual AI would provide more specific guidance based on your exact requirements.
''',
      '''
Excellent question! Let me provide a comprehensive response:

The topic you've raised is quite interesting and has multiple dimensions worth exploring. From my analysis:

**Perspective 1**: Looking at this from one angle reveals certain patterns and opportunities.

**Perspective 2**: An alternative viewpoint suggests different approaches might be beneficial.

**Synthesis**: Combining these perspectives leads to a more nuanced understanding.

The optimal approach likely involves elements from multiple strategies, adapted to your specific situation.

*Note: This is a demonstration response. The actual AI would generate content directly relevant to your prompt.*
''',
    ];
    
    return responses[_random.nextInt(responses.length)] + 
           '\n\n*Mock response for: "${prompt.substring(0, prompt.length > 60 ? 60 : prompt.length)}..."*';
  }
  
  /// Simulate streaming response (returns chunks of text)
  static Stream<String> streamResponse(String prompt) async* {
    final fullResponse = _generateMockResponse(prompt);
    final words = fullResponse.split(' ');
    
    // Simulate streaming by yielding words in small batches
    for (int i = 0; i < words.length; i += 3) {
      final chunk = words.skip(i).take(3).join(' ') + ' ';
      yield chunk;
      await Future.delayed(Duration(milliseconds: 50 + _random.nextInt(100)));
    }
  }
  
  /// Get a mock error response
  static String getMockError() {
    final errors = [
      'Connection timeout. Please check your network and try again.',
      'Model is currently busy. Please try again in a moment.',
      'Invalid prompt format. Please check your input.',
      'Rate limit exceeded. Please wait before making another request.',
    ];
    
    return errors[_random.nextInt(errors.length)];
  }
}