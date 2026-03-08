import 'package:flutter/material.dart';

import 'package:fox_link_app/shared/widgets/loading_skeleton.dart';

class AppointmentsLoadingSkeleton extends StatelessWidget {
  const AppointmentsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerBox(width: 140, height: 16),
        const SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 140),
        const SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 140),
        const SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 140),
      ],
    );
  }
}
