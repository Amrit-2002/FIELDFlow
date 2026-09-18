import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../widgets/diagnostic_card.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _inputController = TextEditingController();

  final List<String> _samplePrompts = [
    'AC is running but cooling is very low.',
    'Solar inverter tripped with ground fault error code E-04.',
    '3-phase motor starter tripping thermal overload relay.',
    'Hydraulic elevator valve block pressure fluctuation.',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _sendQuery([String? customQuery]) {
    final query = customQuery ?? _inputController.text;
    if (query.trim().isNotEmpty) {
      context.read<AiAssistantBloc>().add(RequestTroubleshootingAdvice(query));
      _inputController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.smart_toy_outlined, color: AppColors.amber, size: 22),
            SizedBox(width: 8),
            Text('AI Service Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear History',
            onPressed: () => context.read<AiAssistantBloc>().add(ClearAiAssistantHistory()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Prompt Samples Carousel
          Container(
            height: 44,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _samplePrompts.length,
              itemBuilder: (context, index) {
                final prompt = _samplePrompts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(
                      prompt,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _sendQuery(prompt),
                  ),
                );
              },
            ),
          ),

          // Diagnostic Feed
          Expanded(
            child: BlocBuilder<AiAssistantBloc, AiAssistantState>(
              builder: (context, state) {
                if (state is AiAssistantInitial) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.psychology_outlined, size: 48, color: AppColors.amber),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Field Service Diagnostics',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Describe equipment symptoms or error codes to generate possible causes, recommended checks, and safety precautions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is AiAssistantLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Analyzing: "${state.query}"',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Synthesizing diagnostic checks and safety notes...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AiAssistantLoaded) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: state.history.length,
                    itemBuilder: (context, index) {
                      return DiagnosticCard(advice: state.history[index]);
                    },
                  );
                }

                if (state is AiAssistantError) {
                  return Center(
                    child: Text('Error: ${state.message}'),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Bottom Prompt Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: const Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'Describe machine problem or fault code...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onSubmitted: (_) => _sendQuery(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => _sendQuery(),
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

