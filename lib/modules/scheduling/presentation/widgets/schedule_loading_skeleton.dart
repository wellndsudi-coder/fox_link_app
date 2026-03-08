import 'package:flutter/material.dart';

import 'package:fox_link_app/shared/widgets/loading_skeleton.dart';

/// Loading skeleton for the premium schedule page.
/// Uses shared [ShimmerBox] for shimmer effect.
class ScheduleLoadingSkeleton extends StatelessWidget {
  const ScheduleLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 140, height: 18),
          const SizedBox(height: 8),
          ShimmerBox(width: 200, height: 14),
          const SizedBox(height: 24),
          ShimmerBox(width: double.infinity, height: 56),
          const SizedBox(height: 16),
          ShimmerBox(width: double.infinity, height: 56),
          const SizedBox(height: 16),
          ShimmerBox(width: double.infinity, height: 56),
          const SizedBox(height: 24),
          ShimmerBox(width: 120, height: 18),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(8, (_) => ShimmerBox(width: 72, height: 44)),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
