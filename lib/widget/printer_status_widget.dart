import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/services/thermal_printer_service.dart';
import 'package:pos_app/screens/admin/printer_settings_screen.dart';

/// Opticore theme colors
class OpticoreColors {
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color green500 = Color(0xFF10B981);
  static const Color red500 = Color(0xFFEF4444);
  static const Color orange500 = Color(0xFFF97316);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
}

/// Global printer status widget that can be used across the application
class PrinterStatusWidget extends StatelessWidget {
  final bool showLabel;
  final bool isCompact;
  final VoidCallback? onTap;

  const PrinterStatusWidget({
    Key? key,
    this.showLabel = true,
    this.isCompact = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThermalPrinterService>(
      builder: (context, printerService, child) {
        final isConnected = printerService.isConnected;
        final isConnecting = printerService.connectionStatus == PrinterConnectionStatus.connecting;
        
        Color statusColor;
        IconData statusIcon;
        String statusText;
        
        if (isConnected) {
          statusColor = OpticoreColors.green500;
          statusIcon = Icons.print;
          statusText = 'Connected';
        } else if (isConnecting) {
          statusColor = OpticoreColors.orange500;
          statusIcon = Icons.sync;
          statusText = 'Connecting...';
        } else {
          statusColor = OpticoreColors.red500;
          statusIcon = Icons.print_disabled;
          statusText = 'Disconnected';
        }

        if (isCompact) {
          return InkWell(
            onTap: onTap ?? () => _navigateToPrinterSettings(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 16,
                  ),
                  if (showLabel) ...[
                    SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return InkWell(
          onTap: onTap ?? () => _navigateToPrinterSettings(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Printer Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: OpticoreColors.gray600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      if (isConnected && printerService.connectedPrinterIp != null) ...[
                        SizedBox(height: 2),
                        Text(
                          '${printerService.connectedPrinterIp}:${printerService.connectedPrinterPort}',
                          style: TextStyle(
                            fontSize: 12,
                            color: OpticoreColors.gray600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: OpticoreColors.gray600,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToPrinterSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterSettingsScreen(),
      ),
    );
  }
}

/// App bar printer status indicator
class AppBarPrinterStatus extends StatelessWidget {
  final bool showText;

  const AppBarPrinterStatus({
    Key? key,
    this.showText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThermalPrinterService>(
      builder: (context, printerService, child) {
        final isConnected = printerService.isConnected;
        final isConnecting = printerService.connectionStatus == PrinterConnectionStatus.connecting;
        
        Color statusColor;
        IconData statusIcon;
        String statusText;
        
        if (isConnected) {
          statusColor = Colors.green;
          statusIcon = Icons.print;
          statusText = 'Connected';
        } else if (isConnecting) {
          statusColor = Colors.orange;
          statusIcon = Icons.sync;
          statusText = 'Connecting...';
        } else {
          statusColor = Colors.red;
          statusIcon = Icons.print_disabled;
          statusText = 'Disconnected';
        }

        return GestureDetector(
          onTap: () => _navigateToPrinterSettings(context),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  color: Colors.white,
                  size: 16,
                ),
                if (showText) ...[
                  SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToPrinterSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterSettingsScreen(),
      ),
    );
  }
}

/// Floating printer status indicator for screens where printing is common
class FloatingPrinterStatus extends StatelessWidget {
  final VoidCallback? onPrintTap;
  final bool showPrintButton;

  const FloatingPrinterStatus({
    Key? key,
    this.onPrintTap,
    this.showPrintButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThermalPrinterService>(
      builder: (context, printerService, child) {
        // Only show if printer is not connected
        if (printerService.isConnected) {
          return SizedBox.shrink();
        }

        return Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Print button (if printer is connected and showPrintButton is true)
              if (showPrintButton && printerService.isConnected && onPrintTap != null) ...[
                FloatingActionButton(
                  onPressed: onPrintTap,
                  backgroundColor: OpticoreColors.blue500,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.print),
                  heroTag: "print_fab",
                ),
                SizedBox(height: 8),
              ],
              
              // Printer setup button (if not connected)
              if (!printerService.isConnected)
                FloatingActionButton.extended(
                  onPressed: () => _navigateToPrinterSettings(context),
                  backgroundColor: OpticoreColors.orange500,
                  foregroundColor: Colors.white,
                  icon: Icon(Icons.print_disabled),
                  label: Text('Setup Printer'),
                  heroTag: "setup_printer_fab",
                ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToPrinterSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterSettingsScreen(),
      ),
    );
  }
}

/// Printer status banner for displaying connection issues
class PrinterStatusBanner extends StatelessWidget {
  final bool dismissible;
  final VoidCallback? onDismiss;

  const PrinterStatusBanner({
    Key? key,
    this.dismissible = false,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThermalPrinterService>(
      builder: (context, printerService, child) {
        // Only show banner if printer is not connected
        if (printerService.isConnected) {
          return SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OpticoreColors.orange500.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OpticoreColors.orange500.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: OpticoreColors.orange500,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Printer Not Connected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: OpticoreColors.orange500,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Set up a thermal printer to enable receipt printing.',
                      style: TextStyle(
                        color: OpticoreColors.gray700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _navigateToPrinterSettings(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OpticoreColors.orange500,
                  side: BorderSide(color: OpticoreColors.orange500),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size(0, 0),
                ),
                child: Text(
                  'Setup',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (dismissible) ...[
                SizedBox(width: 8),
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: OpticoreColors.gray600,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _navigateToPrinterSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterSettingsScreen(),
      ),
    );
  }
}

/// Connection retry widget for failed connections
class PrinterConnectionRetry extends StatelessWidget {
  const PrinterConnectionRetry({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThermalPrinterService>(
      builder: (context, printerService, child) {
        if (printerService.connectionStatus != PrinterConnectionStatus.error) {
          return SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OpticoreColors.red500.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: OpticoreColors.red500.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: OpticoreColors.red500,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Printer Connection Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: OpticoreColors.red500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                printerService.printerStatus,
                style: TextStyle(
                  color: OpticoreColors.gray700,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => printerService.reconnect(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OpticoreColors.blue500,
                        side: BorderSide(color: OpticoreColors.blue500),
                      ),
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text('Retry Connection'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToPrinterSettings(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OpticoreColors.blue500,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.settings, size: 18),
                      label: Text('Settings'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToPrinterSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterSettingsScreen(),
      ),
    );
  }
}
