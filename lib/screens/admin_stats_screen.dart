import 'package:flutter/material.dart';

class AdminStatsScreen extends StatefulWidget {
  final int pending;
  final int approved;
  final int rejected;
  final int total;

  const AdminStatsScreen({
    super.key,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.total,
  });

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> with TickerProviderStateMixin {
  late AnimationController _pieChartController;
  late AnimationController _barChartController;
  late Animation<double> _pieChartAnimation;
  late Animation<double> _barChartAnimation;

  @override
  void initState() {
    super.initState();
    _pieChartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _barChartController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _pieChartAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pieChartController, curve: Curves.easeOut),
    );
    _barChartAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _barChartController, curve: Curves.easeOut),
    );
    _pieChartController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _barChartController.forward();
    });
  }

  @override
  void dispose() {
    _pieChartController.dispose();
    _barChartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final approvedPercent = widget.total == 0 ? 0.0 : (widget.approved / widget.total) * 100;
    final rejectedPercent = widget.total == 0 ? 0.0 : (widget.rejected / widget.total) * 100;
    final pendingPercent = widget.total == 0 ? 0.0 : (widget.pending / widget.total) * 100;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),
        const Text(
          'Thống Kê Hệ Thống',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        // Biểu đồ tròn (Pie Chart)
        AnimatedBuilder(
          animation: _pieChartAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.9 + (_pieChartAnimation.value * 0.1),
              child: Opacity(
                opacity: _pieChartAnimation.value,
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tỷ Lệ Trạng Thái Bài Đăng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomPieChart(
                          segments: [
                            PieSegment(
                              value: approvedPercent,
                              color: const Color(0xFF10B981),
                              label: 'Đã duyệt',
                            ),
                            PieSegment(
                              value: rejectedPercent,
                              color: const Color(0xFFEF4444),
                              label: 'Từ chối',
                            ),
                            PieSegment(
                              value: pendingPercent,
                              color: const Color(0xFFF59E0B),
                              label: 'Chờ duyệt',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendItem(
                            color: const Color(0xFF10B981),
                            label: 'Đã duyệt',
                            value: '${approvedPercent.toStringAsFixed(0)}%',
                          ),
                          const SizedBox(height: 12),
                          _LegendItem(
                            color: const Color(0xFFEF4444),
                            label: 'Từ chối',
                            value: '${rejectedPercent.toStringAsFixed(0)}%',
                          ),
                          const SizedBox(height: 12),
                          _LegendItem(
                            color: const Color(0xFFF59E0B),
                            label: 'Chờ duyệt',
                            value: '${pendingPercent.toStringAsFixed(0)}%',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Biểu đồ cột
        AnimatedBuilder(
          animation: _barChartAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.9 + (_barChartAnimation.value * 0.1),
              child: Opacity(
                opacity: _barChartAnimation.value,
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Biểu Đồ Cột - Số Lượng Bài Đăng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _BarColumn(
                        value: widget.pending,
                        maxValue: widget.total == 0 ? 1 : widget.total.toDouble(),
                        label: 'Chờ duyệt',
                        color: const Color(0xFFF59E0B),
                        animationValue: _barChartAnimation.value,
                      ),
                      _BarColumn(
                        value: widget.approved,
                        maxValue: widget.total == 0 ? 1 : widget.total.toDouble(),
                        label: 'Đã duyệt',
                        color: const Color(0xFF10B981),
                        animationValue: _barChartAnimation.value,
                      ),
                      _BarColumn(
                        value: widget.rejected,
                        maxValue: widget.total == 0 ? 1 : widget.total.toDouble(),
                        label: 'Từ chối',
                        color: const Color(0xFFEF4444),
                        animationValue: _barChartAnimation.value,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Thẻ thống kê tổng
        Row(
          children: [
            Expanded(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: _pieChartController, curve: Curves.elasticOut),
                ),
                child: _StatTile(
                  title: 'Tổng Bài Đăng',
                  value: widget.total.toString(),
                  color: const Color(0xFF3B82F6),
                  icon: Icons.post_add,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _pieChartController,
                    curve: const Interval(0.1, 1.0, curve: Curves.elasticOut),
                  ),
                ),
                child: _StatTile(
                  title: 'Chờ Duyệt',
                  value: widget.pending.toString(),
                  color: const Color(0xFFF59E0B),
                  icon: Icons.hourglass_empty,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _pieChartController,
                    curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
                  ),
                ),
                child: _StatTile(
                  title: 'Đã Duyệt',
                  value: widget.approved.toString(),
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _pieChartController,
                    curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
                  ),
                ),
                child: _StatTile(
                  title: 'Từ Chối',
                  value: widget.rejected.toString(),
                  color: const Color(0xFFEF4444),
                  icon: Icons.cancel,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final int value;
  final double maxValue;
  final String label;
  final Color color;
  final double animationValue;

  const _BarColumn({
    required this.value,
    required this.maxValue,
    required this.label,
    required this.color,
    this.animationValue = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final height = (value / maxValue) * 150;
    final animatedHeight = height * animationValue;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: animatedHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

// Custom Pie Chart
class PieSegment {
  final double value;
  final Color color;
  final String label;

  PieSegment({
    required this.value,
    required this.color,
    required this.label,
  });
}

class CustomPieChart extends StatelessWidget {
  final List<PieSegment> segments;

  const CustomPieChart({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PieChartPainter(segments: segments),
      child: Container(),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<PieSegment> segments;

  PieChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = -3.14159 / 2; // Start từ top

    for (final segment in segments) {
      final sweepAngle = (segment.value / 100) * 3.14159 * 2;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) => false;
}
