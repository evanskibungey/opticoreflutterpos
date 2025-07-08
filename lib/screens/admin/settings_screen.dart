import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/screens/sales/sales_history_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Form key and controllers
  final _formKey = GlobalKey<FormState>();
  final _currencyController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _receiptFooterController = TextEditingController();
  final _taxPercentageController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();

  // Opticore theme colors
  final Color _primaryColor = const Color(0xFF3B82F6); // blue-500
  final Color _primaryDarkColor = const Color(0xFF2563EB); // blue-600
  final Color _successColor = const Color(0xFF10B981); // green-500
  final Color _dangerColor = const Color(0xFFEF4444); // red-500
  final Color _warningColor = const Color(0xFFF59E0B); // amber-500
  final Color _surfaceColor = Colors.white;
  final Color _backgroundColor = const Color(0xFFF9FAFB); // gray-50

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _currencyController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _receiptFooterController.dispose();
    _taxPercentageController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await _settingsService.getSettings();
      
      // Populate controllers with values from settings
      _currencyController.text = settings['currency_symbol'] ?? 'Ksh';
      _companyNameController.text = settings['company_name'] ?? 'Eldo Gas';
      _companyAddressController.text = settings['company_address'] ?? '';
      _companyPhoneController.text = settings['company_phone'] ?? '';
      _receiptFooterController.text = settings['receipt_footer'] ?? 'Thank you for your business!';
      _taxPercentageController.text = settings['tax_percentage'] ?? '0';
      _lowStockThresholdController.text = settings['low_stock_threshold'] ?? '5';
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load settings: $e';
        _isLoading = false;
      });
    }
  }

  // Save settings (mock implementation since the service doesn't have a save method)
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful save
      // In a real implementation, you would call an API here
      
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings saved successfully'),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: _dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: _primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Settings',
            onPressed: _loadSettings,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading settings...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildSettingsForm(),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: _dangerColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Settings',
            style: TextStyle(
              color: _dangerColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSettings,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Company Information Section
          _buildSectionHeader('Company Information', Icons.business),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _companyNameController,
            label: 'Company Name',
            icon: Icons.store,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter company name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _companyAddressController,
            label: 'Company Address',
            icon: Icons.location_on,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _companyPhoneController,
            label: 'Company Phone',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          
          // Financial Settings Section
          _buildSectionHeader('Financial Settings', Icons.payments),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _currencyController,
            label: 'Currency Symbol',
            icon: Icons.currency_exchange,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter currency symbol';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _taxPercentageController,
            label: 'Tax Percentage',
            icon: Icons.percent,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffix: '%',
          ),
          const SizedBox(height: 24),
          
          // Receipt Settings Section
          _buildSectionHeader('Receipt Settings', Icons.receipt_long),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _receiptFooterController,
            label: 'Receipt Footer Text',
            icon: Icons.text_fields,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          
          // Inventory Settings Section
          _buildSectionHeader('Inventory Settings', Icons.inventory),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _lowStockThresholdController,
            label: 'Low Stock Threshold',
            icon: Icons.warning_amber,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter low stock threshold';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
            helperText: 'Items with stock below this number will trigger a low stock alert',
          ),
          
          // Add some bottom padding to ensure the content isn't covered by the bottom bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: _primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? helperText,
    String? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor),
          suffix: suffix != null ? Text(suffix) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _dangerColor),
          ),
          filled: true,
          fillColor: _surfaceColor,
          helperText: helperText,
          helperMaxLines: 2,
          helperStyle: TextStyle(color: Colors.grey.shade600),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Saving Settings...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text(
                    'Save Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}