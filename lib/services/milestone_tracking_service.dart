import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/campaign_milestone.dart';
import '../models/campaign_enum.dart';
import '../services/user_preferences_service.dart';

/// Service for managing campaign milestones and tracking
class MilestoneTrackingService {
  static const String _apiName = 'PoligrainAPI';
  final UserPreferencesService _preferencesService = UserPreferencesService();

  /// Get all milestones for a campaign
  Future<List<CampaignMilestone>> getCampaignMilestones(
    String campaignId,
  ) async {
    try {
      final response =
          await Amplify.API
              .get('/campaigns/$campaignId/milestones', apiName: _apiName)
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to fetch milestones: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      final milestones =
          (responseData['milestones'] as List<dynamic>)
              .map(
                (milestoneData) => CampaignMilestone.fromJson(
                  milestoneData as Map<String, dynamic>,
                ),
              )
              .toList();

      return milestones;
    } catch (e) {
      throw Exception('Failed to fetch campaign milestones: $e');
    }
  }

  /// Get milestone by ID
  Future<CampaignMilestone> getMilestone(String milestoneId) async {
    try {
      final response =
          await Amplify.API
              .get('/milestones/$milestoneId', apiName: _apiName)
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw Exception('Milestone not found: $milestoneId');
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to fetch milestone: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final milestoneData = json.decode(responseBody) as Map<String, dynamic>;
      return CampaignMilestone.fromJson(milestoneData);
    } catch (e) {
      throw Exception('Failed to fetch milestone: $e');
    }
  }

