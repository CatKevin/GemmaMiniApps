import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ChatInput extends HookWidget {
  final Function(String) onSendMessage;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController();
    final focusNode = useFocusNode();
    final isEmpty = useState(true);

    // Listen to text changes
    useEffect(() {
      void listener() {
        isEmpty.value = textController.text.trim().isEmpty;
      }

      textController.addListener(listener);
      return () => textController.removeListener(listener);
    }, [textController]);

    void handleSend() {
      final text = textController.text.trim();
      if (text.isNotEmpty && enabled) {
        onSendMessage(text);
        textController.clear();
        isEmpty.value = true;
        // Keep focus on input field
        focusNode.requestFocus();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Theme.of(context).shadowColor.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Text input field
              Expanded(
                child: TextField(
                  controller: textController,
                  focusNode: focusNode,
                  enabled: enabled,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: enabled
                        ? 'Type a message...'
                        : 'Waiting for response...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!isEmpty.value) {
                      handleSend();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              Material(
                color: isEmpty.value || !enabled
                    ? Theme.of(context).colorScheme.surfaceVariant
                    : Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: isEmpty.value || !enabled ? null : handleSend,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.send_rounded,
                      size: 24,
                      color: isEmpty.value || !enabled
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
