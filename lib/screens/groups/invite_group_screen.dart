import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';

class InviteGroupScreen extends StatefulWidget {
  final String groupId;
  final String code;

  const InviteGroupScreen({
    super.key,
    required this.groupId,
    required this.code,
  });

  @override
  State<InviteGroupScreen> createState() => _InviteGroupScreenState();
}

class _InviteGroupScreenState extends State<InviteGroupScreen> {
  bool _isLoading = true;
  bool _isJoining = false;
  GroupModel? _group;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      final group = await GroupService.getGroupByInvite(
        groupId: widget.groupId,
        code: widget.code,
      );

      if (!mounted) return;
      setState(() {
        _group = group;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _join() async {
    final group = _group;
    if (group == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isJoining = true;
    });

    try {
      await GroupService.joinPrivateGroupByLink(group.inviteLink);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsJoinSuccess)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.groupsInviteTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    final group = _group!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupsInviteTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.groups_rounded,
                size: 42,
                color: AppColors.primary,
              ),
              const SizedBox(height: 14),
              Text(
                group.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                group.description.isEmpty
                    ? l10n.groupsPrivateBadge
                    : group.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _InfoPill(text: group.collegeName),
                  _InfoPill(text: group.specializationName),
                  _InfoPill(text: l10n.groupsPrivateBadge),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isJoining ? null : _join,
                  icon: _isJoining
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.login_rounded),
                  label: Text(_isJoining ? l10n.groupsInviteJoiningLoading : l10n.groupsJoinAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;

  const _InfoPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.isEmpty ? l10n.groupsInviteNotSpecified : text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}