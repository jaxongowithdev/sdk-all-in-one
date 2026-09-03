import 'dart:async';

import 'package:all_in_one_sdk/all_in_one_sdk.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _sdkInitStatus = 'Initializing Firebase/Facebook...';

  @override
  void initState() {
    super.initState();
    unawaited(_initAllInOneSdk());
  }

  Future<void> _initAllInOneSdk() async {
      await SdkBootstrap.apply(
        firebase: FirebaseDynamicConfig(
        googleAppId: '1:1234567890:android:abcdef123456',
        gcmSenderId: '1234567890',
        apiKey: 'replace-with-real-api-key',
        projectId: 'replace-with-real-project-id',
        bundleId: 'com.example.allinonesdkExample',
        storageBucket: 'replace-with-real-project-id.appspot.com',
        isAnalyticsEnabled: true,
      ),
        facebook: FacebookSdkConfig(
        applicationId: '123456789012345',
        clientToken: 'replace-with-real-client-token',
        displayName: 'All In One SDK Example',
        autoLogAppEventsEnabled: true,
        advertiserIdCollectionEnabled: true,
      ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('all_in_one_sdk example')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _sdkInitStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
