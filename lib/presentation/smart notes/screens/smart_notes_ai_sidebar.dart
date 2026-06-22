import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:academic_project/data/ai_remote_data_source.dart';
import '../../../domain/ai_response.dart';
import '../../theme/app_constants.dart';
import '../ai/provider/ai_provider.dart';

class SmartNotesAiSidebar extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const SmartNotesAiSidebar({super.key, this.onClose});

  @override
  ConsumerState<SmartNotesAiSidebar> createState() => _SmartNotesAiSidebarState();
}

class _SmartNotesAiSidebarState extends ConsumerState<SmartNotesAiSidebar> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _showHistoryList = false;
  List<dynamic> _historyLogs = [];
  bool _isLoadingHistory = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final List<String> _styles = [
    'Academic',
    'Technical',
    'Short Answer',
    'Exam Standard',
    'Simple Word',
    'Creative',
    'Brainstorming'
  ];

  final List<String> _languages = [
    'English',
    'Bengali',
    'Spanish',
    'French',
    'German',
    'Hindi'
  ];

  final List<String> _formats = [
    'None',
    'Difference Table',
    'Definition',
    'Working Principle'
  ];

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _showHistoryList = true;
    });
    try {
      final logs = await AiRemoteDataSource().getHistory();
      setState(() {
        _historyLogs = logs;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    try {
      await AiRemoteDataSource().clearHistory();
      setState(() {
        _historyLogs.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear history: $e')),
        );
      }
    }
  }

  void _restoreHistoryItem(Map<String, dynamic> log) {
    try {
      final prompt = log['prompt'] as String;
      final responseStr = log['responseJson'] as String;
      final decodedResponse = AiResponse.fromJson(jsonDecode(responseStr));
      setState(() {
        _messages.clear();
        _messages.add(_ChatMessage(prompt, isUser: true));
        _messages.add(_ChatMessage(
          decodedResponse.content.isNotEmpty ? decodedResponse.content : decodedResponse.academicDefinition,
          isUser: false,
          style: log['style'],
          response: decodedResponse,
        ));
        _showHistoryList = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring message: $e')),
        );
      }
    }
  }

  Widget _buildModeBar() {
    final aiState = ref.watch(aiProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SmartNotesTheme.bgSecondary.withOpacity(0.5),
        border: const Border(bottom: BorderSide(color: SmartNotesTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Response Customization', style: TextStyle(
            color: SmartNotesTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          )),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDropdown(
                  icon: Icons.auto_awesome_outlined,
                  label: 'STYLE',
                  value: aiState.selectedStyle,
                  items: _styles,
                  onChanged: (val) => ref.read(aiProvider.notifier).setStyle(val!),
                ),
                const SizedBox(width: 8),
                _buildDropdown(
                  icon: Icons.view_headline,
                  label: 'FORMAT',
                  value: aiState.selectedFormat,
                  items: _formats,
                  onChanged: (val) => ref.read(aiProvider.notifier).setFormat(val!),
                ),
                const SizedBox(width: 8),
                _buildDropdown(
                  icon: Icons.translate,
                  label: 'LANG',
                  value: aiState.selectedLanguage,
                  items: _languages,
                  onChanged: (val) => ref.read(aiProvider.notifier).setLanguage(val!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: SmartNotesTheme.bgMain,
        borderRadius: BorderRadius.circular(SmartNotesTheme.radiusMedium),
        border: Border.all(color: SmartNotesTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: SmartNotesTheme.accentBlue),
          const SizedBox(width: 6),
          Text(
            "$label:",
            style: const TextStyle(
              color: SmartNotesTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 14),
              style: const TextStyle(
                color: SmartNotesTheme.textMain,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
              dropdownColor: SmartNotesTheme.bgMain,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final aiState = ref.read(aiProvider);
    final currentStyle = aiState.selectedStyle;
    setState(() {
      _showHistoryList = false;
      _messages.add(_ChatMessage(text, isUser: true, style: currentStyle));
    });
    _inputController.clear();
    ref.read(aiProvider.notifier).askAi(text);
  }

  void _onSuggestionTap(String text) {
    _sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);

    ref.listen<AiState>(aiProvider, (prev, next) {
      if (next.response != null && next.response != prev?.response) {
        final displayText = next.response!.content.isNotEmpty
            ? next.response!.content
            : next.response!.academicDefinition;
        setState(() {
          _messages.add(_ChatMessage(
            displayText,
            isUser: false,
            style: next.selectedStyle,
            response: next.response,
          ));
        });
        Future.microtask(() {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      if (next.error != null && next.error != prev?.error) {
        setState(() {
          _messages.add(_ChatMessage(
            "Error: ${next.error}",
            isUser: false,
            isError: true,
          ));
        });
      }
    });

    return Container(
      color: SmartNotesTheme.bgMain,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SmartNotesTheme.border))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: SmartNotesTheme.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.smart_toy, color: SmartNotesTheme.iconDark, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Assistant', style: SmartNotesTheme.heading2),
                      Text('Smart productivity helper', style: SmartNotesTheme.caption),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history, color: SmartNotesTheme.iconColor, size: 18),
                  tooltip: 'Chat Logs History',
                  onPressed: _loadHistory,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: SmartNotesTheme.iconColor, size: 18),
                  tooltip: 'New Chat',
                  onPressed: () {
                    setState(() {
                      _messages.clear();
                      _showHistoryList = false;
                    });
                    ref.read(aiProvider.notifier).clearResponse();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: SmartNotesTheme.iconColor, size: 18),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          _buildModeBar(),
          Expanded(
            child: _showHistoryList
                ? _buildHistoryListView()
                : (_messages.isEmpty
                    ? _buildWelcomeView()
                    : _buildMessagesListView(aiState)),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: SmartNotesTheme.border))),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(color: SmartNotesTheme.bgSecondary, borderRadius: BorderRadius.circular(SmartNotesTheme.radiusMedium), border: Border.all(color: SmartNotesTheme.border)),
                    child: TextField(
                      controller: _inputController,
                      style: SmartNotesTheme.body,
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(color: SmartNotesTheme.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) => _sendMessage(val),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_inputController.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: aiState.isLoading ? Colors.grey[400] : SmartNotesTheme.accentBlue,
                      borderRadius: BorderRadius.circular(SmartNotesTheme.radiusMedium),
                    ),
                    child: aiState.isLoading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: SmartNotesTheme.iconDark),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: SmartNotesTheme.accent, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy, color: SmartNotesTheme.iconDark, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: SmartNotesTheme.bgSecondary, borderRadius: BorderRadius.circular(SmartNotesTheme.radiusLarge), border: Border.all(color: SmartNotesTheme.border)),
                child: const Text(
                  "Hi! I'm your AI assistant. I can help you organize your thoughts, compare concepts with structured tables, trace mechanisms with process flowcharts, or write exam summaries. What would you like to ask?",
                  style: TextStyle(color: SmartNotesTheme.textMain, height: 1.4, fontSize: 13),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('Suggested Prompts:', style: SmartNotesTheme.bodySmall),
        ),
        const SizedBox(height: 12),
        _buildSuggestion('Compare CPU scheduling algorithms', () => _onSuggestionTap('Compare CPU scheduling algorithms')),
        _buildSuggestion('Explain how packet switching works step by step', () => _onSuggestionTap('Explain how packet switching works step by step')),
        _buildSuggestion('Academic definition of compiler lexing and parsing', () => _onSuggestionTap('Academic definition of compiler lexing and parsing')),
        _buildSuggestion('Summarize acid rain effects for exams', () => _onSuggestionTap('Summarize acid rain effects for exams')),
      ],
    );
  }

  Widget _buildMessagesListView(AiState aiState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (aiState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && aiState.isLoading) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 34),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: SmartNotesTheme.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.smart_toy, color: SmartNotesTheme.iconDark, size: 14),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: SmartNotesTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(SmartNotesTheme.radiusLarge),
                    border: Border.all(color: SmartNotesTheme.border),
                  ),
                  child: const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ),
          );
        }
        final msg = _messages[index];
        if (msg.isUser) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SmartNotesTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SmartNotesTheme.radiusLarge),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: SmartNotesTheme.textMain, fontSize: 13),
                ),
              ),
            ),
          );
        } else {
          Color bubbleColor = msg.isError
              ? const Color(0xFFFEE2E2)
              : SmartNotesTheme.bgSecondary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: msg.isError ? SmartNotesTheme.bgSecondary : SmartNotesTheme.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    msg.isError ? Icons.error_outline : Icons.smart_toy,
                    color: msg.isError ? Colors.red : SmartNotesTheme.iconDark,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(SmartNotesTheme.radiusLarge),
                      border: msg.isError
                          ? Border.all(color: Colors.red.shade200)
                          : Border.all(color: SmartNotesTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg.response != null) ...[
                          _buildAiResponseCards(msg.response!),
                          if (msg.style != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: SmartNotesTheme.accentBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  msg.style!,
                                  style: const TextStyle(
                                    color: SmartNotesTheme.accentBlue,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                        ] else
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isError ? Colors.red.shade800 : SmartNotesTheme.textMain,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _parseLineToRichText(String line, {double fontSize = 12.0, Color? defaultColor}) {
    final cleanLine = line.trim();
    if (cleanLine.isEmpty) return const SizedBox.shrink();

    // Check for headers
    if (cleanLine.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: _renderFormattedText(
          cleanLine.substring(4),
          style: TextStyle(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.bold,
            color: SmartNotesTheme.accentBlue,
          ),
        ),
      );
    } else if (cleanLine.startsWith('## ') || cleanLine.startsWith('# ')) {
      final startIdx = cleanLine.startsWith('## ') ? 3 : 2;
      return Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
        child: _renderFormattedText(
          cleanLine.substring(startIdx),
          style: TextStyle(
            fontSize: fontSize + 3,
            fontWeight: FontWeight.bold,
            color: SmartNotesTheme.accentBlue,
          ),
        ),
      );
    }

    // Check for bullet points
    bool isBullet = cleanLine.startsWith('* ') || cleanLine.startsWith('- ');
    bool isNumbered = RegExp(r'^\d+\.\s').hasMatch(cleanLine);

    String contentText = cleanLine;
    Widget? prefix;

    if (isBullet) {
      contentText = cleanLine.substring(2);
      prefix = Padding(
        padding: const EdgeInsets.only(top: 5.5, right: 8.0),
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: SmartNotesTheme.accentBlue,
            shape: BoxShape.circle,
          ),
        ),
      );
    } else if (isNumbered) {
      final match = RegExp(r'^(\d+)\.\s').firstMatch(cleanLine);
      if (match != null) {
        final numStr = match.group(1)!;
        contentText = cleanLine.substring(match.end);
        prefix = Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: Text(
            '$numStr.',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: SmartNotesTheme.accentBlue,
            ),
          ),
        );
      }
    }

    final textWidget = _renderFormattedText(
      contentText,
      style: TextStyle(
        fontSize: fontSize,
        color: defaultColor ?? SmartNotesTheme.textMain,
        height: 1.4,
      ),
    );

    if (prefix != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            prefix,
            Expanded(child: textWidget),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: textWidget,
    );
  }

  Widget _renderFormattedText(String text, {required TextStyle style}) {
    final parts = text.split('**');
    if (parts.length == 1) {
      return Text(text, style: style);
    }

    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(TextSpan(
        text: parts[i],
        style: style.copyWith(
          fontWeight: isBold ? FontWeight.bold : style.fontWeight,
          color: isBold ? (style.color ?? SmartNotesTheme.textMain) : style.color,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: style,
      ),
    );
  }

  Widget _parseMarkdownToRichText(String text, {double fontSize = 12.0, Color? defaultColor}) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isNotEmpty) {
        children.add(_parseLineToRichText(line, fontSize: fontSize, defaultColor: defaultColor));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildCard({
    required String title,
    required String content,
    required IconData icon,
    required Color headerColor,
    required Color backgroundColor,
    required Color borderColor,
    Color? textColor,
    Widget? customBody,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: headerColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Copy Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied $title content to clipboard!'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: SmartNotesTheme.accentBlue,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.copy_outlined,
                        size: 13,
                        color: headerColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Body
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: customBody ?? _parseMarkdownToRichText(content, defaultColor: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResponseCards(AiResponse response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Topic Header Card
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SmartNotesTheme.accentBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: SmartNotesTheme.accentBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: SmartNotesTheme.accentBlue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  response.topic.toUpperCase(),
                  style: const TextStyle(
                    color: SmartNotesTheme.accentBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Copy Whole response button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    final buffer = StringBuffer();
                    buffer.writeln('Topic: ${response.topic}');
                    if (response.content.isNotEmpty) {
                      buffer.writeln('\nExplanation:\n${response.content}');
                    }
                    if (response.academicDefinition.isNotEmpty) {
                      buffer.writeln('\nAcademic Definition:\n${response.academicDefinition}');
                    }
                    if (response.simpleDefinition.isNotEmpty) {
                      buffer.writeln('\nSimple Analogy:\n${response.simpleDefinition}');
                    }
                    if (response.examStandardDescription.isNotEmpty) {
                      buffer.writeln('\nExam Suggestions:\n${response.examStandardDescription}');
                    }
                    Clipboard.setData(ClipboardData(text: buffer.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied entire AI response to clipboard!'),
                        backgroundColor: SmartNotesTheme.accentBlue,
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.copy_all_outlined, size: 14, color: SmartNotesTheme.accentBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Main Content Card
        if (response.content.isNotEmpty) ...[
          _buildCard(
            title: 'Explanation',
            content: response.content,
            icon: Icons.info_outline,
            headerColor: SmartNotesTheme.accentBlue,
            backgroundColor: Colors.white,
            borderColor: SmartNotesTheme.border,
          ),
        ],

        // Academic Definition Card
        if (response.academicDefinition.isNotEmpty) ...[
          _buildCard(
            title: 'Academic Definition',
            content: response.academicDefinition,
            icon: Icons.menu_book,
            headerColor: Colors.purple,
            backgroundColor: Colors.white,
            borderColor: Colors.purple.shade100,
          ),
        ],

        // Simple Analogy Card
        if (response.simpleDefinition.isNotEmpty) ...[
          _buildCard(
            title: 'Simple Analogy',
            content: response.simpleDefinition,
            icon: Icons.lightbulb_outline,
            headerColor: Colors.orange,
            backgroundColor: Colors.white,
            borderColor: Colors.orange.shade100,
          ),
        ],

        // Exam Standard Suggestions Card
        if (response.examStandardDescription.isNotEmpty) ...[
          _buildCard(
            title: 'Exam Standard Suggestions',
            content: response.examStandardDescription,
            icon: Icons.grade_outlined,
            headerColor: Colors.amber.shade800,
            backgroundColor: Colors.amber.shade50.withOpacity(0.5),
            borderColor: Colors.amber.shade200,
            textColor: Colors.amber.shade900,
          ),
        ],

        // Comparative Table Card (with drag-and-drop support)
        if (response.tableData.isNotEmpty) ...[
          _buildComparativeTableCard(response.tableData),
          const SizedBox(height: 12),
        ],

        // Flowchart Sequence Card
        if (response.flowchartSteps.isNotEmpty) ...[
          _buildFlowchartStepsCard(response.flowchartSteps),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildComparativeTableCard(List<List<String>> tableData) {
    // Generate text representation for drag-and-drop
    final buffer = StringBuffer();
    for (int i = 0; i < tableData.length; i++) {
      buffer.writeln(tableData[i].join(' | '));
      if (i == 0) {
        buffer.writeln(List.generate(tableData[i].length, (_) => '---').join(' | '));
      }
    }
    final tableText = buffer.toString();

    final headers = tableData.first;
    final rows = tableData.skip(1).toList();

    return Draggable<String>(
      data: 'text:$tableText',
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blueAccent),
          ),
          child: const Text('Dragging Table Card', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: SmartNotesTheme.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator, size: 14, color: SmartNotesTheme.accentBlue),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'COMPARATIVE TABLE (DRAG CONCEPT TO CANVAS)',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: SmartNotesTheme.accentBlue, letterSpacing: 0.5),
                    ),
                  ),
                  // Copy Table Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: tableText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied table as Markdown to clipboard!'),
                            backgroundColor: SmartNotesTheme.accentBlue,
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.copy_outlined, size: 12, color: SmartNotesTheme.accentBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder.all(color: Colors.grey.shade100, width: 1),
                children: [
                  // Blue Header Row
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                    ),
                    children: headers.map((h) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        h,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    )).toList(),
                  ),
                  // Alternating Rows (Transparent / Light Grey)
                  ...List.generate(rows.length, (idx) {
                    final isOdd = idx % 2 == 1;
                    final rowData = rows[idx];
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isOdd ? const Color(0xFFF3F4F6) : Colors.transparent,
                      ),
                      children: rowData.map((cell) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text(
                          cell,
                          style: const TextStyle(color: SmartNotesTheme.textMain, fontSize: 11),
                        ),
                      )).toList(),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowchartStepsCard(List<String> steps) {
    final buffer = StringBuffer();
    for (int i = 0; i < steps.length; i++) {
      buffer.writeln('${i + 1}. ${steps[i]}');
    }
    final stepsText = buffer.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SmartNotesTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FLOWCHART SEQUENCE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: SmartNotesTheme.textMuted, letterSpacing: 0.5),
              ),
              // Copy Flowchart Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: stepsText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied flowchart sequence to clipboard!'),
                        backgroundColor: SmartNotesTheme.accentBlue,
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.copy_outlined, size: 12, color: SmartNotesTheme.textMuted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: Center(
                child: Icon(Icons.arrow_downward, size: 14, color: SmartNotesTheme.accentBlue),
              ),
            ),
            itemBuilder: (context, index) {
              final step = steps[index];
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SmartNotesTheme.bgTertiary,
                  border: Border.all(color: SmartNotesTheme.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        color: SmartNotesTheme.accentBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(color: SmartNotesTheme.textMain, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryListView() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyLogs.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 36, color: SmartNotesTheme.textMuted),
          const SizedBox(height: 12),
          const Text('No past chat logs found.', style: TextStyle(color: SmartNotesTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _showHistoryList = false),
            child: const Text('Back to Conversation'),
          )
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Past Conversations', style: TextStyle(fontWeight: FontWeight.bold, color: SmartNotesTheme.textMain, fontSize: 12)),
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep, size: 14, color: Colors.red),
                label: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 11)),
                onPressed: _clearHistory,
              ),
            ],
          ),
        ),
        const Divider(color: SmartNotesTheme.border, height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _historyLogs.length,
            itemBuilder: (context, index) {
              final log = _historyLogs[index] as Map<String, dynamic>;
              final prompt = log['prompt'] as String;
              final style = log['style'] ?? 'Academic';
              final format = log['format'] ?? 'None';
              final date = log['createdAt'] != null
                  ? log['createdAt'].toString().split('T')[0]
                  : '';

              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: SmartNotesTheme.accentBlue, size: 16),
                title: Text(
                  prompt,
                  style: const TextStyle(color: SmartNotesTheme.textMain, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Style: $style • Format: $format • $date',
                  style: const TextStyle(color: SmartNotesTheme.textMuted, fontSize: 10),
                ),
                trailing: const Icon(Icons.chevron_right, size: 14, color: SmartNotesTheme.iconColor),
                onTap: () => _restoreHistoryItem(log),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestion(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 34),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: SmartNotesTheme.iconActive, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: SmartNotesTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final String? style;
  final AiResponse? response;

  _ChatMessage(this.text, {required this.isUser, this.style, this.response, this.isError = false});
}
