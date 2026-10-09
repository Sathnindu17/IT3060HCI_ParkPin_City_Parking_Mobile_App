import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/driver_profile_service.dart';
import '../widgets/parking_ui.dart';

class ProfilePrivacyScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onLoggedOut;
  final VoidCallback? onOpenVehicles;
  final VoidCallback? onOpenPaymentMethods;

  const ProfilePrivacyScreen({
    super.key,
    this.onNavigate,
    this.onLoggedOut,
    this.onOpenVehicles,
    this.onOpenPaymentMethods,
  });

  @override
  State<ProfilePrivacyScreen> createState() => _ProfilePrivacyScreenState();
}

class _ProfilePrivacyScreenState extends State<ProfilePrivacyScreen> {
  late final DriverProfileService _service;
  StreamSubscription<AuthState>? _authSubscription;

  DriverAccount? _account;
  String? _error;
  String? _userId;

  bool _loading = true;
  bool _busy = false;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();

    _service = DriverProfileService();
    _userId = Supabase.instance.client.auth.currentUser?.id;

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) {
      final nextUserId = event.session?.user.id;

      if (!mounted || nextUserId == _userId) return;

      _userId = nextUserId;
      _load();
    });

    _load();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String _errorMessage(Object error) {
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;
    if (error is StateError) return error.message.toString();

    return 'Could not complete this action. Please try again.';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _load() async {
    if (!mounted) return;

    final version = ++_loadVersion;

    setState(() {
      _loading = true;
      _error = null;
      _account = null;
    });

    try {
      final account = await _service.load();

      if (!mounted || version != _loadVersion) return;

      setState(() => _account = account);
    } catch (error) {
      if (!mounted || version != _loadVersion) return;

      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted && version == _loadVersion) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _save(Future<void> Function() action) async {
    if (_busy || !mounted) return false;

    setState(() => _busy = true);

    try {
      await action();

      if (!mounted) return false;

      await _load();
      return true;
    } catch (error) {
      _showMessage(_errorMessage(error));
      return false;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _editProfile() async {
    final account = _account;
    if (account == null || _busy) return;

    final nameController = TextEditingController(
      text: account.profile.fullName,
    );

    final phoneController = TextEditingController(text: account.profile.phone);

    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Edit profile'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your name.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'Phone number (optional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        final phone = value?.trim() ?? '';

                        if (phone.isNotEmpty &&
                            !RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(phone)) {
                          return 'Enter a valid phone number.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  Navigator.pop(dialogContext, {
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                  });
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (result == null || !mounted) return;

      final success = await _save(() {
        return _service.updateProfile(
          fullName: result['name']!,
          phone: result['phone']!,
        );
      });

      if (success) {
        _showMessage('Profile saved.');
      }
    } finally {
      nameController.dispose();
      phoneController.dispose();
    }
  }

  Future<void> _openPreferences({required bool location}) async {
    final account = _account;
    if (account == null || _busy) return;

    final preferences = account.preferences;

    var draft = location
        ? preferences.locationEnabled
        : preferences.bookingUpdates;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                location ? 'Location preference' : 'Notification settings',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        location ? 'Nearby parking' : 'Booking updates',
                      ),
                      subtitle: Text(
                        location
                            ? 'Allow the map to use your location'
                            : 'Parking starts, extensions and completion',
                      ),
                      value: draft,
                      onChanged: (value) {
                        setDialogState(() => draft = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      location
                          ? 'Your browser or phone may ask separately for '
                                'location permission when you use the map.'
                          : 'Turning this off stops new booking messages. '
                                'Existing messages remain available. '
                                'Scheduled reminders and offers are not enabled.',
                      style: const TextStyle(
                        color: ParkingStyle.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, draft);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    final updated = DriverPreferences(
      locationEnabled: location ? result : preferences.locationEnabled,
      bookingUpdates: location ? preferences.bookingUpdates : result,
    );

    final success = await _save(() {
      return _service.savePreferences(updated);
    });

    if (success) {
      _showMessage('Preference saved.');
    }
  }

  Future<void> _changePassword() async {
    if (_busy) return;

    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final password = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Change password'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Use at least 8 characters.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                      ),
                      validator: (value) {
                        if (value != passwordController.text) {
                          return 'Passwords do not match.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  Navigator.pop(dialogContext, passwordController.text);
                },
                child: const Text('Update password'),
              ),
            ],
          );
        },
      );

      if (password == null || !mounted) return;

      final success = await _save(() {
        return _service.changePassword(password);
      });

      if (success) {
        _showMessage('Password updated.');
      }
    } finally {
      passwordController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> _confirmLogout() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'You will need to sign in again to access your driver account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Log out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted || _busy) return;

    setState(() => _busy = true);

    try {
      await _service.signOut();

      if (!mounted) return;

      final callback = widget.onLoggedOut;

      if (callback != null) {
        callback();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _account = null;
          _error = 'You have signed out. Please sign in again.';
        });
      }
    } catch (error) {
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _navigate(int index) {
    if (index == 3 || _busy) return;

    final callback = widget.onNavigate;

    if (callback != null) {
      callback(index);
    } else {
      _showMessage('This navigation will be connected during app integration.');
    }
  }

  Widget _profileHeader(DriverProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ParkingStyle.navy, Color(0xFF31598E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white.withAlpha(24),
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withAlpha(215), fontSize: 13),
          ),
          if (profile.phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              profile.phone,
              style: TextStyle(color: Colors.white.withAlpha(215)),
            ),
          ],
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_outlined,
                color: ParkingStyle.orange,
                size: 18,
              ),
              SizedBox(width: 7),
              Text('Driver account', style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? const Color(0xFFC54141) : ParkingStyle.navy;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        enabled: !_busy,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: destructive
                ? const Color(0xFFFFEEEE)
                : const Color(0xFFEEF3FA),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: ParkingStyle.muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: color),
        onTap: _busy ? null : onTap,
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: Color(0xFFE8EDF5),
    );
  }

  Widget _content(DriverAccount account) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _profileHeader(account.profile),
          const SizedBox(height: 24),
          const Text(
            'Account & preferences',
            style: TextStyle(
              color: ParkingStyle.navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (_busy) ...[
            const LinearProgressIndicator(color: ParkingStyle.orange),
            const SizedBox(height: 12),
          ],
          ParkingCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  _menuItem(
                    icon: Icons.edit_outlined,
                    title: 'Edit profile',
                    subtitle: 'Update your name and phone number',
                    onTap: _editProfile,
                  ),
                  _divider(),
                  _menuItem(
                    icon: Icons.directions_car_outlined,
                    title: 'My vehicles',
                    subtitle: 'Manage your parking vehicles',
                    onTap:
                        widget.onOpenVehicles ??
                        () {
                          _showMessage(
                            'Vehicle management will be connected '
                            'during app integration.',
                          );
                        },
                  ),
                  _divider(),
                  _menuItem(
                    icon: Icons.credit_card_outlined,
                    title: 'Payment methods',
                    subtitle: 'Manage your payment preferences',
                    onTap:
                        widget.onOpenPaymentMethods ??
                        () {
                          _showMessage(
                            'Payment methods will be connected '
                            'during app integration.',
                          );
                        },
                  ),
                  _divider(),
                  _menuItem(
                    icon: Icons.shield_outlined,
                    title: 'Privacy & security',
                    subtitle: 'Change your account password',
                    onTap: _changePassword,
                  ),
                  _divider(),
                  _menuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Location preference',
                    subtitle: account.preferences.locationEnabled
                        ? 'Nearby parking preference enabled'
                        : 'Nearby parking preference disabled',
                    onTap: () {
                      _openPreferences(location: true);
                    },
                  ),
                  _divider(),
                  _menuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notification settings',
                    subtitle: account.preferences.bookingUpdates
                        ? 'Booking updates enabled'
                        : 'Booking updates disabled',
                    onTap: () {
                      _openPreferences(location: false);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          ParkingCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _menuItem(
                icon: Icons.logout_rounded,
                title: 'Log out',
                subtitle: 'Leave your driver account',
                destructive: true,
                onTap: _confirmLogout,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_loading) {
      body = const Center(
        child: CircularProgressIndicator(color: ParkingStyle.orange),
      );
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ParkingCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 44,
                  color: ParkingStyle.muted,
                ),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(onPressed: _load, child: const Text('Refresh')),
              ],
            ),
          ),
        ),
      );
    } else {
      body = _content(_account!);
    }

    return Scaffold(
      backgroundColor: ParkingStyle.background,
      appBar: AppBar(
        backgroundColor: ParkingStyle.navy,
        foregroundColor: Colors.white,
        toolbarHeight: 72,
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _busy || _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: _navigate,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: ParkingStyle.navy,
        unselectedItemColor: ParkingStyle.muted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Receipts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