  /// Create a new milestone
  Future<CampaignMilestone> createMilestone({
    required String campaignId,
    required String title,
    required String description,
    required MilestoneType type,
    required DateTime targetDate,
    double? targetAmount,
    String? notes,
    List<String> imageUrls = const [],
    List<String> documentUrls = const [],
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestBody = {
        'campaignId': campaignId,
        'title': title,
        'description': description,
        'type': type.value,
        'targetDate': targetDate.toIso8601String(),
        if (targetAmount != null) 'targetAmount': targetAmount,
        if (notes != null) 'notes': notes,
        'imageUrls': imageUrls,
        'documentUrls': documentUrls,
        if (metadata != null) 'metadata': metadata,
      };

      final response =
          await Amplify.API
              .post(
                '/campaigns/$campaignId/milestones',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to create milestone: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final milestoneData = json.decode(responseBody) as Map<String, dynamic>;
      return CampaignMilestone.fromJson(milestoneData);
    } catch (e) {
      throw Exception('Failed to create milestone: $e');
    }
  }

  /// Update milestone status and progress
  Future<CampaignMilestone> updateMilestone({
    required String milestoneId,
    MilestoneStatus? status,
    double? currentAmount,
    DateTime? completedDate,
    String? notes,
    List<String>? imageUrls,
    List<String>? documentUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        if (status != null) 'status': status.value,
        if (currentAmount != null) 'currentAmount': currentAmount,
        if (completedDate != null)
          'completedDate': completedDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (imageUrls != null) 'imageUrls': imageUrls,
        if (documentUrls != null) 'documentUrls': documentUrls,
        if (metadata != null) 'metadata': metadata,
      };

      final response =
          await Amplify.API
              .put(
                '/milestones/$milestoneId',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw Exception('Milestone not found: $milestoneId');
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to update milestone: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final milestoneData = json.decode(responseBody) as Map<String, dynamic>;
      final updatedMilestone = CampaignMilestone.fromJson(milestoneData);

      // Send notifications if status changed to completed
      if (status == MilestoneStatus.completed) {
        await _sendMilestoneCompletedNotifications(updatedMilestone);
      }

      return updatedMilestone;
    } catch (e) {
      throw Exception('Failed to update milestone: $e');
    }
  }

  /// Mark milestone as completed
  Future<CampaignMilestone> completeMilestone(
    String milestoneId, {
    String? notes,
    List<String>? imageUrls,
    List<String>? documentUrls,
  }) async {
    return await updateMilestone(
      milestoneId: milestoneId,
      status: MilestoneStatus.completed,
      completedDate: DateTime.now(),
      notes: notes,
      imageUrls: imageUrls,
      documentUrls: documentUrls,
    );
  }

  /// Get milestones by status
  Future<List<CampaignMilestone>> getMilestonesByStatus(
    String campaignId,
    MilestoneStatus status,
  ) async {
    final allMilestones = await getCampaignMilestones(campaignId);
    return allMilestones.where((m) => m.status == status).toList();
  }

  /// Get overdue milestones for a campaign
  Future<List<CampaignMilestone>> getOverdueMilestones(
    String campaignId,
  ) async {
    final allMilestones = await getCampaignMilestones(campaignId);
    return allMilestones.where((m) => m.isOverdue).toList();
  }

  /// Get upcoming milestones (due in next N days)
  Future<List<CampaignMilestone>> getUpcomingMilestones(
    String campaignId, {
    int daysAhead = 7,
  }) async {
    final allMilestones = await getCampaignMilestones(campaignId);
    final cutoffDate = DateTime.now().add(Duration(days: daysAhead));

    return allMilestones
        .where((m) => !m.isCompleted && m.targetDate.isBefore(cutoffDate))
        .toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }

  /// Get user's tracked milestones across all investments
  Future<List<CampaignMilestone>> getUserTrackedMilestones() async {
    try {
      final response =
          await Amplify.API.get('/user/milestones', apiName: _apiName).response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to fetch user milestones: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      final milestones =
          (responseData['milestones'] as List<dynamic>)
              .map(
                (milestoneData) => CampaignMilestone.fromJson(
                  milestoneData as Map<String, dynamic>,
                ),
              )
              .toList();

      return milestones;
    } catch (e) {
      throw Exception('Failed to fetch user tracked milestones: $e');
    }
  }

  /// Get milestone analytics for a campaign
  Future<Map<String, dynamic>> getMilestoneAnalytics(String campaignId) async {
    try {
      final milestones = await getCampaignMilestones(campaignId);

      final total = milestones.length;
      final completed = milestones.where((m) => m.isCompleted).length;
      final overdue = milestones.where((m) => m.isOverdue).length;
      final pending =
          milestones.where((m) => m.status == MilestoneStatus.pending).length;
      final inProgress =
          milestones
              .where((m) => m.status == MilestoneStatus.inProgress)
              .length;

      final completionRate = total > 0 ? (completed / total) * 100 : 0.0;
      final overdueRate = total > 0 ? (overdue / total) * 100 : 0.0;

      // Calculate average completion time
      final completedMilestones = milestones.where(
        (m) => m.isCompleted && m.completedDate != null,
      );
      double avgCompletionDays = 0.0;

      if (completedMilestones.isNotEmpty) {
        final totalDays = completedMilestones.fold<int>(0, (sum, m) {
          final createdDate = m.createdAt;
          final completedDate = m.completedDate!;
          return sum + completedDate.difference(createdDate).inDays;
        });
        avgCompletionDays = totalDays / completedMilestones.length;
      }

      return {
        'total': total,
        'completed': completed,
        'overdue': overdue,
        'pending': pending,
        'inProgress': inProgress,
        'completionRate': completionRate,
        'overdueRate': overdueRate,
        'averageCompletionDays': avgCompletionDays,
        'milestonesByType': _groupMilestonesByType(milestones),
        'upcomingMilestones': await getUpcomingMilestones(campaignId),
      };
    } catch (e) {
      throw Exception('Failed to get milestone analytics: $e');
    }
  }

  /// Get milestone notifications that should be sent
  Future<List<Map<String, dynamic>>> getPendingMilestoneNotifications() async {
    try {
      final userPrefs = await _preferencesService.getUserPreferences();
      if (!userPrefs.shouldReceiveMilestoneNotifications()) {
        return [];
      }

      final trackedMilestones = await getUserTrackedMilestones();
      final notifications = <Map<String, dynamic>>[];

      for (final milestone in trackedMilestones) {
        // Check for overdue milestones
        if (milestone.isOverdue &&
            userPrefs.milestoneNotifications.milestoneOverdue) {
          notifications.add({
            'type': 'milestone_overdue',
            'milestoneId': milestone.id,
            'campaignId': milestone.campaignId,
            'title': 'Milestone Overdue',
            'message':
                '${milestone.title} is ${milestone.daysOverdue} days overdue',
            'priority': 'high',
            'channels': userPrefs.getEnabledNotificationChannels(),
          });
        }

        // Check for upcoming milestone reminders
        final daysUntilTarget = milestone.daysUntilTarget;
        if (daysUntilTarget <=
                userPrefs.milestoneNotifications.daysBeforeReminder &&
            daysUntilTarget > 0 &&
            !milestone.isCompleted) {
          notifications.add({
            'type': 'milestone_reminder',
            'milestoneId': milestone.id,
            'campaignId': milestone.campaignId,
            'title': 'Upcoming Milestone',
            'message': '${milestone.title} is due in $daysUntilTarget days',
            'priority': 'medium',
            'channels': userPrefs.getEnabledNotificationChannels(),
          });
        }
      }

      return notifications;
    } catch (e) {
      throw Exception('Failed to get pending milestone notifications: $e');
    }
  }

  /// Send milestone completion notifications
  Future<void> _sendMilestoneCompletedNotifications(
    CampaignMilestone milestone,
  ) async {
    try {
      final userPrefs = await _preferencesService.getUserPreferences();

      if (!userPrefs.shouldReceiveMilestoneNotifications() ||
          !userPrefs.milestoneNotifications.milestoneCompleted) {
        return;
      }

      final notificationPayload = {
        'type': 'milestone_completed',
        'milestoneId': milestone.id,
        'campaignId': milestone.campaignId,
        'title': 'Milestone Completed',
        'message': '${milestone.title} has been completed successfully',
        'priority': 'medium',
        'channels': userPrefs.getEnabledNotificationChannels(),
        'metadata': {
          'milestoneType': milestone.type.value,
          'completedDate': milestone.completedDate?.toIso8601String(),
        },
      };

      await Amplify.API
          .post(
            '/notifications/send',
            apiName: _apiName,
            body: HttpPayload.json(notificationPayload),
          )
          .response;
    } catch (e) {
      // Log error but don't throw - notification failures shouldn't break milestone updates
      print('Failed to send milestone completion notification: $e');
    }
  }

  /// Create default milestones for a new campaign
  Future<List<CampaignMilestone>> createDefaultMilestones({
    required String campaignId,
    required DateTime campaignStartDate,
    required DateTime campaignEndDate,
    required CampaignType campaignType,
    required double targetAmount,
  }) async {
    try {
      final milestones = <Map<String, dynamic>>[];
      final campaignDuration =
          campaignEndDate.difference(campaignStartDate).inDays;

      // Funding milestone (always first)
      milestones.add({
        'title': 'Funding Target Achieved',
        'description': 'Campaign has reached its funding target',
        'type': MilestoneType.funding.value,
        'targetDate': campaignStartDate.add(
          Duration(days: (campaignDuration * 0.3).round()),
        ),
        'targetAmount': targetAmount,
      });

      // Type-specific milestones
      switch (campaignType) {
        case CampaignType.loan:
          milestones.addAll([
            {
              'title': 'Preparation Phase',
              'description': 'Land preparation and seed procurement',
              'type': MilestoneType.preparation.value,
              'targetDate': campaignStartDate.add(
                Duration(days: (campaignDuration * 0.4).round()),
              ),
            },
            {
              'title': 'Planting Complete',
              'description': 'All seeds/crops have been planted',
              'type': MilestoneType.planting.value,
              'targetDate': campaignStartDate.add(
                Duration(days: (campaignDuration * 0.5).round()),
              ),
            },
            {
              'title': 'Growth Phase Update',
              'description': 'Crops are growing well and on schedule',
              'type': MilestoneType.growth.value,
              'targetDate': campaignStartDate.add(
                Duration(days: (campaignDuration * 0.7).round()),
              ),
            },
            {
              'title': 'Harvest Complete',
              'description': 'All crops have been harvested',
              'type': MilestoneType.harvest.value,
              'targetDate': campaignStartDate.add(
                Duration(days: (campaignDuration * 0.9).round()),
              ),
            },
            {
              'title': 'Investor Payout',
              'description': 'Returns have been distributed to investors',
              'type': MilestoneType.payout.value,
              'targetDate': campaignEndDate,
            },
          ]);
          break;

        case CampaignType.investment:
        case CampaignType.crowdfunding:
          milestones.addAll([
            {
              'title': 'Project Kickoff',
              'description': 'Project has officially started',
              'type': MilestoneType.preparation.value,
              'targetDate': campaignStartDate.add(
                Duration(days: (campaignDuration * 0.4).round()),
              ),
            },
            {
              'title': 'Mid-Project Review',
              'description': 'Project progress review and updates',
              'type': MilestoneType.growth.value,
              'targetDate': campaignStartDate.add(
                Duration(days: (campaignDuration * 0.6).round()),
              ),
            },
            {
              'title': 'Project Completion',
              'description': 'Project goals have been achieved',
              'type': MilestoneType.harvest.value,
              'targetDate': campaignStartDate.add(
                Duration(days: (campaignDuration * 0.85).round()),
              ),
            },
            {
              'title': 'Final Distribution',
              'description': 'Final returns/rewards distributed',
              'type': MilestoneType.payout.value,
              'targetDate': campaignEndDate,
            },
          ]);
          break;
      }

      // Create all milestones
      final createdMilestones = <CampaignMilestone>[];
      for (final milestoneData in milestones) {
        final milestone = await createMilestone(
          campaignId: campaignId,
          title: milestoneData['title'] as String,
          description: milestoneData['description'] as String,
          type: MilestoneType.fromString(milestoneData['type'] as String),
          targetDate: milestoneData['targetDate'] as DateTime,
          targetAmount: milestoneData['targetAmount'] as double?,
        );
        createdMilestones.add(milestone);
      }

      return createdMilestones;
    } catch (e) {
      throw Exception('Failed to create default milestones: $e');
    }
  }

  /// Delete milestone
  Future<void> deleteMilestone(String milestoneId) async {
    try {
      final response =
          await Amplify.API
              .delete('/milestones/$milestoneId', apiName: _apiName)
              .response;

      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw Exception('Milestone not found: $milestoneId');
      }

      if (statusCode >= 400) {
        final responseBody = response.decodeBody();
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to delete milestone: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete milestone: $e');
    }
  }

  /// Bulk update milestone statuses
  Future<Map<String, CampaignMilestone>> bulkUpdateMilestones(
    Map<String, MilestoneStatus> milestoneUpdates,
  ) async {
    try {
      final requestBody = {
        'updates':
            milestoneUpdates.entries
                .map(
                  (entry) => {
                    'milestoneId': entry.key,
                    'status': entry.value.value,
                  },
                )
                .toList(),
      };

      final response =
          await Amplify.API
              .post(
                '/milestones/bulk-update',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to bulk update milestones: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      final updatedMilestones = <String, CampaignMilestone>{};

      for (final entry
          in (responseData['milestones'] as Map<String, dynamic>).entries) {
        updatedMilestones[entry.key] = CampaignMilestone.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }

      return updatedMilestones;
    } catch (e) {
      throw Exception('Failed to bulk update milestones: $e');
    }
  }

  /// Get milestone timeline for a campaign
  Future<List<Map<String, dynamic>>> getMilestoneTimeline(
    String campaignId,
  ) async {
    try {
      final milestones = await getCampaignMilestones(campaignId);
      final timeline = <Map<String, dynamic>>[];

      for (final milestone in milestones) {
        timeline.add({
          'id': milestone.id,
          'title': milestone.title,
          'type': milestone.type.value,
          'status': milestone.status.value,
          'targetDate': milestone.targetDate.toIso8601String(),
          'completedDate': milestone.completedDate?.toIso8601String(),
          'isCompleted': milestone.isCompleted,
          'isOverdue': milestone.isOverdue,
          'daysUntilTarget': milestone.daysUntilTarget,
          'progressPercentage': milestone.progressPercentage,
        });
      }

      // Sort by target date
      timeline.sort(
        (a, b) => DateTime.parse(
          a['targetDate'] as String,
        ).compareTo(DateTime.parse(b['targetDate'] as String)),
      );

      return timeline;
    } catch (e) {
      throw Exception('Failed to get milestone timeline: $e');
    }
  }

  /// Helper method to group milestones by type
  Map<String, int> _groupMilestonesByType(List<CampaignMilestone> milestones) {
    final grouped = <String, int>{};
    for (final milestone in milestones) {
      final type = milestone.type.value;
      grouped[type] = (grouped[type] ?? 0) + 1;
    }
    return grouped;
  }

  /// Get milestone performance metrics
  Future<Map<String, dynamic>> getMilestonePerformanceMetrics(
    String campaignId,
  ) async {
    try {
      final milestones = await getCampaignMilestones(campaignId);

      if (milestones.isEmpty) {
        return {
          'onTimeRate': 0.0,
          'averageDelay': 0.0,
          'completionRate': 0.0,
          'performanceScore': 0.0,
        };
      }

      final completedMilestones =
          milestones.where((m) => m.isCompleted).toList();
      final onTimeMilestones =
          completedMilestones
              .where(
                (m) =>
                    m.completedDate != null &&
                    !m.completedDate!.isAfter(m.targetDate),
              )
              .length;

      final onTimeRate =
          completedMilestones.isNotEmpty
              ? (onTimeMilestones / completedMilestones.length) * 100
              : 0.0;

      // Calculate average delay for completed milestones
      double totalDelay = 0.0;
      int delayedMilestones = 0;

      for (final milestone in completedMilestones) {
        if (milestone.completedDate != null &&
            milestone.completedDate!.isAfter(milestone.targetDate)) {
          totalDelay +=
              milestone.completedDate!.difference(milestone.targetDate).inDays;
          delayedMilestones++;
        }
      }

      final averageDelay =
          delayedMilestones > 0 ? totalDelay / delayedMilestones : 0.0;
      final completionRate =
          (completedMilestones.length / milestones.length) * 100;

      // Performance score (0-100, higher is better)
      final performanceScore = ((onTimeRate * 0.4) + (completionRate * 0.6))
          .clamp(0.0, 100.0);

      return {
        'onTimeRate': onTimeRate,
        'averageDelay': averageDelay,
        'completionRate': completionRate,
        'performanceScore': performanceScore,
        'totalMilestones': milestones.length,
        'completedMilestones': completedMilestones.length,
        'onTimeMilestones': onTimeMilestones,
        'delayedMilestones': delayedMilestones,
      };
    } catch (e) {
      throw Exception('Failed to get milestone performance metrics: $e');
    }
  }
}
