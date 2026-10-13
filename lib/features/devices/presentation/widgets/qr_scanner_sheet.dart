import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
    final accent = theme.colorScheme.primary;
    const frame = 200.0;
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
          // Viewfinder: dims everything outside the frame, accent edge with a soft glow.
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRect(
                child: Center(
                  child: Container(
                    width: frame,
                    height: frame,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.45), spreadRadius: 999),
                        BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.lg,
            right: AppSpacing.md,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Text('Scan tracker QR code',
                        style: theme.textTheme.titleSmall?.copyWith(fontSize: 15, color: Colors.white)),
                  ),
                  _CameraButton(
                    tooltip: 'Torch',
                    icon: AppIcons.sun,
                    onPressed: () => _controller.toggleTorch(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CameraButton(
                    tooltip: 'Close',
                    icon: AppIcons.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: AppSpacing.xxl,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'The QR code is on the back of your tracker or inside the box.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: Colors.white70),
                  ),
                  AppSpacing.gapMd,
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: Colors.white,
                      iconColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(AppIcons.edit, size: 18),
                    label: const Text('Enter ID manually'),
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

/// Translucent round control over the (always dark) camera view.
class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        side: const BorderSide(color: Colors.white24),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Text('Camera unavailable', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
              AppSpacing.gapSm,
              Text(message,
                  textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: Colors.white70)),
              AppSpacing.gapSm,
              Text('You can enter the device ID manually instead.',
                  textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
