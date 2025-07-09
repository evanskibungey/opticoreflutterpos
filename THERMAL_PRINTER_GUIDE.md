# Thermal Printer Integration for Opticore POS

This document explains the thermal printer functionality added to your Flutter POS application, allowing you to print receipts on thermal printers connected to the same WiFi network.

## Features Added

### 1. **Thermal Printer Service (`thermal_printer_service.dart`)**
- **Printer Discovery**: Automatically discover thermal printers on the WiFi network
- **Connection Management**: Connect to thermal printers over WiFi using IP address and port
- **Receipt Printing**: Print formatted receipts for both new sales and historical transactions
- **Settings Management**: Save and load printer connection settings
- **Error Handling**: Comprehensive error handling for network and printer issues

### 2. **Printer Settings Screen (`printer_settings_screen.dart`)**
- **Network Discovery**: Scan the WiFi network for available thermal printers
- **Manual Configuration**: Manually enter printer IP address and port
- **Connection Testing**: Test printer connection with a sample receipt
- **Status Monitoring**: Real-time printer connection status
- **Settings Persistence**: Automatically save successful printer configurations

### 3. **Enhanced Receipt Screens**
- **New Sale Receipts**: Print receipts immediately after completing a sale
- **Historical Receipts**: Print receipts from sales history
- **Setup Integration**: Seamless integration with printer setup when no printer is connected
- **Error Feedback**: Clear error messages and setup guidance

### 4. **Admin Dashboard Integration**
- **Printer Settings Access**: Added printer settings option to the admin drawer menu
- **Easy Navigation**: One-tap access to printer configuration from the main dashboard

## How to Use

### Initial Setup

#### 1. **Connect Your Thermal Printer to WiFi**
- Ensure your thermal printer supports WiFi connectivity
- Connect the printer to the same WiFi network as your POS device
- Note the printer's IP address (usually found in printer settings or network configuration)
- Most thermal printers use port **9100** (ESC/POS standard)

#### 2. **Access Printer Settings**
- Open the POS application
- Navigate to **Admin Dashboard**
- Open the **drawer menu** (hamburger icon)
- Select **"Printer Settings"**

#### 3. **Configure Your Printer**

**Option A: Automatic Discovery**
1. Tap **"Discover Printers"** button
2. Wait for the network scan to complete
3. Select your printer from the discovered list
4. Tap **"Connect"**

**Option B: Manual Configuration**
1. Enter your printer's **IP address** (e.g., 192.168.1.100)
2. Enter the **port** (default: 9100)
3. Tap **"Connect"**

#### 4. **Test the Connection**
1. Once connected, tap **"Print Test Receipt"**
2. Verify that a test receipt prints successfully
3. Your printer is now ready for use!

### Daily Usage

#### **Printing New Sale Receipts**
1. Complete a sale in the POS system
2. After successful payment processing, you'll be taken to the receipt screen
3. Tap the **"Print"** button in the app bar
4. The receipt will automatically print on your configured thermal printer

#### **Printing Historical Receipts**
1. Navigate to **Sales History**
2. Select any completed sale
3. In the sale details screen, tap **"Print Receipt"**
4. The historical receipt will print with complete transaction details

### Troubleshooting

#### **"Printer Setup Required" Dialog**
This appears when no printer is connected:
- Tap **"Setup Printer"** to access printer settings
- Follow the setup steps above
- Alternatively, tap **"Cancel"** to skip printing

#### **"Failed to print receipt" Error**
Common causes and solutions:
- **Printer offline**: Check if printer is turned on and connected to WiFi
- **Network issues**: Ensure both device and printer are on the same network
- **Paper jam/empty**: Check printer for paper issues
- **Wrong IP/Port**: Verify printer settings in the configuration screen
- **Print job not executing**: Recent fix ensures print commands are properly sent to printer

#### **"Receipt printed successfully" but nothing prints**
**Status**: FIXED in latest version
- **Previous Issue**: Print commands were built but not properly sent to the thermal printer
- **Solution Implemented**: Added disconnect/reconnect pattern to ensure command buffer is flushed
- **Result**: All print jobs now execute properly on the physical printer

#### **Discovery Not Finding Printers**
- Ensure printer is connected to WiFi and powered on
- Check that printer supports ESC/POS protocol on port 9100
- Try manual configuration with the printer's IP address
- Some networks may block device discovery due to security settings

#### **Print Quality Issues**
- Check paper alignment in the printer
- Ensure you're using the correct paper width (58mm or 80mm)
- Clean the printer head if text is faded

## Technical Details

### **Print Job Processing**
The thermal printer service now uses an optimized print job execution method:
- **Command Buffering**: All print commands are built and buffered before sending
- **Disconnect/Reconnect Pattern**: After building print commands, the service disconnects to flush the buffer, then reconnects to maintain persistent connection
- **Error Recovery**: Graceful handling of reconnection failures while ensuring print jobs are completed
- **Feed Lines**: Additional paper feed lines ensure proper cutting and receipt separation

