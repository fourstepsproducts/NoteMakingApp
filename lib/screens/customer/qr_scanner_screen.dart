import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'customer_register_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanned = true;
        });

        _navigateToForm(barcode.rawValue!);
        break;
      }
    }
  }

  void _navigateToForm(String qrCodeData) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerRegisterScreen(eventId: qrCodeData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                if (state.torchState == TorchState.on) {
                  return const Icon(Icons.flash_on, color: Colors.amber);
                } else {
                  return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                if (state.cameraDirection == CameraFacing.front) {
                  return const Icon(Icons.camera_front);
                } else {
                  return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Camera View Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Scan Frame Overlay
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF4F46E5), width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          // Bottom Controls & Simulation Fallback for Emulator/Testing
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Point camera at the Event Registration QR Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Simulation Button for Emulator Testing
                ElevatedButton.icon(
                  onPressed: () {
                    _navigateToForm('DEMO_EVENT_QR_001');
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Simulate QR Scan (Demo mode)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
