import 'package:flutter/material.dart';

import '../../utils/color_pallets.dart';

class FeedbackScreen extends StatefulWidget {
  static const routeName = "/feedback";
  final String? orderId;
  final String? shopId;
  final String? shopName;

  const FeedbackScreen({
    super.key,
    this.orderId,
    this.shopId,
    this.shopName,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isAnonymous = false;
  final List<bool> _tags = [false, false, false, false, false, false];
  
  final List<Map<String, dynamic>> _tagOptions = [
    {'icon': Icons.speed, 'label': 'Fast'},
    {'icon': Icons.verified, 'label': 'Quality'},
    {'icon': Icons.attach_money, 'label': 'Affordable'},
    {'icon': Icons.people, 'label': 'Friendly'},
    {'icon': Icons.location_on, 'label': 'Nearby'},
    {'icon': Icons.cleaning_services, 'label': 'Clean'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    final selectedTags = _tagOptions
        .asMap()
        .entries
        .where((e) => _tags[e.key])
        .map((e) => e.value['label'])
        .toList();

    // Submit feedback logic here (include selectedTags in API call)
    debugPrint('Submitting feedback: rating=$_rating, tags=$selectedTags, comment=${_commentController.text}');
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your ${_isAnonymous ? 'anonymous' : ''} feedback! ${selectedTags.isNotEmpty ? "(Liked: ${selectedTags.join(', ')})" : ""}'),
          backgroundColor: ColorPallets.deepBlue,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: ColorPallets.deepBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (widget.shopName != null) ...[
                      Text(
                        widget.shopName!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Order: ${widget.orderId ?? 'N/A'}',
                        style: const TextStyle(
                          color: ColorPallets.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'How was your experience?',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildStarRating(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What did you like?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        _tagOptions.length,
                        (index) => FilterChip(
                          avatar: Icon(_tagOptions[index]['icon'], size: 18),
                          label: Text(_tagOptions[index]['label']),
                          selected: _tags[index],
                          onSelected: (selected) {
                            setState(() => _tags[index] = selected);
                          },
                          selectedColor: ColorPallets.deepBlue.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Comments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Submit anonymously'),
                      subtitle: const Text('Your name will not be shown'),
                      value: _isAnonymous,
                      onChanged: (value) => setState(() => _isAnonymous = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPallets.deepBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Feedback',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => setState(() => _rating = starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              _rating >= starIndex ? Icons.star : Icons.star_border,
              size: 48,
              color: Colors.amber,
            ),
          ),
        );
      }),
    );
  }
}
