import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/color_pallets.dart';
import '../../utils/engagement_store.dart';
import '../../widgets/common/pill_appbar_title.dart';

class SupportCenterScreen extends StatefulWidget {
  static const routeName = '/supportCenter';

  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final _issueController = TextEditingController();
  final _surveyController = TextEditingController();
  String _screenshotPath = '';
  double _surveyRating = 4;
  final List<String> _features = const [
    'Faster store matching',
    'Better PDF editor',
    'Subscription discounts',
    'Live shop chat',
    'Delivery tracking',
  ];
  List<String> _votes = const <String>[];

  @override
  void initState() {
    super.initState();
    _loadVotes();
  }

  @override
  void dispose() {
    _issueController.dispose();
    _surveyController.dispose();
    super.dispose();
  }

  Future<void> _loadVotes() async {
    final votes = await EngagementStore.getFeatureVotes();
    if (!mounted) return;
    setState(() => _votes = votes);
  }

  Future<void> _pickScreenshot() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _screenshotPath = path);
  }

  Future<void> _submitIssue() async {
    final text = _issueController.text.trim();
    if (text.isEmpty) return;
    await EngagementStore.saveIssue({
      'message': text,
      'screenshotPath': _screenshotPath,
    });
    _issueController.clear();
    setState(() => _screenshotPath = '');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Issue report saved locally')),
    );
  }

  Future<void> _submitSurvey() async {
    if (_surveyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a short comment before submitting.')),
      );
      return;
    }
    await EngagementStore.saveSurvey({
      'rating': _surveyRating,
      'message': _surveyController.text.trim(),
    });
    _surveyController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback saved. +5 reward points')),
    );
  }

  Future<void> _openUri(String uri) async {
    final parsed = Uri.parse(uri);
    if (await canLaunchUrl(parsed)) {
      await launchUrl(parsed, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PillAppBarTitle(
          title: 'Help & Support',
          icon: Icons.support_agent_rounded,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildContactCard(),
          const SizedBox(height: 12),
          _buildFaqCard(),
          const SizedBox(height: 12),
          _buildTroubleshootingCard(),
          const SizedBox(height: 12),
          _buildIssueCard(),
          const SizedBox(height: 12),
          _buildVoteCard(),
          const SizedBox(height: 12),
          _buildSurveyCard(),
          const SizedBox(height: 12),
          _buildLegalCard(),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading:
                Icon(Icons.headset_mic_rounded, color: ColorPallets.deepBlue),
            title: Text('Quick Contact'),
            subtitle: Text('Call, WhatsApp, or email support'),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => _openUri('tel:+919999999999'),
                icon: const Icon(Icons.call_rounded),
                label: const Text('Call'),
              ),
              TextButton.icon(
                onPressed: () => _openUri(
                    'https://wa.me/919999999999?text=I%20need%20help%20with%20Dittox'),
                icon: const Icon(Icons.chat_rounded),
                label: const Text('WhatsApp'),
              ),
              TextButton.icon(
                onPressed: () => _openUri(
                    'mailto:support@dittox.in?subject=Dittox%20Support'),
                icon: const Icon(Icons.email_rounded),
                label: const Text('Email'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard() {
    const faqs = <String, String>{
      'How do I reorder?':
          'Open Order History, expand an order, then tap Reorder Similar.',
      'How do I track an order?':
          'Open Orders and expand the order card to see the live timeline.',
      'How do I print selected pages?':
          'Use the Range button before choosing a shop.',
      'What if payment fails?':
          'Checkout shows a Retry Failed Payment button after a failure.',
    };
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.quiz_rounded, color: ColorPallets.deepBlue),
        title: const Text('FAQ'),
        children: faqs.entries
            .map(
              (entry) => ListTile(
                title: Text(entry.key),
                subtitle: Text(entry.value),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTroubleshootingCard() {
    return const Card(
      child: ExpansionTile(
        leading: Icon(Icons.build_circle_rounded,
            color: ColorPallets.deepBlue),
        title: Text('Troubleshooting Guides'),
        children: [
          ListTile(
              title: Text('Upload stuck'),
              subtitle: Text('Try one PDF at a time or use a smaller file.')),
          ListTile(
              title: Text('Printer not opening'),
              subtitle:
                  Text('Use Store Mode > Print Queue and re-open the file.')),
          ListTile(
              title: Text('Payment not updating'),
              subtitle: Text('Use retry or Pay Later, then refresh Orders.')),
          ListTile(
              title: Text('Video tutorials'),
              subtitle: Text(
                  'Tutorial links can be connected when public videos are ready.')),
        ],
      ),
    );
  }

  Widget _buildIssueCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report an Issue',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              controller: _issueController,
              minLines: 3,
              maxLines: 5,
              decoration:
                  const InputDecoration(hintText: 'Describe what went wrong'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _screenshotPath.isEmpty
                        ? 'No screenshot attached'
                        : 'Screenshot attached',
                    style: const TextStyle(color: ColorPallets.textSecondary),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickScreenshot,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: const Text('Attach'),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitIssue,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Submit Issue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteCard() {
    return Card(
      child: ExpansionTile(
        leading:
            const Icon(Icons.how_to_vote_rounded, color: ColorPallets.deepBlue),
        title: const Text('Feature Request Voting'),
        children: _features.map((feature) {
          final voted = _votes.contains(feature);
          return ListTile(
            title: Text(feature),
            trailing: voted
                ? const Icon(Icons.check_circle, color: ColorPallets.deepBlue)
                : const Icon(Icons.add_circle_outline),
            onTap: voted
                ? null
                : () async {
                    await EngagementStore.voteFeature(feature);
                    await _loadVotes();
                  },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSurveyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Feedback Survey',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Slider(
              value: _surveyRating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _surveyRating.toStringAsFixed(0),
              onChanged: (value) => setState(() => _surveyRating = value),
            ),
            TextField(
              controller: _surveyController,
              decoration:
                  const InputDecoration(hintText: 'What should we improve?'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _submitSurvey,
                icon: const Icon(Icons.rate_review_rounded),
                label: const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _openUri('https://dittox.in/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_rounded),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _openUri('https://dittox.in/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.star_rate_rounded),
            title: const Text('Rate App'),
            subtitle:
                const Text('Store listing can be connected when published'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thanks for rating Dittox.')),
            ),
          ),
        ],
      ),
    );
  }
}
