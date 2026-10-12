import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';

/// Opens the camera to scan a tracker's QR code. Returns the decoded ID, or
/// null if the user cancels / the camera is unavailable (they can then type it).
Future<String?> showQrScanner(BuildContext context) => showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      showDragHandle: false,
      builder: (_) => const _QrScannerSheet(),
    );

class _QrScannerSheet extends StatefulWidget {
  const _QrScannerSheet();

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// QR codes may contain the bare ID or a URL like https://trackpro.app/d/TRK-123.
  static String _extractId(String raw) {
    final trimmed = raw.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) return uri.pathSegments.last.toUpperCase();
    return trimmed.toUpperCase();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null || raw.isEmpty) return;
    _done = true;
    Navigator.pop(context, _extractId(raw));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _CameraUnavailable(
                message: error.errorDetails?.message ?? 'Camera access was denied or no camera is available.',
              ),
            ),
          ),
          // Viewfinder
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.signalLight, width: 3),
                borderRadius: AppRadius.xlAll,
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Text('Scan tracker QR code',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                  ),
                  IconButton(
                    onPressed: () => _controller.toggleTorch(),
                    icon: const Icon(AppIcons.sun, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(AppIcons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: AppSpacing.xxl,
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'The QR code is on the back of your tracker or inside the box.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  AppSpacing.gapMd,
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Enter ID manually'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.scan, color: Colors.white54, size: 48),
              AppSpacing.gapLg,
              const Text('Camera unavailable',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              AppSpacing.gapSm,
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              AppSpacing.gapSm,
              const Text('You can enter the device ID manually instead.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
