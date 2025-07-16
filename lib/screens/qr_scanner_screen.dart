import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../utils/duitnow_qr_parser.dart';
import 'payment_confirmation_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );

  StreamSubscription<BarcodeCapture>? _subscription;
  bool _isProcessing = false;
  bool _hasPermission = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStart();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _checkPermissionAndStart() async {
    final permission = await Permission.camera.request();

    if (permission == PermissionStatus.granted) {
      setState(() {
        _hasPermission = true;
      });

      // Start listening to the barcode events
      _subscription = controller.barcodes.listen(_handleBarcode);

      // Start the scanner
      await controller.start();
    } else {
      setState(() {
        _hasPermission = false;
        _errorMessage = 'Camera permission is required to scan QR codes';
      });
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Parse the QR code
    final qrData = DuitnowQrParser.parseQrData(code);

    if (qrData['isValid'] == 'true') {
      // Navigate to payment confirmation with parsed data
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentConfirmationScreen(
            merchantName: qrData['merchantName'] ?? 'Unknown Merchant',
          ),
        ),
      );
    } else {
      // Show error for invalid QR code
      _showErrorDialog(
        'Invalid QR Code',
        'This QR code is not a valid DUITNOW payment code.',
      );

      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Check gallery permission
      final permission = await Permission.photos.request();
      if (permission != PermissionStatus.granted) {
        _showErrorDialog(
          'Permission Required',
          'Gallery access is needed to select QR code images.',
        );
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        await _analyzeImageForQR(image.path);
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Error', 'Failed to select image from gallery: $e');
    }
  }

  Future<void> _analyzeImageForQR(String imagePath) async {
    try {
      final bool result = await controller.analyzeImage(imagePath);

      if (result) {
        // For mobile_scanner 3.x, analyzeImage returns bool and should trigger the normal detection flow
        // The actual barcode data will be processed through the _handleBarcode method
        // Show a message to indicate processing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing image... Please wait for results.'),
            duration: Duration(seconds: 2),
          ),
        );

        // Reset processing flag after a delay if no barcode is detected
        Future.delayed(const Duration(seconds: 3), () {
          if (_isProcessing) {
            setState(() {
              _isProcessing = false;
            });
            _showErrorDialog(
              'No QR Code Found',
              'No valid DUITNOW QR code found in the selected image.',
            );
          }
        });
      } else {
        _showErrorDialog(
          'No QR Code Found',
          'No QR code detected in the selected image.',
        );
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog(
        'Analysis Error',
        'Image analysis is not supported on this device or version: $e',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check if camera permission is granted before controlling the scanner
    if (!_hasPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = controller.barcodes.listen(_handleBarcode);
        unawaited(controller.start());
        break;
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _subscription = null;
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImageFromGallery,
            tooltip: 'Select from Gallery',
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: !_hasPermission ? _buildPermissionError() : _buildScanner(),
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Camera permission required',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkPermissionAndStart,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(controller: controller, onDetect: _handleBarcode),
        _buildOverlay(),
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: Theme.of(context).primaryColor,
          borderRadius: 16,
          borderLength: 30,
          borderWidth: 8,
          cutOutSize: 250,
        ),
      ),
      child: const Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Column(
          children: [
            Text(
              'Point your camera at a DUITNOW QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Or tap the gallery icon to select an image',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Processing QR Code...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.borderLength = 40,
    this.borderRadius = 20,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(double x, double y) {
      return Path()
        ..moveTo(x, y + borderLength)
        ..lineTo(x, y + borderRadius)
        ..quadraticBezierTo(x, y, x + borderRadius, y)
        ..lineTo(x + borderLength, y);
    }

    Path getRightTopPath(double x, double y) {
      return Path()
        ..moveTo(x - borderLength, y)
        ..lineTo(x - borderRadius, y)
        ..quadraticBezierTo(x, y, x, y + borderRadius)
        ..lineTo(x, y + borderLength);
    }

    Path getRightBottomPath(double x, double y) {
      return Path()
        ..moveTo(x, y - borderLength)
        ..lineTo(x, y - borderRadius)
        ..quadraticBezierTo(x, y, x - borderRadius, y)
        ..lineTo(x - borderLength, y);
    }

    Path getLeftBottomPath(double x, double y) {
      return Path()
        ..moveTo(x + borderLength, y)
        ..lineTo(x + borderRadius, y)
        ..quadraticBezierTo(x, y, x, y - borderRadius)
        ..lineTo(x, y - borderLength);
    }

    final center = rect.center;
    final left = center.dx - cutOutSize / 2;
    final top = center.dy - cutOutSize / 2;
    final right = center.dx + cutOutSize / 2;
    final bottom = center.dy + cutOutSize / 2;

    return Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, right, bottom),
          Radius.circular(borderRadius),
        ),
      )
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final center = rect.center;
    final left = center.dx - cutOutSize / 2;
    final top = center.dy - cutOutSize / 2;
    final right = center.dx + cutOutSize / 2;
    final bottom = center.dy + cutOutSize / 2;

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    // Draw corner borders
    canvas.drawPath(_getLeftTopPath(left, top), paint);
    canvas.drawPath(_getRightTopPath(right, top), paint);
    canvas.drawPath(_getRightBottomPath(right, bottom), paint);
    canvas.drawPath(_getLeftBottomPath(left, bottom), paint);
  }

  Path _getLeftTopPath(double x, double y) {
    return Path()
      ..moveTo(x, y + borderLength)
      ..lineTo(x, y + borderRadius)
      ..quadraticBezierTo(x, y, x + borderRadius, y)
      ..lineTo(x + borderLength, y);
  }

  Path _getRightTopPath(double x, double y) {
    return Path()
      ..moveTo(x - borderLength, y)
      ..lineTo(x - borderRadius, y)
      ..quadraticBezierTo(x, y, x, y + borderRadius)
      ..lineTo(x, y + borderLength);
  }

  Path _getRightBottomPath(double x, double y) {
    return Path()
      ..moveTo(x, y - borderLength)
      ..lineTo(x, y - borderRadius)
      ..quadraticBezierTo(x, y, x - borderRadius, y)
      ..lineTo(x - borderLength, y);
  }

  Path _getLeftBottomPath(double x, double y) {
    return Path()
      ..moveTo(x + borderLength, y)
      ..lineTo(x + borderRadius, y)
      ..quadraticBezierTo(x, y, x, y - borderRadius)
      ..lineTo(x, y - borderLength);
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
    borderColor: borderColor,
    borderWidth: borderWidth,
    borderLength: borderLength,
    borderRadius: borderRadius,
    cutOutSize: cutOutSize,
  );
}
