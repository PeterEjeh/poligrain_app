import 'package:flutter/material.dart';
import '../../models/user_preferences.dart';
import '../../services/user_preferences_service.dart';

/// Screen for managing user preferences
class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final UserPreferencesService _preferencesService = UserPreferencesService();
  UserPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final preferences = await _preferencesService.getUserPreferences();
      setState(() {
        _preferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreferences(UserPreferences updatedPreferences) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await _preferencesService.updateUserPreferences(
        updatedPreferences,
      );
      setState(() {
        _preferences = updated;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorWidget()
              : _preferences != null
              ? _buildPreferencesContent()
              : const Center(child: Text('No preferences found')),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load preferences',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPreferences,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesContent() {
    final preferences = _preferences!;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGeneralSection(preferences),
              const SizedBox(height: 24),
              _buildNotificationSection(preferences),
              const SizedBox(height: 24),
              _buildInvestmentSection(preferences),
              const SizedBox(height: 24),
              _buildTrackingSection(preferences),
              const SizedBox(height: 24),
              _buildSecuritySection(preferences),
              const SizedBox(height: 24),
              _buildPrivacySection(preferences),
              const SizedBox(height: 100), // Extra space for floating button
            ],
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Saving preferences...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGeneralSection(UserPreferences preferences) {
    return _buildSection('General', Icons.settings, [
      _buildDropdownTile<ThemePreference>(
        'Theme',
        preferences.theme,
        ThemePreference.values,
        (value) => value.value,
        (value) => _updatePreferences(preferences.copyWith(theme: value)),
      ),
      _buildDropdownTile<LanguagePreference>(
        'Language',
        preferences.language,
        LanguagePreference.values,
        (value) => value.value,
        (value) => _updatePreferences(preferences.copyWith(language: value)),
      ),
      _buildDropdownTile<CurrencyPreference>(
        'Currency',
        preferences.currency,
        CurrencyPreference.values,
        (value) => value.value,
        (value) => _updatePreferences(preferences.copyWith(currency: value)),
      ),
    ]);
  }

  Widget _buildNotificationSection(UserPreferences preferences) {
    return _buildSection('Notifications', Icons.notifications, [
      _buildDropdownTile<NotificationPreference>(
        'Notification Level',
        preferences.notifications,
        NotificationPreference.values,
        (value) => value.value,
        (value) =>
            _updatePreferences(preferences.copyWith(notifications: value)),
      ),
      const Divider(),
      Text(
        'Milestone Notifications',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
      const SizedBox(height: 8),
      _buildSwitchTile(
        'Campaign Started',
        preferences.milestoneNotifications.campaignStarted,
        (value) => _updatePreferences(
          preferences.copyWith(
            milestoneNotifications: preferences.milestoneNotifications.copyWith(
              campaignStarted: value,
            ),
          ),
        ),
      ),
      _buildSwitchTile(
        'Milestone Completed',
        preferences.milestoneNotifications.milestoneCompleted,
        (value) => _updatePreferences(
          preferences.copyWith(
            milestoneNotifications: preferences.milestoneNotifications.copyWith(
              milestoneCompleted: value,
            ),
          ),
        ),
      ),
      _buildSwitchTile(
        'Milestone Overdue',
        preferences.milestoneNotifications.milestoneOverdue,
        (value) => _updatePreferences(
          preferences.copyWith(
            milestoneNotifications: preferences.milestoneNotifications.copyWith(
              milestoneOverdue: value,
            ),
          ),
        ),
      ),
      _buildSwitchTile(
        'Payout Received',
        preferences.milestoneNotifications.payoutReceived,
        (value) => _updatePreferences(
          preferences.copyWith(
            milestoneNotifications: preferences.milestoneNotifications.copyWith(
              payoutReceived: value,
            ),
          ),
        ),
      ),
      _buildSwitchTile(
        'Risk Alerts',
        preferences.milestoneNotifications.riskAlerts,
        (value) => _updatePreferences(
          preferences.copyWith(
            milestoneNotifications: preferences.milestoneNotifications.copyWith(
              riskAlerts: value,
            ),
          ),
        ),
      ),
      _buildSliderTile(
        'Reminder Days Before Due',
        preferences.milestoneNotifications.daysBeforeReminder.toDouble(),
        1.0,
        14.0,
        7,
        (value) => _updatePreferences(
          preferences.copyWith(
            milestoneNotifications: preferences.milestoneNotifications.copyWith(
              daysBeforeReminder: value.round(),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildInvestmentSection(UserPreferences preferences) {
    final investmentPrefs = preferences.investmentPreferences;

    return _buildSection('Investment Preferences', Icons.trending_up, [
      _buildDropdownTile<RiskTolerance>(
        'Risk Tolerance',
        investmentPrefs.riskTolerance,
        RiskTolerance.values,
        (value) => value.value,
        (value) => _updatePreferences(
          preferences.copyWith(
            investmentPreferences: investmentPrefs.copyWith(
              riskTolerance: value,
            ),
          ),
        ),
      ),
      _buildDropdownTile<InvestmentFocus>(
        'Primary Focus',
        investmentPrefs.primaryFocus,
        InvestmentFocus.values,
        (value) => value.value,
        (value) => _updatePreferences(
          preferences.copyWith(
            investmentPreferences: investmentPrefs.copyWith(
              primaryFocus: value,
            ),
          ),
        ),
      ),
      _buildTextFieldTile(
        'Minimum Investment Amount',
        investmentPrefs.minInvestmentAmount.toString(),
        TextInputType.number,
        (value) {
          final amount = double.tryParse(value);
          if (amount != null) {
            _updatePreferences(
              preferences.copyWith(
                investmentPreferences: investmentPrefs.copyWith(
                  minInvestmentAmount: amount,
                ),
              ),
            );
          }
        },
      ),
      _buildTextFieldTile(
        'Maximum Investment Amount',
        investmentPrefs.maxInvestmentAmount == double.infinity
            ? ''
            : investmentPrefs.maxInvestmentAmount.toString(),
        TextInputType.number,
        (value) {
          final amount =
              value.isEmpty ? double.infinity : double.tryParse(value);
          if (amount != null) {
            _updatePreferences(
              preferences.copyWith(
                investmentPreferences: investmentPrefs.copyWith(
                  maxInvestmentAmount: amount,
                ),
              ),
            );
          }
        },
      ),
      _buildSliderTile(
        'Minimum Expected ROI (%)',
        investmentPrefs.minExpectedROI,
        0.0,
        50.0,
        10,
        (value) => _updatePreferences(
          preferences.copyWith(
            investmentPreferences: investmentPrefs.copyWith(
              minExpectedROI: value,
            ),
          ),
        ),
      ),
      _buildSwitchTile(
        'Auto-Invest Enabled',
        investmentPrefs.autoInvestEnabled,
        (value) => _updatePreferences(
          preferences.copyWith(
            investmentPreferences: investmentPrefs.copyWith(
              autoInvestEnabled: value,
            ),
          ),
        ),
      ),
      if (investmentPrefs.autoInvestEnabled)
        _buildTextFieldTile(
          'Auto-Invest Amount',
          investmentPrefs.autoInvestAmount.toString(),
          TextInputType.number,
          (value) {
            final amount = double.tryParse(value);
            if (amount != null) {
              _updatePreferences(
                preferences.copyWith(
                  investmentPreferences: investmentPrefs.copyWith(
                    autoInvestAmount: amount,
                  ),
                ),
              );
            }
          },
        ),
    ]);
  }

  Widget _buildTrackingSection(UserPreferences preferences) {
    final trackingPrefs = preferences.trackingPreferences;

    return _buildSection('Tracking & Reports', Icons.analytics, [
      _buildSwitchTile(
        'Track Milestones',
        trackingPrefs.trackMilestones,
        (value) => _updatePreferences(
          preferences.copyWith(
            trackingPreferences: trackingPrefs.copyWith(trackMilestones: value),
          ),
        ),
      ),
      _buildSwitchTile(
        'Track ROI',
        trackingPrefs.trackROI,
        (value) => _updatePreferences(
          preferences.copyWith(
            trackingPreferences: trackingPrefs.copyWith(trackROI: value),
          ),
        ),
      ),
      _buildSwitchTile(
        'Track Risk Changes',
        trackingPrefs.trackRiskChanges,
        (value) => _updatePreferences(
          preferences.copyWith(
            trackingPreferences: trackingPrefs.copyWith(
              trackRiskChanges: value,
            ),
          ),
        ),
      ),
      const Divider(),
      Text(
        'Reports',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
      const SizedBox(height: 8),
      _buildSwitchTile(
        'Weekly Reports',
        trackingPrefs.receiveWeeklyReports,
        (value) => _updatePreferences(
          preferences.copyWith(
            trackingPreferences: trackingPrefs.copyWith(
              receiveWeeklyReports: value,
            ),
          ),
        ),
      ),
      _buildSwitchTile(
        'Monthly Reports',
        trackingPrefs.receiveMonthlyReports,
        (value) => _updatePreferences(
          preferences.copyWith(
            trackingPreferences: trackingPrefs.copyWith(
              receiveMonthlyReports: value,
            ),
          ),
        ),
      ),
      const Divider(),
      Text(
        'Notification Channels',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
      const SizedBox(height: 8),
      _buildSwitchTile(
        'Push Notifications',
        trackingPrefs.enablePushNotifications,
        (value) => _updatePreferences(
          preferences.copyWith(
            trackingPreferences: trackingPrefs.copyWith(
              enablePushNotifications: value,
            ),
          ),
        ),
      ),
      _buildSwitchTile(
        'Email Notifications',
        trackingPrefs.enableEmailNotifications,
        (value) => _updatePreferences(
          preferences.copyWith(
            trackingPreferences: trackingPrefs.copyWith(
              enableEmailNotifications: value,
            ),
          ),
        ),
      ),
      _buildSwitchTile(
        'SMS Notifications',
        trackingPrefs.enableSMSNotifications,
        (value) => _updatePreferences(
          preferences.copyWith(
            trackingPreferences: trackingPrefs.copyWith(
              enableSMSNotifications: value,
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildSecuritySection(UserPreferences preferences) {
    return _buildSection('Security', Icons.security, [
      _buildSwitchTile(
        'Biometric Authentication',
        preferences.enableBiometricAuth,
        (value) => _updatePreferences(
          preferences.copyWith(enableBiometricAuth: value),
        ),
      ),
      _buildSwitchTile(
        'Two-Factor Authentication',
        preferences.enableTwoFactorAuth,
        (value) => _updatePreferences(
          preferences.copyWith(enableTwoFactorAuth: value),
        ),
      ),
    ]);
  }

  Widget _buildPrivacySection(UserPreferences preferences) {
    return _buildSection('Privacy', Icons.privacy_tip, [
      _buildSwitchTile(
        'Share Analytics Data',
        preferences.shareAnalytics,
        (value) =>
            _updatePreferences(preferences.copyWith(shareAnalytics: value)),
      ),
      _buildSwitchTile(
        'Receive Marketing Emails',
        preferences.receiveMarketingEmails,
        (value) => _updatePreferences(
          preferences.copyWith(receiveMarketingEmails: value),
        ),
      ),
    ]);
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile<T>(
    String title,
    T currentValue,
    List<T> options,
    String Function(T) getDisplayText,
    void Function(T) onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: DropdownButton<T>(
        value: currentValue,
        items:
            options.map((option) {
              return DropdownMenuItem<T>(
                value: option,
                child: Text(getDisplayText(option)),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    void Function(bool) onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    double min,
    double max,
    int divisions,
    void Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextFieldTile(
    String title,
    String value,
    TextInputType keyboardType,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        onFieldSubmitted: onChanged,
      ),
    );
  }
}
