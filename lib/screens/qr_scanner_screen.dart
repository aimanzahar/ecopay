import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:math';
import '../helpers/database_helper.dart';
import '../models/user.dart';
import '../utils/duitnow_qr_parser.dart';
import '../widgets/ecopay_notification.dart';
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
    detectionSpeed: DetectionSpeed.normal,
    formats: [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
    torchEnabled: false,
    returnImage: false,
  );

  StreamSubscription<BarcodeCapture>? _subscription;
  bool _isProcessing = false;
  bool _hasPermission = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Timer? _timeoutTimer;

  // EcoPay notification state
  bool _isEcoPayNotificationVisible = false;
  String? _merchantName;
  Map<String, String>? _qrData;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStart();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _checkPermissionAndStart() async {
    // Check current camera permission status
    final cameraStatus = await Permission.camera.status;

    if (cameraStatus == PermissionStatus.granted) {
      await _startScanner();
    } else if (cameraStatus == PermissionStatus.denied) {
      // Request permission
      final permission = await Permission.camera.request();

      if (permission == PermissionStatus.granted) {
        await _startScanner();
      } else if (permission == PermissionStatus.permanentlyDenied) {
        setState(() {
          _hasPermission = false;
          _errorMessage =
              'Camera permission is permanently denied. Please enable it in device settings.';
        });
      } else {
        setState(() {
          _hasPermission = false;
          _errorMessage = 'Camera permission is required to scan QR codes';
        });
      }
    } else if (cameraStatus == PermissionStatus.permanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _errorMessage =
            'Camera permission is permanently denied. Please enable it in device settings.';
      });
    }
  }

  Future<void> _startScanner() async {
    try {
      setState(() {
        _hasPermission = true;
        _errorMessage = null;
      });

      // Start listening to the barcode events
      _subscription = controller.barcodes.listen(_handleBarcode);

      // Start the scanner
      await controller.start();
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _errorMessage = 'Failed to start camera: $e';
      });
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    print('DEBUG: _handleBarcode called');
    print('DEBUG: Current processing state: $_isProcessing');

    if (_isProcessing) {
      print('DEBUG: Already processing, returning');
      return;
    }

    _timeoutTimer?.cancel(); // Cancel the timeout if a barcode is detected

    final List<Barcode> barcodes = capture.barcodes;
    print('DEBUG: Number of barcodes detected: ${barcodes.length}');

    if (barcodes.isEmpty) {
      print('DEBUG: No barcodes in capture, returning');
      return;
    }

    final String? code = barcodes.first.rawValue;
    print('DEBUG: Raw barcode value: ${code?.length ?? 0} characters');

    if (code == null || code.isEmpty) {
      print('DEBUG: Code is null or empty, returning');
      return;
    }

    print('DEBUG: QR Code detected: ${code.length} characters');
    print(
      'DEBUG: QR Code content: ${code.substring(0, code.length > 200 ? 200 : code.length)}...',
    );

    setState(() {
      _isProcessing = true;
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Parse the QR code
    final qrData = DuitnowQrParser.parseQrData(code);
    print('DEBUG: Parsed QR data: $qrData');

    if (qrData['isValid'] == 'true') {
      final merchantName = qrData['merchantName'] ?? 'Unknown Merchant';
      print('DEBUG: Valid QR code found, merchant: $merchantName');

      // Check if user has opted in to EcoPay
      _databaseHelper.getUser(1).then((user) {
        if (user?.ecopayOptIn ?? false) {
          _showEcoPayNotification(merchantName, qrData);
        } else {
          // Navigate to payment confirmation with parsed data
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) =>
                      PaymentConfirmationScreen(merchantName: merchantName),
                ),
              )
              .then((_) {
                // Reset processing state when returning from payment
                setState(() {
                  _isProcessing = false;
                });
              });
        }
      });
    } else {
      // Show error for invalid QR code with more detailed information
      final errorMsg =
          qrData['error'] ?? 'This QR code is not a valid payment code.';
      print('DEBUG: Invalid QR code: $errorMsg');

      _showErrorDialog(
        'QR Code Not Supported',
        'This appears to be a QR code, but it\'s not a supported payment format.\n\nSupported formats: DuitNow, EMVCo payment QR codes.\n\nError: $errorMsg',
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

  void _showPermissionDialog(
    String title,
    String message,
    bool isPermanentlyDenied,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (isPermanentlyDenied)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Try requesting permission again
                if (title.contains('Gallery')) {
                  _pickImageFromGallery();
                } else {
                  _checkPermissionAndStart();
                }
              },
              child: const Text('Allow'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      print('DEBUG: Starting gallery image picker');

      // Check current photo permission status
      final photoStatus = await Permission.photos.status;
      print('DEBUG: Photo permission status: $photoStatus');

      PermissionStatus permission;
      if (photoStatus == PermissionStatus.granted) {
        permission = photoStatus;
      } else {
        // Request permission
        print('DEBUG: Requesting photo permission');
        permission = await Permission.photos.request();
        print('DEBUG: Photo permission after request: $permission');
      }

      if (permission == PermissionStatus.granted) {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
        );

        if (image != null) {
          print('DEBUG: Image selected from gallery: ${image.path}');
          await _analyzeImageForQR(image.path);
        } else {
          print('DEBUG: No image selected from gallery');
        }
      } else if (permission == PermissionStatus.permanentlyDenied) {
        _showPermissionDialog(
          'Gallery Permission Required',
          'Gallery access is permanently denied. Please enable it in device settings to select QR code images.',
          true,
        );
      } else {
        _showPermissionDialog(
          'Gallery Permission Required',
          'Gallery access is needed to select QR code images from your photo library.',
          false,
        );
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
      print('DEBUG: Starting image analysis for: $imagePath');
      print('DEBUG: Pre-analysis processing flag: $_isProcessing');
      print('DEBUG: Subscription active: ${_subscription != null}');

      try {
        final bool result = await controller.analyzeImage(imagePath);
        print('DEBUG: Image analysis result: $result');

        if (result) {
          print('DEBUG: Image analysis returned true - QR code detected');
          // For mobile_scanner 3.x, analyzeImage returns bool and should trigger the normal detection flow
          // The actual barcode data will be processed through the _handleBarcode method
          // Show a message to indicate processing
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Processing image... Please wait for results.'),
              duration: Duration(seconds: 3),
            ),
          );

          // Reset processing flag after a delay if no barcode is detected
          _timeoutTimer?.cancel();
          _timeoutTimer = Timer(const Duration(seconds: 5), () {
            print(
              'DEBUG: Image analysis timeout check - mounted: $mounted, processing: $_isProcessing',
            );
            if (_isProcessing && mounted) {
              print(
                'DEBUG: Image analysis timeout - no QR code callback received',
              );
              setState(() {
                _isProcessing = false;
              });
              _showErrorDialog(
                'No QR Code Found',
                'No valid payment QR code found in the selected image.\n\nPlease ensure the image contains a clear, well-lit QR code.',
              );
            } else if (!mounted) {
              print(
                'DEBUG: Widget disposed before timeout callback - avoiding setState',
              );
            }
          });
        } else {
          print('DEBUG: Image analysis returned false - no QR code detected');
          _showErrorDialog(
            'No QR Code Found',
            'No QR code detected in the selected image.\n\nPlease select an image that contains a clear QR code.',
          );
        }
      } catch (e, s) {
        print('CRITICAL: Error during analyzeImage: $e');
        print('CRITICAL: Stacktrace: $s');
        _showErrorDialog(
          'Analysis Critical Error',
          'An unexpected error occurred during image analysis. $e',
        );
      }
    } catch (e) {
      print('DEBUG: Image analysis error: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      _showErrorDialog(
        'Analysis Error',
        'Failed to analyze the selected image.\n\nThis may happen if:\n• The image format is not supported\n• The image is corrupted\n• Device limitations\n\nError: $e',
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
    _timeoutTimer?.cancel();
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
    final isPermanentlyDenied =
        _errorMessage?.contains('permanently denied') ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              isPermanentlyDenied
                  ? 'Camera Access Denied'
                  : 'Camera Permission Required',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Camera permission is required to scan QR codes',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isPermanentlyDenied) ...[
              ElevatedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _checkPermissionAndStart,
                child: const Text('Try Again'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _checkPermissionAndStart,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Grant Camera Permission'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Alternative Option',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can also select a QR code image from your gallery',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select from Gallery'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
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
        if (_isEcoPayNotificationVisible) _buildEcoPayNotification(),
      ],
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        Container(
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
        ),
        Positioned(
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
      ],
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

  Widget _buildEcoPayNotification() {
    if (_merchantName == null || _qrData == null) {
      return const SizedBox.shrink();
    }

    final amount =
        double.tryParse(_qrData!['transactionAmount'] ?? '0.0') ?? 0.0;

    // Calculate round-up amount
    final double roundUp;
    final double cents = amount - amount.floor();
    if (cents == 0) {
      roundUp = 0.5;
    } else if (cents <= 0.5) {
      roundUp = 0.5 - cents;
    } else {
      roundUp = 1.0 - cents;
    }

    return EcoPayNotification(
      merchantName: _merchantName!,
      amount: amount,
      roundUpAmount: roundUp,
      onSkip: _handleSkipEcoPay,
      onRoundUp: _handleRoundUpEcoPay,
      onDismiss: _dismissEcoPayNotification,
    );
  }

  void _showEcoPayNotification(
    String merchantName,
    Map<String, String> qrData,
  ) {
    // Cancel any pending timeout timer to prevent "No QR Code Found" dialog
    _timeoutTimer?.cancel();
    
    final amount = double.tryParse(qrData['transactionAmount'] ?? '0.0') ?? 0.0;

    // Dynamic round-up: round to the nearest RM 0.50 or RM 1.00
    final double roundUp;
    final double cents = amount - amount.floor();
    if (cents == 0) {
      roundUp = 0.5;
    } else if (cents <= 0.5) {
      roundUp = 0.5 - cents;
    } else {
      roundUp = 1.0 - cents;
    }

    setState(() {
      _isEcoPayNotificationVisible = true;
      _merchantName = merchantName;
      _qrData = qrData;
    });
  }

  void _handleSkipEcoPay() {
    if (_merchantName != null) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) =>
                  PaymentConfirmationScreen(merchantName: _merchantName!),
            ),
          )
          .then((_) {
            // Reset processing state when returning from payment
            setState(() {
              _isProcessing = false;
            });
          });
    }
  }

  void _handleRoundUpEcoPay() {
    if (_merchantName != null && _qrData != null) {
      final amount =
          double.tryParse(_qrData!['transactionAmount'] ?? '0.0') ?? 0.0;

      // Calculate round-up amount
      final double roundUp;
      final double cents = amount - amount.floor();
      if (cents == 0) {
        roundUp = 0.5;
      } else if (cents <= 0.5) {
        roundUp = 0.5 - cents;
      } else {
        roundUp = 1.0 - cents;
      }

      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => PaymentConfirmationScreen(
                merchantName: _merchantName!,
                ecoPayAmount: roundUp,
              ),
            ),
          )
          .then((_) {
            // Reset processing state when returning from payment
            setState(() {
              _isProcessing = false;
            });
          });
    }
  }

  void _dismissEcoPayNotification() {
    setState(() {
      _isEcoPayNotificationVisible = false;
      _merchantName = null;
      _qrData = null;
      _isProcessing = false;
    });
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
