import 'package:flutter/material.dart';
import 'package:shimmer_builder/shimmer_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "shimmer_builder example",
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: "Example"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loading = true;

  IconData getIcon(int index) {
    if (index % 2 == 0) {
      return Icons.account_circle;
    }
    return Icons.add_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => setState(() {
              loading = !loading;
            }),
            child: Icon(loading ? Icons.stop : Icons.play_arrow),
          ),
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
          ),
          body: Shimmer(
            enable: loading,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ShimmerPaintOver(child: Icon(Icons.abc, size: 150)),
                ),
                Flexible(
                  child: ListView.builder(
                    itemCount: 6,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ShimmerPaintOver(
                          child: Icon(
                            loading ? Icons.add_box_sharp : getIcon(index),
                            size: 40,
                          ),
                        ),
                        title: ShimmerBuilder(
                          childBuilder: (context) =>
                              Text("child number $index"),
                          sampleBuilder: (context) => Text("child sample 1"),
                        ),
                        subtitle: ShimmerPaintOver(child: Text("subtitle")),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
