import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import '../controller.dart';
import '../model/conversion_status.dart';
import '../utilities/constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/conversion_history_card.dart';
import '../widgets/speed_dial_widget.dart';


class ToolHomeScreen extends StatelessWidget {
  const ToolHomeScreen({super.key});

  void _showSnackBar(BuildContext context, ConversionStatus status) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (status.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status.message),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: status.progress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
          duration: const Duration(minutes: 5),
        ),
      );
    } else if (status.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status.message),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              final provider = context.read<DocumentConverterProvider>();
              if (provider.history.isNotEmpty) {
                OpenFile.open(provider.history.first.outputPath);
              }
            },
          ),
        ),
      );
    } else if (status.isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentConverterProvider>(
      builder: (context, provider, child) {
        // Show snackbar on status change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (provider.status.state != ConversionState.idle) {
            _showSnackBar(context, provider.status);

            // Reset status after showing success/error
            if (provider.status.isSuccess || provider.status.isError) {
              Future.delayed(const Duration(seconds: 2), () {
                if (context.mounted) {
                  provider.resetStatus();
                }
              });
            }
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.appTitle),
            elevation: 2,
            actions: [
              if (provider.history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: AppStrings.clearHistory,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear History'),
                        content: const Text(
                          'Are you sure you want to clear all conversion history?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.clearHistory();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: provider.history.isEmpty
              ? const EmptyState()
              : ListView.builder(
            itemCount: provider.history.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final history = provider.history[index];
              return ConversionHistoryCard(history: history);
            },
          ),
          floatingActionButton: const SpeedDialWidget(),
        );
      },
    );
  }
}