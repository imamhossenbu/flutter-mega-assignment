import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/promo_code_model.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;

  String _userId = '';
  List<OrderModel> _orders = [];
  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  String? _errorMessage;
  StreamSubscription? _subscription;
  StreamSubscription? _allOrdersSub;

  static final List<OrderModel> _sampleOrders = [
    OrderModel(
      id: 'ORD-98421',
      userId: 'user_sample_1',
      customerName: 'Rahim Ahmed',
      customerPhone: '01712345678',
      shippingAddress: 'House 42, Road 11, Block D, Banani, Dhaka',
      paymentMethod: 'Cash on Delivery',
      items: [
        const OrderItemModel(
          productId: 'prod_1',
          name: 'Sony WH-1000XM5 Wireless Headphones',
          price: 34900.0,
          imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
          selectedColor: 'Black',
          quantity: 1,
        ),
      ],
      subtotal: 34900.0,
      discount: 3490.0,
      deliveryCharge: 60.0,
      tax: 0.0,
      totalAmount: 31470.0,
      promoCode: 'MEGA10',
      status: OrderStatus.processing,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    OrderModel(
      id: 'ORD-98418',
      userId: 'user_sample_1',
      customerName: 'Karim Ullah',
      customerPhone: '01898765432',
      shippingAddress: 'Flat 4B, Green Road, Dhanmondi, Dhaka',
      paymentMethod: 'Cash on Delivery',
      items: [
        const OrderItemModel(
          productId: 'prod_2',
          name: 'Apple Watch Ultra 2 GPS + Cellular',
          price: 98500.0,
          imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80',
          selectedColor: 'Titanium',
          quantity: 1,
        ),
      ],
      subtotal: 98500.0,
      discount: 0.0,
      deliveryCharge: 60.0,
      tax: 0.0,
      totalAmount: 98560.0,
      status: OrderStatus.shipped,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    OrderModel(
      id: 'ORD-98410',
      userId: 'user_sample_1',
      customerName: 'Tanvir Hossain',
      customerPhone: '01911223344',
      shippingAddress: 'Holding 14, Agrabad C/A, Chittagong',
      paymentMethod: 'Cash on Delivery',
      items: [
        const OrderItemModel(
          productId: 'prod_5',
          name: 'JBL Charge 5 Portable Bluetooth Speaker',
          price: 13900.0,
          imageUrl: 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=800&q=80',
          selectedColor: 'Teal',
          quantity: 1,
        ),
      ],
      subtotal: 13900.0,
      discount: 1390.0,
      deliveryCharge: 120.0,
      tax: 0.0,
      totalAmount: 12630.0,
      status: OrderStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static List<OrderModel> get sampleOrders => _sampleOrders;

  List<OrderModel> get orders => _orders;
  List<OrderModel> get allOrders => _allOrders;
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;
  String? get errorMessage => _errorMessage;

  // Customer metrics (excludes cancelled orders)
  double get totalSpent => orders.fold(
      0.0, (sum, o) => sum + (o.status != OrderStatus.cancelled ? o.grandTotal : 0.0));
  int get ordersCount => orders.length;
  int get nonCancelledOrdersCount =>
      orders.where((o) => o.status != OrderStatus.cancelled).length;
  int get activeOrdersCount => orders
      .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
      .length;
  OrderModel? get latestActiveOrder {
    try {
      return orders.firstWhere(
        (o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled,
      );
    } catch (_) {
      return null;
    }
  }

  // Admin metrics
  double get totalRevenue => allOrders.fold(
      0.0, (sum, o) => sum + (o.status != OrderStatus.cancelled ? o.totalAmount : 0.0));
  int get totalOrdersCount => allOrders.length;
  int get pendingOrdersCount =>
      allOrders.where((o) => o.status == OrderStatus.pending).length;
  int get processingOrdersCount =>
      allOrders.where((o) => o.status == OrderStatus.processing).length;
  int get shippedOrdersCount =>
      allOrders.where((o) => o.status == OrderStatus.shipped).length;
  int get deliveredOrdersCount =>
      allOrders.where((o) => o.status == OrderStatus.delivered).length;
  int get cancelledOrdersCount =>
      allOrders.where((o) => o.status == OrderStatus.cancelled).length;

  OrderProvider({OrderRepository? orderRepository})
      : _orderRepository = orderRepository ?? FirestoreOrderRepository();

  void updateUserId(String newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _listenToOrders();
  }

  void initAdminOrdersStream() {
    _allOrdersSub?.cancel();
    _allOrdersSub = _orderRepository.streamAllOrders(limit: 100).listen(
      (orders) {
        _allOrders = orders;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Admin orders stream error: $e');
      },
    );
  }

  Future<void> refreshAdminOrders() async {
    try {
      final list = await _orderRepository.getAllOrders(limit: 100);
      _allOrders = list;
      notifyListeners();
    } catch (e) {
      debugPrint('Admin orders refresh error: $e');
    }
  }

  void _listenToOrders() {
    _subscription?.cancel();
    if (_userId.isEmpty) {
      _orders = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    _subscription = _orderRepository.streamUserOrders(_userId).listen(
      (orders) {
        _orders = orders;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Orders stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refreshUserOrders() async {
    if (_userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _orderRepository.getUserOrders(_userId);
      _orders = list;
    } catch (e) {
      debugPrint('Refresh user orders error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> placeOrder({
    required List<CartItemModel> cartItems,
    required String customerName,
    required String customerPhone,
    required String shippingAddress,
    required double deliveryCharge,
    PromoCodeModel? promoCode,
    double? subtotal,
    double? discount,
    double? shipping,
    double? tax,
    double? grandTotal,
  }) async {
    if (_userId.isEmpty || cartItems.isEmpty) return null;

    _isPlacingOrder = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshotItems = cartItems
          .map((item) => OrderItemModel(
                productId: item.product.id,
                name: item.product.name,
                price: item.product.price,
                imageUrl: item.product.imageUrl,
                unit: item.product.unit,
                selectedColor: item.selectedColor,
                selectedSize: item.selectedSize,
                quantity: item.quantity,
              ))
          .toList();

      final orderId = await _orderRepository.placeOrderInTransaction(
        userId: _userId,
        customerName: customerName,
        customerPhone: customerPhone,
        shippingAddress: shippingAddress,
        items: snapshotItems,
        promoCode: promoCode?.code,
        deliveryCharge: deliveryCharge,
      );

      final createdOrder = await _orderRepository.getOrderById(orderId);
      _isPlacingOrder = false;
      notifyListeners();
      return createdOrder;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isPlacingOrder = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> cancelCustomerOrder(String orderId) async {
    try {
      await _orderRepository.cancelOrderCustomer(
        orderId: orderId,
        userId: _userId,
      );

      // Optimistically update local lists so totalSpent and order counts recalculate immediately
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = _orders[idx].copyWith(status: OrderStatus.cancelled);
      }
      final adminIdx = _allOrders.indexWhere((o) => o.id == orderId);
      if (adminIdx != -1) {
        _allOrders[adminIdx] = _allOrders[adminIdx].copyWith(status: OrderStatus.cancelled);
      }
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) => cancelCustomerOrder(orderId);

  Future<bool> updateOrderStatus(String orderId, String userId, OrderStatus newStatus) async {
    try {
      await _orderRepository.updateOrderStatusAdmin(
        orderId: orderId,
        newStatus: newStatus,
      );
      final idx = _allOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _allOrders[idx] = _allOrders[idx].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _allOrdersSub?.cancel();
    super.dispose();
  }
}
