import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netify/netify.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final dio = Dio(
    BaseOptions(
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
    ),
  );

  // Initialize Netify with configuration
  // Entry modes: bubble (default), none
  await Netify.init(
    dio: dio,
    config: const NetifyConfig(
      maxLogs: 500,
      entryMode: NetifyEntryMode.bubble,
    ),
  );

  runApp(MyApp(dio: dio));
}

class MyApp extends StatelessWidget {
  final Dio dio;

  const MyApp({super.key, required this.dio});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netify Example',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Wrap home with NetifyWrapper (must be inside MaterialApp for Navigator access)
      // Entry modes: bubble (default), none
      home: NetifyWrapper(
        entryMode: NetifyEntryMode.bubble,
        child: HomePage(dio: dio),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Dio dio;

  const HomePage({super.key, required this.dio});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Netify Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () =>
                Netify.show(context), // Use Netify.show() for manual access
            tooltip: 'Open Netify',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test API Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the floating bubble to open Netify',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Success requests
            _buildSectionTitle('Success Requests'),
            _buildRequestButton(
              'GET Post',
              Colors.green,
              () => _makeRequest(
                  'GET', 'https://jsonplaceholder.typicode.com/posts/1'),
            ),
            const SizedBox(height: 8),
            _buildRequestButton(
              'GET User',
              Colors.green,
              () => _makeRequest(
                  'GET', 'https://jsonplaceholder.typicode.com/users/1'),
            ),
            const SizedBox(height: 16),

            // Error requests
            _buildSectionTitle('Error Requests'),
            _buildRequestButton(
              'GET 404 Error',
              Colors.red,
              () => _makeRequest(
                  'GET', 'https://jsonplaceholder.typicode.com/posts/99999999'),
            ),
            const SizedBox(height: 8),
            _buildRequestButton(
              'Network Error',
              Colors.red,
              () => _makeRequest(
                  'GET', 'https://invalid-domain-that-does-not-exist.com/api'),
            ),
            const SizedBox(height: 16),

            // CRUD operations
            _buildSectionTitle('CRUD Operations'),
            _buildRequestButton(
              'POST Create',
              Colors.blue,
              () => _makeRequest(
                'POST',
                'https://jsonplaceholder.typicode.com/posts',
                data: {
                  'title': 'New Post Title',
                  'body': 'This is the post body content with some details.',
                  'userId': 1,
                },
              ),
            ),
            const SizedBox(height: 8),
            _buildRequestButton(
              'PUT Update',
              Colors.orange,
              () => _makeRequest(
                'PUT',
                'https://jsonplaceholder.typicode.com/posts/1',
                data: {
                  'id': 1,
                  'title': 'Updated Title',
                  'body': 'Updated body content',
                  'userId': 1,
                },
              ),
            ),
            const SizedBox(height: 8),
            _buildRequestButton(
              'DELETE Remove',
              Colors.red.shade700,
              () => _makeRequest(
                  'DELETE', 'https://jsonplaceholder.typicode.com/posts/1'),
            ),
            const SizedBox(height: 16),

            // Batch requests (for testing grouping)
            _buildSectionTitle('Batch Requests (Test Grouping)'),
            _buildRequestButton(
              'Multiple Domains',
              Colors.purple,
              _makeMultipleDomainRequests,
            ),
            const SizedBox(height: 8),
            _buildRequestButton(
              'Same Domain Batch',
              Colors.indigo,
              _makeSameDomainRequests,
            ),
            const SizedBox(height: 24),

            if (_isLoading) const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 16),
            StreamBuilder<List<NetworkLog>>(
              stream: Netify.logsStream,
              initialData: Netify.logs,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                final errorCount =
                    snapshot.data?.where((l) => l.isError).length ?? 0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.wifi, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$count requests captured',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  if (errorCount > 0)
                                    Text(
                                      '$errorCount errors',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red[600]),
                                    ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => Netify.show(context),
                              child: const Text('View'),
                            ),
                          ],
                        ),
                        if (count > 0) ...[
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: Netify.clearLogs,
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Clear'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 80), // Space for floating bubble
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildRequestButton(
      String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(label),
    );
  }

  Future<void> _makeRequest(
    String method,
    String url, {
    Map<String, dynamic>? data,
  }) async {
    setState(() => _isLoading = true);

    try {
      switch (method) {
        case 'GET':
          await widget.dio.get(url);
          break;
        case 'POST':
          await widget.dio.post(url, data: data);
          break;
        case 'PUT':
          await widget.dio.put(url, data: data);
          break;
        case 'DELETE':
          await widget.dio.delete(url);
          break;
      }
    } catch (e) {
      // Error is captured by Netify
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeMultipleDomainRequests() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        widget.dio.get('https://jsonplaceholder.typicode.com/posts/1'),
        widget.dio.get('https://jsonplaceholder.typicode.com/users/1'),
        widget.dio.get('https://httpbin.org/get'),
        widget.dio.get('https://dummyjson.com/products/1'),
      ]);
    } catch (e) {
      // Errors captured by Netify
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeSameDomainRequests() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        widget.dio.get('https://jsonplaceholder.typicode.com/posts/1'),
        widget.dio.get('https://jsonplaceholder.typicode.com/posts/2'),
        widget.dio.get('https://jsonplaceholder.typicode.com/posts/3'),
        widget.dio.get('https://jsonplaceholder.typicode.com/users/1'),
        widget.dio.get('https://jsonplaceholder.typicode.com/comments/1'),
        widget.dio.get('https://jsonplaceholder.typicode.com/albums/1'),
      ]);
    } catch (e) {
      // Errors captured by Netify
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
