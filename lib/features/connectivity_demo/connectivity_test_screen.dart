import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/network_test.dart';

class ConnectivityTestScreen extends ConsumerStatefulWidget {
  const ConnectivityTestScreen({super.key});

  @override
  ConsumerState<ConnectivityTestScreen> createState() => _ConnectivityTestScreenState();
}

class _ConnectivityTestScreenState extends ConsumerState<ConnectivityTestScreen> {
  Map<String, dynamic>? testResults;
  bool isTestRunning = false;

  Future<void> runConnectivityTest() async {
    setState(() {
      isTestRunning = true;
      testResults = null;
    });

    try {
      // Run comprehensive connectivity test
      final results = await NetworkTest.runComprehensiveTest();
      
      setState(() {
        testResults = results;
        isTestRunning = false;
      });
    } catch (e) {
      setState(() {
        testResults = {
          'error': 'Test failed: $e',
          'timestamp': DateTime.now().toIso8601String(),
        };
        isTestRunning = false;
      });
    }
  }

  Future<void> retrySupabaseConnection() async {
    setState(() {
      isTestRunning = true;
    });

    try {
      // Try to reinitialize Supabase
      await SupabaseConfig.initialize();
      
      // Test if it's working
      final working = await SupabaseConfig.isSupabaseWorking();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(working ? 'Supabase reconnected successfully!' : 'Supabase still not working'),
          backgroundColor: working ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reconnection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isTestRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connectivity Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Network Connectivity Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This will test your internet connection and Supabase connectivity.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isTestRunning ? null : runConnectivityTest,
                            icon: isTestRunning 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.network_check),
                            label: Text(isTestRunning ? 'Testing...' : 'Run Test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isTestRunning ? null : retrySupabaseConnection,
                            icon: isTestRunning 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                            label: Text(isTestRunning ? 'Retrying...' : 'Retry Supabase'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (testResults != null) ...[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Test Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Timestamp: ${testResults!['timestamp'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (testResults!['error'] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      border: Border.all(color: Colors.red.shade200),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.red.shade600),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            testResults!['error'],
                                            style: TextStyle(color: Colors.red.shade800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // Network tests
                                  if (testResults!['network'] != null) ...[
                                    const Text(
                                      'Network Tests:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    ...((testResults!['network'] as Map<String, dynamic>).entries.map((entry) {
                                      final success = entry.value as bool;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              success ? Icons.check_circle : Icons.error,
                                              color: success ? Colors.green : Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text('${entry.key}: ${success ? "PASS" : "FAIL"}'),
                                          ],
                                        ),
                                      );
                                    })),
                                    const Divider(height: 24),
                                  ],
                                  
                                  // Authentication tests
                                  if (testResults!['authentication'] != null) ...[
                                    const Text(
                                      'Authentication Status:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    ...((testResults!['authentication'] as Map<String, dynamic>).entries.map((entry) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Text(
                                          '${entry.key}: ${entry.value}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    })),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text(
                    'Tap "Run Test" to check your connectivity',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}