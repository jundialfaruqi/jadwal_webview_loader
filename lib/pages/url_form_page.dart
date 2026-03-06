import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/url_checker.dart';
import 'webview_page.dart';

class UrlFormPage extends StatefulWidget {
  const UrlFormPage({super.key});

  @override
  State<UrlFormPage> createState() => _UrlFormPageState();
}

class _UrlFormPageState extends State<UrlFormPage> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;
  String? _savedUrl;
  String? _lastUrl;

  @override
  void initState() {
    super.initState();
    _openSavedIfAny();
  }

  Future<void> _openSavedIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefKeySavedUrl);
    final last = prefs.getString(prefKeyLastSavedUrl);
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _savedUrl = saved;
      });
    }
    if (last != null && last.isNotEmpty) {
      setState(() {
        _lastUrl = last;
        _controller.text = '';
      });
    }
  }

  String _composeUrl(String input) {
    final trimmed = input.trim().replaceAll(RegExp(r'^/+'), '');
    return '$baseUrl$trimmed';
  }

  Future<void> _onSave() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });
    final full = _composeUrl(_controller.text);
    final ok = await isValidUrl(full);
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeySavedUrl, full);
      await prefs.remove(prefKeyLastSavedUrl);
      setState(() {
        _savedUrl = full;
        _lastUrl = null;
      });
    } else {
      Fluttertoast.showToast(msg: 'URL masjid tidak valid');
    }
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _onClearUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefKeySavedUrl);
    final last = prefs.getString(prefKeyLastSavedUrl);
    setState(() {
      _savedUrl = null;
      _lastUrl = last;
    });
  }

  Future<void> _onCancel() async {
    if (_submitting) return;
    if (_lastUrl != null && _lastUrl!.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeySavedUrl, _lastUrl!);
      await prefs.remove(prefKeyLastSavedUrl);
      setState(() {
        _savedUrl = _lastUrl;
        _lastUrl = null;
      });
    } else {
      setState(() {
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_savedUrl != null) {
      return WebViewPage(url: _savedUrl!, onChangeUrl: _onClearUrl);
    }
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 2,
              color: cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masukkan alamat masjid',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contoh: masjid-annur',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'Slug Masjid',
                        prefixText: baseUrl,
                        prefixStyle: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        hintText: 'masjid-annur',
                        filled: true,
                        fillColor: cs.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                        helperText:
                            'Masukkan slug tanpa https, hanya bagian setelah domain.',
                        helperStyle: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting ? null : _onCancel,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _onSave,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(opacity: anim, child: child),
                              child: _submitting
                                  ? Row(
                                      key: const ValueKey('loading'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 18,
                                          width: 18,
                                          child:
                                              const CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Menyimpan...'),
                                      ],
                                    )
                                  : const Text(
                                      'Simpan',
                                      key: ValueKey('save'),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
