import 'package:flutter/material.dart';
import '../../utils/color_pallets.dart';
import '../../utils/auto_mode_store.dart';

class AutoModeSetupWizard extends StatefulWidget {
  static const routeName = "/autoModeSetup";
  final VoidCallback onComplete;

  const AutoModeSetupWizard({super.key, required this.onComplete});

  @override
  State<AutoModeSetupWizard> createState() => _AutoModeSetupWizardState();
}

class _AutoModeSetupWizardState extends State<AutoModeSetupWizard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Settings
  bool _autoAccept = true;
  bool _autoPrint = false;
  int _copies = 1;
  String _quality = '80gsm';
  bool _notificationSound = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Mode Setup'),
        backgroundColor: ColorPallets.deepBlue,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWelcomePage(),
                _buildOrderPage(),
                _buildPrintPage(),
                _buildNotificationPage(),
                _buildSummaryPage(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? ColorPallets.deepBlue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ColorPallets.deepBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 60,
              color: ColorPallets.deepBlue,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to Auto Mode!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s set up automatic printing for your shop in just a few steps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: Order Handling',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How should new orders be handled?',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          _buildOptionCard(
            title: 'Auto-Accept Orders',
            subtitle: 'Automatically accept new orders',
            icon: Icons.check_circle,
            isSelected: _autoAccept,
            onTap: () => setState(() => _autoAccept = true),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            title: 'Manual Accept',
            subtitle: 'Review each order before accepting',
            icon: Icons.pending,
            isSelected: !_autoAccept,
            onTap: () => setState(() => _autoAccept = false),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: Auto Print',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure automatic printing settings',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Enable Auto Print'),
            subtitle: const Text('Automatically print when order is accepted'),
            value: _autoPrint,
            onChanged: (v) => setState(() => _autoPrint = v),
            activeThumbColor: ColorPallets.deepBlue,
          ),
          if (_autoPrint) ...[
            const SizedBox(height: 16),
            const Text('Default Copies', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 4, 5].map((count) {
                return ChoiceChip(
                  label: Text('$count'),
                  selected: _copies == count,
                  onSelected: (_) => setState(() => _copies = count),
                  selectedColor: ColorPallets.deepBlue.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Paper Quality', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['80gsm', '100gsm', 'Bond'].map((quality) {
                return ChoiceChip(
                  label: Text(quality),
                  selected: _quality == quality,
                  onSelected: (_) => setState(() => _quality = quality),
                  selectedColor: ColorPallets.deepBlue.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 3: Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How do you want to be notified?',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Sound Notifications'),
            subtitle: const Text('Play sound for new orders'),
            value: _notificationSound,
            onChanged: (v) => setState(() => _notificationSound = v),
            activeThumbColor: ColorPallets.deepBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildSummaryItem(
            'Order Handling',
            _autoAccept ? 'Auto-Accept' : 'Manual Accept',
            _autoAccept ? Icons.check_circle : Icons.pending,
          ),
          _buildSummaryItem(
            'Auto Print',
            _autoPrint ? 'Enabled ($_copies copies, $_quality)' : 'Disabled',
            _autoPrint ? Icons.print : Icons.print_disabled,
          ),
          _buildSummaryItem(
            'Notifications',
            _notificationSound ? 'Sound On' : 'Sound Off',
            _notificationSound ? Icons.notifications_active : Icons.notifications_off,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? ColorPallets.deepBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? ColorPallets.deepBlue.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isSelected ? ColorPallets.deepBlue : Colors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? ColorPallets.deepBlue : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: ColorPallets.deepBlue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorPallets.deepBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ColorPallets.deepBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentPage > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _currentPage < 3 ? _nextPage : _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPallets.deepBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_currentPage < 3 ? 'Next' : 'Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage--);
  }

  Future<void> _completeSetup() async {
    await AutoModeSettings.setAutoModeEnabled(true);
    await AutoModeSettings.setAutoSelectShopEnabled(_autoAccept);
    await AutoModeSettings.setDefaultCopies(_copies);
    await AutoModeSettings.setDefaultQuality(_quality);
    
    if (mounted) {
      widget.onComplete();
      Navigator.pop(context);
    }
  }
}