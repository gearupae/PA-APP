import 'package:flutter/material.dart';

/// Renders mind-map JSON from API (stub tree until graph layout plugin added).
class MindMapView extends StatelessWidget {
  const MindMapView({super.key, required this.rootLabel, this.children = const []});

  final String rootLabel;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rootLabel, style: Theme.of(context).textTheme.titleMedium),
            ...children.map(
              (c) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(c)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
