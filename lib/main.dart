// Lab Activity 1 - Ephemeral and App State Implementation
// Created by Mindaphil Francisca Sotelo for Advanced Mobile Programming

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  // Wrapping the root of my application with ChangeNotifierProvider 
  // This allows the ThemeModel to be accessed globally across the entire app
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const MyApp(),
    ),
  );
}

// I created this ThemeModel class with ChangeNotifier to manage the App State (Light/Dark mode)
class ThemeModel with ChangeNotifier {
  bool _isDark = false; // The default theme preference is set to light mode

  // Getter to securely access the current theme status from other widgets
  bool get isDark => _isDark;

  // Function to toggle the theme state 
  // Calling notifyListeners() ensures any widget listening to this state rebuilds immediately
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// MyApp serves as the root widget for sotelo_advmobprog
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listening to my ThemeModel provider to apply the correct theme globally
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      // Dynamically switching between dark and light themes based on the current App State
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: const MyHomePage(),
    );
  }
}

// First screen using a StatefulWidget to demonstrate Ephemeral (Local) State
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // This _counter variable represents the Ephemeral State. 
  // It only exists locally within this specific widget and resets if the widget is destroyed.
  int _counter = 0;

  // Function to increment the counter
  // Using setState() triggers a local UI rebuild only for this specific screen
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeral State Example'),
        actions: [
          // Navigation button to route the user to my second screen (ToggleScreen)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ToggleScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            // Displaying the current value of our ephemeral state
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Second screen using a StatelessWidget to demonstrate interacting with the global App State
class ToggleScreen extends StatelessWidget {
  const ToggleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Accessing the ThemeModel so we can connect our UI Switch to the App State
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App State Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Toggle the theme using the switch below:'),
            // Switch widget that triggers the toggleTheme function in our Provider
            Switch(
              value: themeModel.isDark,
              onChanged: (_) => themeModel.toggleTheme(),
            ),
          ],
        ),
      ),
    );
  }
}