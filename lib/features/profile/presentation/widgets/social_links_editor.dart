import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/social_links.dart';

class SocialLinksEditor extends StatefulWidget {
  final SocialLinks? initialLinks;
  final Function(SocialLinks) onSave;
  final bool isEditing;

  const SocialLinksEditor({
    super.key,
    this.initialLinks,
    required this.onSave,
    this.isEditing = false,
  });

  @override
  State<SocialLinksEditor> createState() => _SocialLinksEditorState();
}

class _SocialLinksEditorState extends State<SocialLinksEditor> {
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  late TextEditingController _linkedinController;
  late TextEditingController _xController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _facebookController = TextEditingController(text: widget.initialLinks?.facebook ?? '');
    _instagramController = TextEditingController(text: widget.initialLinks?.instagram ?? '');
    _tiktokController = TextEditingController(text: widget.initialLinks?.tiktok ?? '');
    _linkedinController = TextEditingController(text: widget.initialLinks?.linkedin ?? '');
    _xController = TextEditingController(text: widget.initialLinks?.x ?? '');
    _isEditing = widget.isEditing;
  }

  @override
  void dispose() {
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _linkedinController.dispose();
    _xController.dispose();
    super.dispose();
  }

  SocialLinks _getCurrentLinks() {
    return SocialLinks(
      facebook: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
      instagram: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
      tiktok: _tiktokController.text.trim().isEmpty ? null : _tiktokController.text.trim(),
      linkedin: _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim(),
      x: _xController.text.trim().isEmpty ? null : _xController.text.trim(),
    );
  }

  void _saveLinks() {
    final links = _getCurrentLinks();
    widget.onSave(links);
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Social Profiles',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Connect your social accounts',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!_isEditing)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(
                    Icons.edit,
                    color: AppColors.richGold,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          if (_isEditing) ...[
            // Edit mode
            _buildSocialInput(
              controller: _facebookController,
              label: 'Facebook',
              hint: 'Username or profile URL',
              icon: Icons.facebook,
              color: const Color(0xFF1877F2),
            ),
            _buildSocialInput(
              controller: _instagramController,
              label: 'Instagram',
              hint: 'Username (without @)',
              icon: Icons.camera_alt,
              color: const Color(0xFFE4405F),
            ),
            _buildSocialInput(
              controller: _tiktokController,
              label: 'TikTok',
              hint: 'Username (without @)',
              icon: Icons.music_note,
              color: const Color(0xFF000000),
            ),
            _buildSocialInput(
              controller: _linkedinController,
              label: 'LinkedIn',
              hint: 'Username or profile URL',
              icon: Icons.work,
              color: const Color(0xFF0A66C2),
            ),
            _buildSocialInput(
              controller: _xController,
              label: 'X (Twitter)',
              hint: 'Username (without @)',
              icon: Icons.alternate_email,
              color: const Color(0xFF000000),
            ),

            const SizedBox(height: 16),

            // Save and Cancel buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        // Reset to original values
                        _facebookController.text = widget.initialLinks?.facebook ?? '';
                        _instagramController.text = widget.initialLinks?.instagram ?? '';
                        _tiktokController.text = widget.initialLinks?.tiktok ?? '';
                        _linkedinController.text = widget.initialLinks?.linkedin ?? '';
                        _xController.text = widget.initialLinks?.x ?? '';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveLinks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // View mode
            _buildSocialItem(
              label: 'Facebook',
              value: widget.initialLinks?.facebook,
              url: widget.initialLinks?.facebookUrl,
              icon: Icons.facebook,
              color: const Color(0xFF1877F2),
            ),
            _buildSocialItem(
              label: 'Instagram',
              value: widget.initialLinks?.instagram,
              url: widget.initialLinks?.instagramUrl,
              icon: Icons.camera_alt,
              color: const Color(0xFFE4405F),
            ),
            _buildSocialItem(
              label: 'TikTok',
              value: widget.initialLinks?.tiktok,
              url: widget.initialLinks?.tiktokUrl,
              icon: Icons.music_note,
              color: const Color(0xFF000000),
            ),
            _buildSocialItem(
              label: 'LinkedIn',
              value: widget.initialLinks?.linkedin,
              url: widget.initialLinks?.linkedinUrl,
              icon: Icons.work,
              color: const Color(0xFF0A66C2),
            ),
            _buildSocialItem(
              label: 'X (Twitter)',
              value: widget.initialLinks?.x,
              url: widget.initialLinks?.xUrl,
              icon: Icons.alternate_email,
              color: const Color(0xFF000000),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          filled: true,
          fillColor: AppColors.backgroundDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 2),
          ),
          prefixIcon: Icon(icon, color: color),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialItem({
    required String label,
    String? value,
    String? url,
    required IconData icon,
    required Color color,
  }) {
    final hasValue = value != null && value.isNotEmpty;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: hasValue ? color.withOpacity(0.1) : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: hasValue ? color : AppColors.textTertiary,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        hasValue ? (value.startsWith('http') ? value.split('/').last : value) : 'Not connected',
        style: TextStyle(
          color: hasValue ? AppColors.textPrimary : AppColors.textTertiary,
          fontSize: 15,
        ),
      ),
      trailing: hasValue && url != null
          ? IconButton(
              onPressed: () => _launchUrl(url),
              icon: const Icon(
                Icons.open_in_new,
                color: AppColors.textSecondary,
                size: 20,
              ),
            )
          : null,
    );
  }
}

class SocialLinksDisplay extends StatelessWidget {
  final SocialLinks? socialLinks;
  final bool compact;

  const SocialLinksDisplay({
    super.key,
    this.socialLinks,
    this.compact = false,
  });

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    if (socialLinks == null || !socialLinks!.hasAnyLink) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (socialLinks!.facebook != null)
            _buildCompactIcon(Icons.facebook, const Color(0xFF1877F2), socialLinks!.facebookUrl!),
          if (socialLinks!.instagram != null)
            _buildCompactIcon(Icons.camera_alt, const Color(0xFFE4405F), socialLinks!.instagramUrl!),
          if (socialLinks!.tiktok != null)
            _buildCompactIcon(Icons.music_note, AppColors.textPrimary, socialLinks!.tiktokUrl!),
          if (socialLinks!.linkedin != null)
            _buildCompactIcon(Icons.work, const Color(0xFF0A66C2), socialLinks!.linkedinUrl!),
          if (socialLinks!.x != null)
            _buildCompactIcon(Icons.alternate_email, AppColors.textPrimary, socialLinks!.xUrl!),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (socialLinks!.facebook != null)
          _buildSocialIcon(Icons.facebook, const Color(0xFF1877F2), socialLinks!.facebookUrl!),
        if (socialLinks!.instagram != null)
          _buildSocialIcon(Icons.camera_alt, const Color(0xFFE4405F), socialLinks!.instagramUrl!),
        if (socialLinks!.tiktok != null)
          _buildSocialIcon(Icons.music_note, AppColors.textPrimary, socialLinks!.tiktokUrl!),
        if (socialLinks!.linkedin != null)
          _buildSocialIcon(Icons.work, const Color(0xFF0A66C2), socialLinks!.linkedinUrl!),
        if (socialLinks!.x != null)
          _buildSocialIcon(Icons.alternate_email, AppColors.textPrimary, socialLinks!.xUrl!),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => _launchUrl(url),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildCompactIcon(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
