class AdminDashboardData {
  final Map<String, dynamic> stats;
  final List<LowStockProduct> lowStockProducts;
  final Map<String, dynamic> salesStats;
  final List<TopProduct> topProducts;
  final List<TopCategory> topCategories;
  final Map<String, dynamic> salesTrendData;
  final List<RecentSale> recentSales;
  final List<PaymentMethodStat> salesByPaymentMethod;
  final Map<String, dynamic> settings;
  final double totalStockValue;

  AdminDashboardData({
    required this.stats,
    required this.lowStockProducts,
    required this.salesStats,
    required this.topProducts,
    required this.topCategories,
    required this.salesTrendData,
    required this.recentSales,
    required this.salesByPaymentMethod,
    required this.settings,
    required this.totalStockValue,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    // Safely handle different data types
    return AdminDashboardData(
      stats: json['stats'] ?? {},
      lowStockProducts: (json['low_stock_products'] as List? ?? [])
          .map((item) => LowStockProduct.fromJson(item))
          .toList(),
      salesStats: json['sales_stats'] ?? {},
      topProducts: (json['top_products'] as List? ?? [])
          .map((item) => TopProduct.fromJson(item))
          .toList(),
      topCategories: (json['top_categories'] as List? ?? [])
          .map((item) => TopCategory.fromJson(item))
          .toList(),
      salesTrendData: json['sales_trend_data'] ?? {},
      recentSales: (json['recent_sales'] as List? ?? [])
          .map((item) => RecentSale.fromJson(item))
          .toList(),
      salesByPaymentMethod: (json['sales_by_payment_method'] as List? ?? [])
          .map((item) => PaymentMethodStat.fromJson(item))
          .toList(),
      settings: json['settings'] ?? {},
      totalStockValue: _parseToDouble(json['total_stock_value']),
    );
  }
  
  // Helper method to safely parse various types to double
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
  
  // Helper method to safely parse various types to int
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
}

class LowStockProduct {
  final int id;
  final String name;
  final int stock;
  final int minStock;
  final Map<String, dynamic> category;

  LowStockProduct({
    required this.id,
    required this.name,
    required this.stock,
    required this.minStock,
    required this.category,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      id: AdminDashboardData._parseToInt(json['id']),
      name: json['name'] ?? '',
      stock: AdminDashboardData._parseToInt(json['stock']),
      minStock: AdminDashboardData._parseToInt(json['min_stock']),
      category: json['category'] ?? {},
    );
  }
}

class TopProduct {
  final int id;
  final String name;
  final String? image;
  final int totalQuantity;
  final double totalRevenue;

  TopProduct({
    required this.id,
    required this.name,
    this.image,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: AdminDashboardData._parseToInt(json['id']),
      name: json['name'] ?? '',
      image: json['image'],
      totalQuantity: AdminDashboardData._parseToInt(json['total_quantity']),
      totalRevenue: AdminDashboardData._parseToDouble(json['total_revenue']),
    );
  }
}

class TopCategory {
  final int id;
  final String name;
  final int totalQuantity;
  final double totalRevenue;

  TopCategory({
    required this.id,
    required this.name,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory TopCategory.fromJson(Map<String, dynamic> json) {
    return TopCategory(
      id: AdminDashboardData._parseToInt(json['id']),
      name: json['name'] ?? '',
      totalQuantity: AdminDashboardData._parseToInt(json['total_quantity']),
      totalRevenue: AdminDashboardData._parseToDouble(json['total_revenue']),
    );
  }
}

class RecentSale {
  final int id;
  final String receiptNumber;
  final String customerName;
  final String userName;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final int itemsCount;
  final String createdAt;

  RecentSale({
    required this.id,
    required this.receiptNumber,
    required this.customerName,
    required this.userName,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.itemsCount,
    required this.createdAt,
  });

  factory RecentSale.fromJson(Map<String, dynamic> json) {
    return RecentSale(
      id: AdminDashboardData._parseToInt(json['id']),
      receiptNumber: json['receipt_number'] ?? '',
      customerName: json['customer_name'] ?? '',
      userName: json['user_name'] ?? '',
      totalAmount: AdminDashboardData._parseToDouble(json['total_amount']),
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? '',
      itemsCount: AdminDashboardData._parseToInt(json['items_count']),
      createdAt: json['created_at'] ?? '',
    );
  }
}

class PaymentMethodStat {
  final String method;
  final int count;
  final double total;

  PaymentMethodStat({
    required this.method,
    required this.count,
    required this.total,
  });

  factory PaymentMethodStat.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStat(
      method: json['method'] ?? '',
      count: AdminDashboardData._parseToInt(json['count']),
      total: AdminDashboardData._parseToDouble(json['total']),
    );
  }
}

class CashierDashboardData {
  final int todaySalesCount;
  final double todayRevenue;
  final List<CashierRecentSale> recentSales;
  final Map<String, dynamic> settings;
  final bool lowStockAlert;
  final int lowStockCount;

  CashierDashboardData({
    required this.todaySalesCount,
    required this.todayRevenue,
    required this.recentSales,
    required this.settings,
    required this.lowStockAlert,
    required this.lowStockCount,
  });

  factory CashierDashboardData.fromJson(Map<String, dynamic> json) {
    return CashierDashboardData(
      todaySalesCount: AdminDashboardData._parseToInt(json['today_sales_count']),
      todayRevenue: AdminDashboardData._parseToDouble(json['today_revenue']),
      recentSales: (json['recent_sales'] as List? ?? [])
          .map((item) => CashierRecentSale.fromJson(item))
          .toList(),
      settings: json['settings'] ?? {},
      lowStockAlert: json['low_stock_alert'] ?? false,
      lowStockCount: AdminDashboardData._parseToInt(json['low_stock_count']),
    );
  }
}

class CashierRecentSale {
  final int id;
  final String receiptNumber;
  final double total;
  final int items;
  final String time;
  final String date;
  final String paymentMethod;

  CashierRecentSale({
    required this.id,
    required this.receiptNumber,
    required this.total,
    required this.items,
    required this.time,
    required this.date,
    required this.paymentMethod,
  });

  factory CashierRecentSale.fromJson(Map<String, dynamic> json) {
    return CashierRecentSale(
      id: AdminDashboardData._parseToInt(json['id']),
      receiptNumber: json['receipt_number'] ?? '',
      total: AdminDashboardData._parseToDouble(json['total']),
      items: AdminDashboardData._parseToInt(json['items']),
      time: json['time'] ?? '',
      date: json['date'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
    );
  }
}