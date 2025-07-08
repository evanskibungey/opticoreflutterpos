import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'dart:convert'; // For URL encoding

/// Opticore theme colors - matching web version
class OpticoreColors {
  // Main blues
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);

  // Grays
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Additional colors
  static const Color green500 = Color(0xFF10B981);
  static const Color red500 = Color(0xFFEF4444);
  static const Color whatsapp = Color(0xFF25D366); // WhatsApp green
}

class ReceiptScreen extends StatelessWidget {
  final String receiptNumber;
  final Map<String, dynamic> receiptData;
  final VoidCallback onClose;
  
  const ReceiptScreen({
    Key? key,
    required this.receiptNumber,
    required this.receiptData,
    required this.onClose
  }) : super(key: key);

  // Helper method to safely format numeric values
  String formatNumber(dynamic value) {
    if (value == null) return '0.00';
    
    // If value is already a string, convert it to double first
    if (value is String) {
      try {
        return double.parse(value).toStringAsFixed(2);
      } catch (e) {
        // If parsing fails, return the original string
        return value;
      }
    }
    
    // If value is numeric, format it
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    
    // Fallback for unknown types
    return value.toString();
  }
  
  // Format receipt data into a shareable text message
  String formatReceiptForSharing(
    String receiptNumber,
    DateTime date,
    List<Map<String, dynamic>> items,
    dynamic total,
    String paymentMethod,
    Map<String, dynamic> customer
  ) {
    final buffer = StringBuffer();
    
    // Header with company details
    buffer.writeln('*OPTICORE RECEIPT*');
    buffer.writeln('Receipt #: $receiptNumber');
    buffer.writeln('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(date)}');
    buffer.writeln('');
    
    // Customer info for credit
    if (paymentMethod == 'credit') {
      buffer.writeln('*Customer Details:*');
      buffer.writeln('Name: ${customer['name'] ?? 'Walk-in Customer'}');
      buffer.writeln('Phone: ${customer['phone'] ?? '-'}');
      buffer.writeln('');
    }
    
    // Items
    buffer.writeln('*Items:*');
    for (final item in items) {
      buffer.writeln('${item['name']} - ${item['quantity']} x KSh ${formatNumber(item['price'])} = KSh ${formatNumber(item['subtotal'])}');
    }
    buffer.writeln('');
    
    // Total
    buffer.writeln('*Total: KSh ${formatNumber(total)}*');
    buffer.writeln('Payment Method: ${paymentMethod.toUpperCase()}');
    buffer.writeln('');
    
    // Footer
    buffer.writeln('Thank you for your business!');
    buffer.writeln('Opticore');
    
    return buffer.toString();
  }
  
