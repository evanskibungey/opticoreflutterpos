// lib/models/report_models.dart

// Base class for report filters - moved to the top for clarity
abstract class ReportFilter {
  Map<String, String> toQueryParams();
}

// Make SalesReportFilter implement ReportFilter
class SalesReportFilter implements ReportFilter {
  final String? dateRange;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? paymentMethod;
  final int? cashierId;
  final int page;
  final int perPage;

  SalesReportFilter({
    this.dateRange,
    this.startDate,
    this.endDate,
    this.paymentMethod,
    this.cashierId,
    this.page = 1,
    this.perPage = 50, // Default to 50 items per page
  });

  @override // Add override annotation to clarify it's implementing the interface
  Map<String, String> toQueryParams() {
    final Map<String, String> params = {};
    
    if (dateRange != null) {
      params['date_range'] = dateRange!;
    }
    
    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String().split('T')[0];
    }
    
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String().split('T')[0];
    }
    
    if (paymentMethod != null && paymentMethod!.isNotEmpty) {
      params['payment_method'] = paymentMethod!;
    }
    
    if (cashierId != null) {
      params['cashier'] = cashierId.toString();
    }
    
    // Add pagination parameters
    params['page'] = page.toString();
    params['per_page'] = perPage.toString();
    
    return params;
  }
}

class SalesReportSummary {
  final int totalSales;
  final double totalRevenue;
  final int totalItems;
  final List<TopProduct> topProducts;
  final List<TopCategory> topCategories;

  SalesReportSummary({
    required this.totalSales,
    required this.totalRevenue,
    required this.totalItems,
    required this.topProducts,
    required this.topCategories,
  });

  factory SalesReportSummary.fromJson(Map<String, dynamic> json) {
    // Make sure summary exists and handle nulls
    final summary = json['summary'] ?? {};
    
    // Parse top products
    final List<TopProduct> topProducts = [];
    if (json['top_products'] != null) {
      topProducts.addAll((json['top_products'] as List)
          .map((item) => TopProduct.fromJson(item)));
    }
    
    // Parse top categories
    final List<TopCategory> topCategories = [];
    if (json['top_categories'] != null) {
      topCategories.addAll((json['top_categories'] as List)
          .map((item) => TopCategory.fromJson(item)));
    }
    
    return SalesReportSummary(
      // Handle null or non-numeric values with null-aware operators
      totalSales: summary['total_sales']?.toInt() ?? 0,
      totalRevenue: double.tryParse(summary['total_revenue']?.toString() ?? '0') ?? 0.0,
      totalItems: summary['total_items']?.toInt() ?? 0,
      topProducts: topProducts,
      topCategories: topCategories,
    );
  }
}

class TopProduct {
  final int id;
  final String name;
  final int totalQuantity;
  final double totalRevenue;

  TopProduct({
    required this.id,
    required this.name,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Product',
      totalQuantity: int.tryParse(json['total_quantity']?.toString() ?? '0') ?? 0,
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0.0,
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
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Category',
      totalQuantity: int.tryParse(json['total_quantity']?.toString() ?? '0') ?? 0,
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0.0,
    );
  }
}

// Make InventoryReportFilter implement ReportFilter
class InventoryReportFilter implements ReportFilter {
  final String? category;
  final String? stockStatus;
  final int page;
  final int perPage;

  InventoryReportFilter({
    this.category,
    this.stockStatus,
    this.page = 1,
    this.perPage = 50,
  });

  @override
  Map<String, String> toQueryParams() {
    final Map<String, String> params = {};
    
    if (category != null && category!.isNotEmpty) {
      params['category'] = category!;
    }
    
    if (stockStatus != null && stockStatus!.isNotEmpty) {
      params['stock_status'] = stockStatus!;
    }
    
    // Add pagination parameters
    params['page'] = page.toString();
    params['per_page'] = perPage.toString();
    
    return params;
  }
}

class InventoryReportSummary {
  final int totalProducts;
  final double totalValue;
  final int lowStockCount;
  final int outOfStockCount;

  InventoryReportSummary({
    required this.totalProducts,
    required this.totalValue,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  factory InventoryReportSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] ?? {};
    
    return InventoryReportSummary(
      totalProducts: summary['total_products']?.toInt() ?? 0,
      totalValue: double.tryParse(summary['total_value']?.toString() ?? '0') ?? 0.0,
      lowStockCount: summary['low_stock_count']?.toInt() ?? 0,
      outOfStockCount: summary['out_of_stock_count']?.toInt() ?? 0,
    );
  }
}

// Make UsersReportFilter implement ReportFilter
class UsersReportFilter implements ReportFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int perPage;

  UsersReportFilter({
    this.startDate,
    this.endDate,
    this.page = 1,
    this.perPage = 50,
  });

  @override
  Map<String, String> toQueryParams() {
    final Map<String, String> params = {};
    
    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String().split('T')[0];
    }
    
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String().split('T')[0];
    }
    
    // Add pagination parameters
    params['page'] = page.toString();
    params['per_page'] = perPage.toString();
    
    return params;
  }
}

// Make StockMovementsReportFilter implement ReportFilter
class StockMovementsReportFilter implements ReportFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? type;
  final int? productId;
  final int page;
  final int perPage;

  StockMovementsReportFilter({
    this.startDate,
    this.endDate,
    this.type,
    this.productId,
    this.page = 1,
    this.perPage = 50,
  });

  @override
  Map<String, String> toQueryParams() {
    final Map<String, String> params = {};
    
    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String().split('T')[0];
    }
    
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String().split('T')[0];
    }
    
    if (type != null && type!.isNotEmpty) {
      params['type'] = type!;
    }
    
    if (productId != null) {
      params['product'] = productId.toString();
    }
    
    // Add pagination parameters
    params['page'] = page.toString();
    params['per_page'] = perPage.toString();
    
    return params;
  }
}

// Add StockMovement and other related models
class StockMovement {
  final int id;
  final int productId;
  final String type;
  final int quantity;
  final String referenceType;
  final int referenceId;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final dynamic product;
  final dynamic user;

  StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.referenceType,
    required this.referenceId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.product,
    this.user,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      type: json['type'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      referenceType: json['reference_type'] ?? '',
      referenceId: json['reference_id'] ?? 0,
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      product: json['product'],
      user: json['user'],
    );
  }
}

// Add user performance model
class UserPerformance {
  final int id;
  final String name;
  final String email;
  final int salesCount;
  final double salesTotal;
  final int itemsSold;
  final double averagePerSale;

  UserPerformance({
    required this.id,
    required this.name,
    required this.email,
    required this.salesCount,
    required this.salesTotal,
    required this.itemsSold,
    required this.averagePerSale,
  });

  factory UserPerformance.fromJson(Map<String, dynamic> json) {
    return UserPerformance(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      salesCount: json['sales_count']?.toInt() ?? 0,
      salesTotal: double.tryParse(json['sales_total']?.toString() ?? '0') ?? 0.0,
      itemsSold: json['items_sold']?.toInt() ?? 0,
      averagePerSale: double.tryParse(json['average_per_sale']?.toString() ?? '0') ?? 0.0,
    );
  }
}