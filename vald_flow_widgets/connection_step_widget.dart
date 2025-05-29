// lib/presentation/widgets/vald_flow_widgets/connection_step_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/vald_test_flow_controller.dart';
import '../../controllers/usb_controller.dart';

class ConnectionStepWidget extends StatefulWidget {
  const ConnectionStepWidget({super.key});

  @override
  State<ConnectionStepWidget> createState() => _ConnectionStepWidgetState();
}

class _ConnectionStepWidgetState extends State<ConnectionStepWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _checkExistingConnection();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  void _checkExistingConnection() {
    // Check if USB is already connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usbController = context.read<UsbController>();
      if (usbController.isConnected) {
        final flowController = context.read<ValdTestFlowController>();
        flowController.connectToDevice(usbController.connectedDeviceId ?? 'Connected Device');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UsbController, ValdTestFlowController>(
      builder: (context, usbController, flowController, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Connection Visual
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: usbController.isConnected 
                            ? Colors.green.withOpacity(0.1)
                            : const Color(0xFF1565C0).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: usbController.isConnected 
                              ? Colors.green 
                              : const Color(0xFF1565C0),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        usbController.isConnected ? Icons.link : Icons.link_off,
                        size: 48,
                        color: usbController.isConnected 
                            ? Colors.green 
                            : const Color(0xFF1565C0),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Connection Status
              Text(
                usbController.isConnected 
                    ? 'IzForce Platform Connected'
                    : 'Connect IzForce Platform',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: usbController.isConnected 
                      ? Colors.green 
                      : const Color(0xFF1565C0),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Connection Details
              if (usbController.isConnected) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            usbController.connectedDeviceId ?? 'IzForce Platform',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildConnectionDetail('Sampling', '1000 Hz'),
                          _buildConnectionDetail('Platforms', '2 (L+R)'),
                          _buildConnectionDetail('Load Cells', '8 (4+4)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'No platform detected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Please ensure:\n• IzForce platform is powered on\n• USB dongle is connected\n• Platform is in range',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _connectToPlatform(usbController, flowController),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan for Platforms'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (usbController.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          usbController.errorMessage!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionDetail(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _connectToPlatform(UsbController usbController, ValdTestFlowController flowController) async {
    // Refresh available devices
    await usbController.refreshDevices();
    
    if (usbController.availableDevices.isNotEmpty) {
      // Connect to first available device
      final success = await usbController.connectToDevice(usbController.availableDevices.first);
      
      if (success) {
        // Update flow controller
        flowController.connectToDevice(usbController.connectedDeviceId ?? 'Connected Device');
      }
    } else {
      // Show no devices found message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No IzForce platforms found. Please check connection.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}