import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_theme.dart';

class ShimmerItem extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerItem({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  const ShimmerList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const ShimmerItem(width: 80, height: 80),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerItem(width: double.infinity, height: 16),
                  SizedBox(height: 8),
                  ShimmerItem(width: 150, height: 14),
                  SizedBox(height: 8),
                  ShimmerItem(width: 80, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  const ShimmerGrid({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const ShimmerItem(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}

class ShimmerProductDetails extends StatelessWidget {
  const ShimmerProductDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerItem(width: double.infinity, height: 300, borderRadius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerItem(width: 250, height: 28),
                SizedBox(height: 16),
                ShimmerItem(width: 120, height: 24),
                SizedBox(height: 32),
                ShimmerItem(width: 80, height: 20),
                SizedBox(height: 12),
                ShimmerItem(width: double.infinity, height: 16),
                SizedBox(height: 8),
                ShimmerItem(width: double.infinity, height: 16),
                SizedBox(height: 8),
                ShimmerItem(width: 200, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerForm extends StatelessWidget {
  const ShimmerForm({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Center(child: ShimmerItem(width: 100, height: 100, borderRadius: BorderRadius.all(Radius.circular(50)))),
        SizedBox(height: 32),
        ShimmerItem(width: double.infinity, height: 50),
        SizedBox(height: 16),
        ShimmerItem(width: double.infinity, height: 50),
        SizedBox(height: 16),
        ShimmerItem(width: double.infinity, height: 50),
        SizedBox(height: 32),
        ShimmerItem(width: double.infinity, height: 50, borderRadius: BorderRadius.all(Radius.circular(25))),
      ],
    );
  }
}