  // Share receipt via WhatsApp with improved handling
  Future<void> shareViaWhatsApp(BuildContext context, String phoneNumber) async {
    // Parse receipt data here to ensure we have local variables for error handling
    final date = receiptData['date'] != null
        ? DateTime.parse(receiptData['date'])
        : DateTime.now();
    final items = List<Map<String, dynamic>>.from(receiptData['items'] ?? []);
    final dynamic total = receiptData['total'] ?? 0.0;
    final paymentMethod = receiptData['payment_method'] ?? 'cash';
    final customer = receiptData['customer'] ?? {'name': 'Walk-in Customer', 'phone': '-'};
    
    // Format the receipt text
    final receiptText = formatReceiptForSharing(
      receiptNumber,
      date,
      items,
      total,
      paymentMethod,
      customer
    );
    
    try {
      // Prepare the WhatsApp URL - Different approaches for Android and iOS
      // Remove any non-digit characters from phone number except for the + sign
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final encodedText = Uri.encodeComponent(receiptText);
      
      // Create the URL based on platform
      Uri whatsappUri;
      if (Platform.isAndroid) {
        // On Android, we can use whatsapp://send
        whatsappUri = Uri.parse('whatsapp://send?phone=$cleanPhoneNumber&text=$encodedText');
      } else if (Platform.isIOS) {
        // On iOS, we use a web URL (new approach works better on iOS)
        whatsappUri = Uri.parse('https://wa.me/$cleanPhoneNumber?text=$encodedText');
      } else {
        // For other platforms, try the URL scheme first
        whatsappUri = Uri.parse('whatsapp://send?phone=$cleanPhoneNumber&text=$encodedText');
      }
      
      // Try to launch WhatsApp with more robust error handling
      final canLaunch = await canLaunchUrl(whatsappUri);
      
      if (canLaunch) {
        final launched = await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication, // Ensures it opens in the actual WhatsApp app
        );
        
        if (!launched) {
          throw 'Could not launch WhatsApp';
        }
      } else {
        // If we can't launch WhatsApp URL, try the web version as fallback
        final webUri = Uri.parse('https://wa.me/$cleanPhoneNumber?text=$encodedText');
        
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          // If all fails, show a detailed error
          throw 'WhatsApp is not installed or could not be opened';
        }
      }
    } catch (e) {
      print('WhatsApp Error: $e'); // Add this for debugging
      
      // Show more helpful error message with options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: OpticoreColors.red500),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'WhatsApp Not Available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: OpticoreColors.gray800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We couldn\'t open WhatsApp to share the receipt. This could be because:',
                style: TextStyle(
                  color: OpticoreColors.gray700,
                ),
              ),
              SizedBox(height: 12),
              Text('• WhatsApp is not installed on this device'),
              Text('• The phone number format is incorrect'),
              Text('• There is a permission issue'),
              SizedBox(height: 16),
              Text(
                'Would you like to copy the receipt to clipboard instead?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: OpticoreColors.gray800,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: OpticoreColors.gray700,
              ),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // We can safely use receiptText which is in scope
                Clipboard.setData(ClipboardData(text: receiptText));
                
                Navigator.pop(context);
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Receipt copied to clipboard'),
                        ),
                      ],
                    ),
                    backgroundColor: OpticoreColors.green500,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OpticoreColors.blue500,
                foregroundColor: Colors.white,
              ),
              child: Text('Copy Receipt'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
  
  // Show dialog to get customer phone number
  void showPhoneNumberDialog(BuildContext context) {
    // Default to customer phone if available (for credit sales)
    final paymentMethod = receiptData['payment_method'] ?? 'cash';
    final customer = receiptData['customer'] ?? {'name': 'Walk-in Customer', 'phone': ''};
    final initialPhone = paymentMethod == 'credit' ? customer['phone'] ?? '' : '';
    
    final phoneController = TextEditingController(text: initialPhone);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: OpticoreColors.whatsapp.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat,
                color: OpticoreColors.whatsapp,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Share Receipt',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: OpticoreColors.gray800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the customer\'s phone number to share the receipt via WhatsApp:',
              style: TextStyle(
                color: OpticoreColors.gray700,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+254700123456',
                prefixIcon: Icon(Icons.phone, color: OpticoreColors.blue500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: OpticoreColors.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: OpticoreColors.blue500, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: OpticoreColors.gray300),
                ),
                filled: true,
                fillColor: OpticoreColors.gray50,
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 8),
            Text(
              'Include country code (e.g., +254 for Kenya)',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: OpticoreColors.gray600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: OpticoreColors.gray700,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              shareViaWhatsApp(context, phoneController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: OpticoreColors.whatsapp,
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat, size: 18),
                SizedBox(width: 8),
                Text(
                  'Share',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    // Format date
    final date = receiptData['date'] != null
        ? DateTime.parse(receiptData['date'])
        : DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
    
    // Extract items
    final items = List<Map<String, dynamic>>.from(receiptData['items'] ?? []);
    
    // Calculate total
    final dynamic total = receiptData['total'] ?? 0.0;
    
    // Extract payment method
    final paymentMethod = receiptData['payment_method'] ?? 'cash';
    
    // Extract customer details
    final customer = receiptData['customer'] ?? {'name': 'Walk-in Customer', 'phone': '-'};
    
    // Create the Opticore gradient for the app bar
    final opticoreGradient = LinearGradient(
      colors: [
        OpticoreColors.blue500,
        OpticoreColors.blue600,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return Scaffold(
      backgroundColor: OpticoreColors.gray50,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.receipt_long, size: 20),
            SizedBox(width: 8),
            Text(
              'Receipt',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: opticoreGradient),
        ),
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.print, color: Colors.white),
              onPressed: () {
                // TODO: Implement printing functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Printing is not implemented in this demo'),
                        ),
                      ],
                    ),
                    backgroundColor: OpticoreColors.blue600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              tooltip: 'Print Receipt',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Receipt wrapper with improved Opticore shadow
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: OpticoreColors.blue500.withOpacity(0.1),
                        offset: Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                    border: Border.all(color: OpticoreColors.gray200, width: 1),
                  ),
                  child: Column(
                    children: [
                      // Receipt header with Opticore colors
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: opticoreGradient,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Receipt #$receiptNumber',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                paymentMethod == 'cash' ? 'Cash' : 'Credit',
                                style: TextStyle(
                                  color: OpticoreColors.blue700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Company info - Opticore styled
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: OpticoreColors.blue50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.shopping_cart,
                                    color: OpticoreColors.blue500,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Opticore',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: OpticoreColors.gray800,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tel: +254700123456',
                              style: TextStyle(
                                color: OpticoreColors.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Divider(color: OpticoreColors.gray200),
                      
                      // Customer info (for credit) - Opticore styled
                      if (paymentMethod == 'credit')
                        Container(
                          padding: EdgeInsets.all(16),
                          color: OpticoreColors.blue50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: OpticoreColors.blue100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 14,
                                      color: OpticoreColors.blue700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Customer Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: OpticoreColors.blue800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: OpticoreColors.blue700,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Name:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: OpticoreColors.blue700,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      customer['name'] ?? 'Walk-in Customer',
                                      style: TextStyle(
                                        color: OpticoreColors.blue700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: OpticoreColors.blue700,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Phone:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: OpticoreColors.blue700,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      customer['phone'] ?? '-',
                                      style: TextStyle(
                                        color: OpticoreColors.blue700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      
                      if (paymentMethod == 'credit')
                        Divider(color: OpticoreColors.gray200),
                      
                      // Items header - Opticore styled
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: OpticoreColors.gray100,
                          border: Border(
                            bottom: BorderSide(color: OpticoreColors.gray200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Item',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: OpticoreColors.gray700,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Qty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: OpticoreColors.gray700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Price',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: OpticoreColors.gray700,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: OpticoreColors.gray700,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Items list - Opticore styled
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: OpticoreColors.gray200,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item name and serial - Opticore styled
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? 'Unknown Item',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: OpticoreColors.gray800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      if (item['serial_number'] != null) ...[
                                        SizedBox(height: 4),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6, 
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: OpticoreColors.blue50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: OpticoreColors.blue200, 
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.tag,
                                                size: 10,
                                                color: OpticoreColors.blue700,
                                              ),
                                              SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  item['serial_number'],
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: OpticoreColors.blue700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                // Quantity - Opticore styled
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${item['quantity'] ?? 0}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: OpticoreColors.gray700,
                                    ),
                                  ),
                                ),
                                
                                // Price - Opticore styled
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'KSh ${formatNumber(item['price'])}',
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: OpticoreColors.gray700,
                                    ),
                                  ),
                                ),
                                
                                // Subtotal - Opticore styled
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'KSh ${formatNumber(item['subtotal'])}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: OpticoreColors.blue700,
                                    ),
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      Divider(color: OpticoreColors.gray200),
                      
                      // Totals - Opticore styled
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: OpticoreColors.gray50,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(11),
                            bottomRight: Radius.circular(11),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal:',
                                  style: TextStyle(
                                    color: OpticoreColors.gray600,
                                  ),
                                ),
                                Text(
                                  'KSh ${formatNumber(total)}',
                                  style: TextStyle(
                                    color: OpticoreColors.gray800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tax (0%):',
                                  style: TextStyle(
                                    color: OpticoreColors.gray600,
                                  ),
                                ),
                                Text(
                                  'KSh 0.00',
                                  style: TextStyle(
                                    color: OpticoreColors.gray800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    OpticoreColors.blue50,
                                    OpticoreColors.blue100,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: OpticoreColors.blue200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: OpticoreColors.blue800,
                                    ),
                                  ),
                                  Text(
                                    'KSh ${formatNumber(total)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: OpticoreColors.blue700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Footer - Opticore styled
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: OpticoreColors.blue50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.thumb_up_alt_outlined,
                                color: OpticoreColors.blue500,
                                size: 24,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Thank you for your business!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: OpticoreColors.gray800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Keep this receipt for any returns or exchanges.',
                              style: TextStyle(
                                color: OpticoreColors.gray600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Opti',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: OpticoreColors.gray800,
                                  ),
                                ),
                                Text(
                                  'core',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: OpticoreColors.blue500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action buttons - Opticore styled
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Share via WhatsApp button - Opticore styled with WhatsApp color
                      ElevatedButton.icon(
                        onPressed: () => showPhoneNumberDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OpticoreColors.whatsapp,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(Icons.chat, size: 18),
                        label: Text(
                          'Share via WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      // New Sale Button - Opticore styled gradient button
                      ElevatedButton(
                        onPressed: onClose,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          shadowColor: OpticoreColors.blue200,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                OpticoreColors.blue500,
                                OpticoreColors.blue600,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_shopping_cart, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'New Sale',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}