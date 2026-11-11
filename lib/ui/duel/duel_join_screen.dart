import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel.dart';
import '../../providers/duel_provider.dart';
import '../../utils/invitation_link.dart';
import 'duel_errors.dart';
import 'duel_join_confirm_screen.dart';
import 'duel_widgets.dart';

/// Typing a code to join. Pops with the new [Opponent] once accepted.
class DuelJoinScreen extends StatefulWidget {
  final String? initialCode;
  final String? initialError;

  const DuelJoinScreen({super.key, this.initialCode, this.initialError});

  @override
  State<DuelJoinScreen> createState() => _DuelJoinScreenState();
}

class _DuelJoinScreenState extends State<DuelJoinScreen> {
  late final TextEditingController _controller;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode ?? '');
    _error = widget.initialError;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _complete => isCompleteInvitationCode(_controller.text);

  Future<void> _continue() async {
    final l = AppLocalizations.of(context)!;
    final code = normalizeInvitationCode(_controller.text);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await context
          .read<DuelProvider>()
          .service
          .previewInvitation(code);
      if (!mounted) return;
      setState(() => _loading = false);
      final opponent = await Navigator.of(context).push<Opponent>(
        MaterialPageRoute(
          builder: (_) => DuelJoinConfirmScreen(code: code, preview: preview),
        ),
      );
      if (opponent != null && mounted) {
        Navigator.of(context).pop(opponent);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = duelErrorMessage(l, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DuelScaffold(
      title: l.duelJoinTitle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DuelCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('join-code-field'),
                  controller: _controller,
                  enabled: !_loading,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 -]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                  decoration: InputDecoration(
                    labelText: l.duelJoinCodeLabel,
                    helperText: l.duelJoinCodeHelp,
                    errorText: _error,
                    errorMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    if (_complete && !_loading) _continue();
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _complete && !_loading ? _continue : null,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.duelContinue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
