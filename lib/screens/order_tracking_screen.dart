import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transaction.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_layout.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.transaction,
  });

  final PurchaseTransaction transaction;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  List<LatLng> routePoints = [];
  bool isLoadingRoute = true;
  LatLng sellerLatLng = const LatLng(10.8231, 106.6830); // fallback TP.HCM
  LatLng buyerLatLng = const LatLng(10.7769, 106.6869); // fallback Quận 1

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      // Lấy địa chỉ người bán từ bài đăng
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final post = postProvider.posts.firstWhere(
        (p) => p.id == widget.transaction.postId,
        orElse: () => PostItem(
          id: '',
          title: '',
          content: '',
          category: '',
          type: 'sell',
          price: '',
          authorId: widget.transaction.sellerId,
          authorName: widget.transaction.sellerName,
          location: null,
        ),
      );

      final sellerAddress = (post.location != null && post.location!.trim().isNotEmpty)
          ? post.location!.trim()
          : 'Ho Chi Minh City';
      final buyerAddress = (widget.transaction.buyerInfo.address.trim().isNotEmpty)
          ? widget.transaction.buyerInfo.address.trim()
          : 'Ho Chi Minh City';

      final sellerGeo = await _geocodeAddress(sellerAddress);
      final buyerGeo = await _geocodeAddress(buyerAddress);

      if (!mounted) return;

      setState(() {
        sellerLatLng = sellerGeo ?? sellerLatLng;
        buyerLatLng = buyerGeo ?? buyerLatLng;
      });

      await _fetchRoute(sellerLatLng, buyerLatLng);
    } catch (e) {
      print('Error loading route: $e');
      if (mounted) {
        setState(() => isLoadingRoute = false);
      }
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final encoded = Uri.encodeComponent(address);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1&addressdetails=0&countrycodes=vn';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: () => http.Response('timeout', 500),
      );

      if (response.statusCode != 200) {
        print('Geocode error: statusCode=${response.statusCode}');
        return null;
      }
      
      final body = jsonDecode(response.body) as List<dynamic>;
      if (body.isEmpty) {
        print('No geocode results for: $address');
        return null;
      }
      
      final item = body.first as Map<String, dynamic>;
      final lat = double.tryParse(item['lat'] as String? ?? '') ?? 0;
      final lon = double.tryParse(item['lon'] as String? ?? '') ?? 0;
      if (lat == 0 && lon == 0) {
        print('Invalid coordinates for: $address');
        return null;
      }
      print('Geocoded "$address" to LatLng($lat, $lon)');
      return LatLng(lat, lon);
    } catch (e) {
      print('Error geocoding "$address": $e');
      return null;
    }
  }

  Future<void> _fetchRoute(LatLng seller, LatLng buyer) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${seller.longitude},${seller.latitude};${buyer.longitude},${buyer.latitude}?overview=full&geometries=geojson';

      print('Fetching route: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: () => http.Response('{"code":"timeout"}', 500),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          
          if (data['code'] != 'Ok' || (data['routes'] as List?)?.isEmpty != false) {
            print('OSRM returned code: ${data['code']}');
            if (mounted) {
              setState(() => isLoadingRoute = false);
            }
            return;
          }

          final geometry = data['routes'][0]['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;

          if (coordinates.isEmpty) {
            print('No coordinates in route');
            if (mounted) {
              setState(() => isLoadingRoute = false);
            }
            return;
          }

          final points = coordinates.map<LatLng>((coord) {
            return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
          }).toList();

          print('Loaded ${points.length} route points');

          if (!mounted) return;

          setState(() {
            routePoints = points;
            isLoadingRoute = false;
          });
        } catch (parseError) {
          print('Error parsing OSRM response: $parseError');
          if (mounted) {
            setState(() => isLoadingRoute = false);
          }
        }
      } else {
        print('OSRM error: statusCode=${response.statusCode}, body=${response.body.substring(0, 100)}');
        if (mounted) {
          setState(() => isLoadingRoute = false);
        }
      }
    } catch (e) {
      print('Error fetching route: $e');
      if (mounted) {
        setState(() => isLoadingRoute = false);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    
    // Get updated transaction
    final tx = postProvider.transactions.firstWhere(
      (t) => t.id == widget.transaction.id,
      orElse: () => widget.transaction,
    );

    final isSeller = currentUser?.id == tx.sellerId;
    final isBuyer = currentUser?.id == tx.buyerId;

    // Define order stages based on payment method
    final isCOD = tx.buyerInfo.paymentMethod == 'cash_on_delivery';
    
    final List<_OrderStage> stages = isCOD
        ? [
            // COD: skip payment, go directly to shipping
            _OrderStage(
              title: 'Đang xử lý',
              description: 'Người bán đang xem xét yêu cầu',
              icon: Icons.receipt_long,
              statuses: ['pending', 'approved'],
            ),
            _OrderStage(
              title: 'Đang giao hàng',
              description: 'Đơn hàng đang được giao',
              icon: Icons.local_shipping,
              statuses: ['shipping'],
            ),
            _OrderStage(
              title: 'Hoàn tất',
              description: 'Giao dịch thành công, thanh toán khi nhận hàng',
              icon: Icons.task_alt,
              statuses: ['completed'],
            ),
          ]
        : [
            // Bank transfer: has payment step
            _OrderStage(
              title: 'Đang xử lý',
              description: 'Người bán đang xem xét yêu cầu',
              icon: Icons.receipt_long,
              statuses: ['pending'],
            ),
            _OrderStage(
              title: 'Chờ thanh toán',
              description: 'Chờ người mua chuyển khoản',
              icon: Icons.payment,
              statuses: ['approved', 'awaiting_payment'],
            ),
            _OrderStage(
              title: 'Đã thanh toán',
              description: 'Thanh toán thành công',
              icon: Icons.check_circle,
              statuses: ['payment_confirmed'],
            ),
            _OrderStage(
              title: 'Đang giao hàng',
              description: 'Đơn hàng đang được giao',
              icon: Icons.local_shipping,
              statuses: ['shipping'],
            ),
            _OrderStage(
              title: 'Hoàn tất',
              description: 'Giao dịch thành công',
              icon: Icons.task_alt,
              statuses: ['completed'],
            ),
          ];

    // Find current stage
    int currentStage = 0;
    for (int i = stages.length - 1; i >= 0; i--) {
      if (stages[i].statuses.contains(tx.status)) {
        currentStage = i;
        break;
      }
    }

    return MainLayoutWithCustomAppBar(
      title: 'Theo dõi đơn hàng',
      showDrawer: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin đơn hàng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Mã đơn:', '#${tx.id.substring(0, 8)}'),
                    const Divider(height: 24),
                    _buildInfoRow('Người bán:', tx.sellerName),
                    const SizedBox(height: 8),
                    _buildInfoRow('Người mua:', tx.buyerName),
                    const SizedBox(height: 8),
                    _buildInfoRow('Phương thức:', tx.buyerInfo.paymentMethod == 'bank_transfer' ? 'Chuyển khoản' : 'Trực tiếp'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Trạng thái:', _getStatusText(tx.status)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Progress tracker
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiến trình đơn hàng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
                    
                    // Progress steps
                    ...List.generate(stages.length, (index) {
                      final stage = stages[index];
                      final isCompleted = index < currentStage;
                      final isCurrent = index == currentStage;
                      final isUpcoming = index > currentStage;
                      
                      return _buildProgressStep(
                        stage: stage,
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        isUpcoming: isUpcoming,
                        isLast: index == stages.length - 1,
                      );
                    }),
                  ],
                ),
              ),
            ),            const SizedBox(height: 20),

            // Map card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.map, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Text(
                          'Tuyến đường giao hàng',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: _buildMapWidget(tx),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMapLegend(
                          icon: Icons.circle,
                          color: const Color(0xFF34D399),
                          label: 'Người bán',
                        ),
                        _buildMapLegend(
                          icon: Icons.circle,
                          color: const Color(0xFFEF4444),
                          label: 'Người mua',
                        ),
                        _buildMapLegend(
                          icon: Icons.remove,
                          color: const Color(0xFF2563EB),
                          label: 'Tuyến đường',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),            const SizedBox(height: 20),

            // Action buttons
            if (isSeller && tx.status == 'payment_confirmed')
              ElevatedButton.icon(
                onPressed: () => _startShipping(context, tx),
                icon: const Icon(Icons.local_shipping),
                label: const Text('Bắt đầu giao hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            
            // For COD: button to confirm shipping (after seller approves)
            if (isSeller && isCOD && tx.status == 'approved')
              ElevatedButton.icon(
                onPressed: () => _startShipping(context, tx),
                icon: const Icon(Icons.local_shipping),
                label: const Text('Bắt đầu giao hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

            if (isSeller && tx.status == 'shipping')
              ElevatedButton.icon(
                onPressed: () => _completeOrder(context, tx),
                icon: const Icon(Icons.check_circle),
                label: const Text('Xác nhận đã giao hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

            if (isBuyer && tx.status == 'shipping')
              ElevatedButton.icon(
                onPressed: () => _confirmReceived(context, tx),
                icon: const Icon(Icons.check),
                label: const Text('Xác nhận đã nhận hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWidget(PurchaseTransaction tx) {
    // Nếu đang tải route, hiển thị loading indicator
    if (isLoadingRoute) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Đang tải đường đi...', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    // Nếu không có route points, dùng đường thẳng
    final polylinePoints = routePoints.isEmpty ? [sellerLatLng, buyerLatLng] : routePoints;
    final mapCenter = LatLng(
      (sellerLatLng.latitude + buyerLatLng.latitude) / 2,
      (sellerLatLng.longitude + buyerLatLng.longitude) / 2,
    );

    return FlutterMap(
      options: MapOptions(
        center: mapCenter,
        zoom: 13.0,
        minZoom: 5.0,
        maxZoom: 19.0,
      ),
      children: [
        // Lớp bản đồ OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        // Polyline cho đường giao hàng thực tế
        PolylineLayer(
          polylines: [
            Polyline(
              points: polylinePoints,
              strokeWidth: 4,
              color: const Color(0xFF2563EB),
              borderStrokeWidth: 2,
              borderColor: Colors.white,
            ),
          ],
        ),
        // Marker cho người bán
        MarkerLayer(
          markers: [
            Marker(
              point: sellerLatLng,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.store, size: 20, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                    ),
                    child: Text(
                      tx.sellerName,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Marker cho người mua
            Marker(
              point: buyerLatLng,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.home, size: 20, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                    ),
                    child: Text(
                      tx.buyerName,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapLegend({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep({
    required _OrderStage stage,
    required bool isCompleted,
    required bool isCurrent,
    required bool isUpcoming,
    required bool isLast,
  }) {
    Color iconColor;
    Color lineColor;
    
    if (isCompleted) {
      iconColor = const Color(0xFF16A34A);
      lineColor = const Color(0xFF16A34A);
    } else if (isCurrent) {
      iconColor = const Color(0xFF2563EB);
      lineColor = Colors.grey.shade300;
    } else {
      iconColor = Colors.grey.shade400;
      lineColor = Colors.grey.shade300;
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 2),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : stage.icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: lineColor,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                        color: isUpcoming ? Colors.grey : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stage.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUpcoming ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang xử lý';
      case 'approved':
      case 'awaiting_payment':
        return 'Chờ thanh toán';
      case 'payment_confirmed':
        return 'Đã thanh toán';
      case 'shipping':
        return 'Đang giao hàng';
      case 'completed':
        return 'Hoàn tất';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  void _startShipping(BuildContext context, PurchaseTransaction tx) async {
    final postProvider = context.read<PostProvider>();
    final notifProvider = context.read<NotificationProvider>();
    
    postProvider.updateTransactionStatus(tx.id, 'shipping');
    
    notifProvider.addNotification(
      userId: tx.buyerId,
      type: 'order_shipping',
      message: 'Đơn hàng của bạn đã được giao cho đơn vị vận chuyển.',
      postId: tx.postId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật trạng thái giao hàng')),
    );
  }

  void _completeOrder(BuildContext context, PurchaseTransaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Xác nhận đã giao hàng thành công?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final postProvider = context.read<PostProvider>();
      final notifProvider = context.read<NotificationProvider>();
      
      postProvider.updateTransactionStatus(tx.id, 'completed');
      
      notifProvider.addNotification(
        userId: tx.buyerId,
        type: 'order_completed',
        message: 'Đơn hàng đã được giao thành công. Cảm ơn bạn đã mua hàng!',
        postId: tx.postId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn hàng hoàn tất!')),
      );
    }
  }

  void _confirmReceived(BuildContext context, PurchaseTransaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Xác nhận bạn đã nhận được hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chưa'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đã nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final postProvider = context.read<PostProvider>();
      final notifProvider = context.read<NotificationProvider>();
      
      postProvider.updateTransactionStatus(tx.id, 'completed');
      
      notifProvider.addNotification(
        userId: tx.sellerId,
        type: 'order_completed',
        message: 'Người mua đã xác nhận nhận hàng. Giao dịch hoàn tất!',
        postId: tx.postId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã xác nhận! Giao dịch hoàn tất.')),
      );
    }
  }
}

class _OrderStage {
  final String title;
  final String description;
  final IconData icon;
  final List<String> statuses;

  _OrderStage({
    required this.title,
    required this.description,
    required this.icon,
    required this.statuses,
  });
}