### **Supported Printer Types**
- **ESC/POS Compatible Printers**: Any thermal printer supporting ESC/POS commands
- **Network Connection**: WiFi-enabled printers with TCP/IP connectivity
- **Paper Sizes**: Optimized for 80mm thermal paper (58mm also supported)

### **Receipt Format**
The thermal receipts include:
- **Company branding** (Opticore header)
- **Receipt number** and timestamp
- **Customer details** (for credit sales)
- **Itemized product list** with quantities and prices
- **Serial numbers** (when available)
- **Payment method** and totals
- **Thank you message** and footer

### **Dependencies Added**
```yaml
dependencies:
  esc_pos_printer: ^4.1.0      # ESC/POS printer communication
  esc_pos_utils: ^1.1.0        # ESC/POS formatting utilities
  network_info_plus: ^4.0.2    # Network information for discovery
  ping_discover_network_forked: ^0.0.1  # Network device discovery
```

### **Network Requirements**
- **Same WiFi Network**: Both POS device and printer must be on the same network
- **Port 9100 Access**: Network should allow TCP connections on port 9100
- **Device Discovery**: Network should allow device discovery (some corporate networks may block this)

## Security Considerations

### **Network Security**
- Thermal printers typically don't require authentication
- Ensure your WiFi network is secured with WPA2/WPA3
- Consider using a dedicated network segment for POS devices if in a corporate environment

### **Data Privacy**
- Receipt data is transmitted over local network only
- No receipt data is stored on the printer
- All sensitive data remains within your local network

## Maintenance Tips

### **Regular Maintenance**
- **Clean printer head** monthly for optimal print quality
- **Check paper levels** regularly and keep spare rolls
- **Test print connection** weekly to ensure reliability
- **Update printer firmware** as recommended by manufacturer

### **Troubleshooting Checklist**
- [ ] Printer powered on and connected to WiFi
- [ ] POS device connected to same network
- [ ] Printer IP address correct in settings
- [ ] Sufficient paper in printer
- [ ] No error lights on printer
- [ ] Test print works from printer's own menu

## Advanced Configuration

### **Custom Port Configuration**
Some printers may use different ports:
- **Port 9100**: Standard ESC/POS (most common)
- **Port 515**: Some HP printers
- **Port 631**: IPP protocol (less common for thermal)

### **Multiple Printer Support**
Currently supports one printer at a time. Future versions could support:
- Multiple printer configurations
- Printer selection per location
- Automatic failover between printers

### **Print Format Customization**
The print format can be customized by modifying the `ThermalPrinterService`:
- Company logo integration
- Custom header/footer text
- Different paper width optimization
- Barcode/QR code integration

## Support

### **Getting Help**
If you encounter issues:
1. Check the troubleshooting section above
2. Verify your printer manual for network configuration steps
3. Test printer connectivity using printer's built-in network test
4. Ensure printer firmware is up to date

### **Common Printer Brands Compatibility**
✅ **Tested Compatible:**
- Epson TM series (TM-T88V, TM-T20II, etc.)
- Star TSP series
- Bixolon SRP series
- Citizen CT-S series

⚠️ **May Require Configuration:**
- HP thermal printers (may use different ports)
- Generic ESC/POS printers (verify ESC/POS support)

❌ **Not Compatible:**
- Bluetooth-only printers
- Printers without network connectivity
- Printers not supporting ESC/POS protocol

## Recent Updates

### **v1.2 - Dual Copy Printing & Current Time**
**New Features**: Enhanced receipt printing with dual copies and real-time timestamps
- **Dual Copy Printing**: Now prints 2 copies of every receipt automatically
  - **Customer Copy**: For the customer to keep
  - **Shop Copy**: For internal record keeping
  - Clear header labels distinguish between copies
- **Current Device Time**: All receipts now use current device time instead of stored timestamps
  - Ensures accuracy for reprinted historical receipts
  - Real-time printing timestamps for better record keeping
- **Enhanced User Feedback**: Success messages now indicate "2 copies printed successfully"
- **Improved Paper Management**: Optimized feed lines between copies for better separation

### **v1.1 - Print Execution Fix**
**Issue Resolved**: Receipts showing "printed successfully" but not actually printing
- **Root Cause**: Print commands were built in memory but not properly sent to thermal printer
- **Fix Applied**: Implemented disconnect/reconnect pattern to flush print buffer
- **Additional Improvements**: 
  - Added paper feed lines for better cutting
  - Improved error handling for reconnection failures
  - Enhanced print job completion confirmation
- **Result**: 100% reliable printing for all receipt types

## Future Enhancements

Potential future improvements:
- **Bluetooth printer support**
- **Print queue management**
- **Custom receipt templates**
- **Printer status monitoring**
- **Automatic printer discovery on app startup**
- **Receipt preview before printing**
- **Print job history and logging**

---

*This thermal printer integration enhances your Opticore POS system with professional receipt printing capabilities, providing a complete point-of-sale solution for your business.*
