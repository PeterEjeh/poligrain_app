import 'package:flutter/material.dart';
import '../models/campaign_milestone.dart';
import '../services/milestone_tracking_service.dart';

/// Widget for displaying campaign milestone tracking
class MilestoneTrackingWidget extends StatefulWidget {
  final String campaignId;
  final bool showAddButton;
  final VoidCallback? onMilestoneAdded;
  final VoidCallback? onMilestoneUpdated;

  const MilestoneTrackingWidget({
    super.key,
    required this.campaignId,
    this.showAddButton = false,
    this.onMilestoneAdded,
    this.onMilestoneUpdated,
  });

  @override
  State<MilestoneTrackingWidget> createState() => _MilestoneTrackingWidgetState();
}

class _MilestoneTrackingWidgetState extends State<MilestoneTrackingWidget> {
  final MilestoneTrackingService _milestoneService = MilestoneTrackingService();
  List<CampaignMilestone> _milestones = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final milestones = await _milestoneService.getCampaignMilestones(widget.campaignId);
      final analytics = await _milestoneService.getMilestoneAnalytics(widget.campaignId);

      setState(() {
        _milestones = milestones;
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load milestones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMilestones,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        if (_analytics != null) _buildAnalytics(),
        const SizedBox(height: 16),
        _buildMilestonesList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Campaign Milestones',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.showAddButton)
          ElevatedButton.icon(
            onPressed: _showAddMilestoneDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Milestone'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildAnalytics() {
    final analytics = _analytics!;
    final total = analytics['total'] as int;
    final completed = analytics['completed'] as int;
    final overdue = analytics['overdue'] as int;
    final completionRate = analytics['completionRate'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticItem(
                  'Total',
                  total.toString(),
                  Icons.flag,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildAnalyticItem(
                  'Completed',
                  completed.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildAnalyticItem(
                  'Overdue',
                  overdue.toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildAnalyticItem(
                  'Progress',
                  '${completionRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesList() {
    if (_milestones.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No milestones yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Milestones help track campaign progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Sort milestones by target date
    final sortedMilestones = List<CampaignMilestone>.from(_milestones)
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedMilestones.length,
      itemBuilder: (context, index) {
        final milestone = sortedMilestones[index];
        return _buildMilestoneCard(milestone);
      },
    );
  }

  Widget _buildMilestoneCard(CampaignMilestone milestone) {
    final isCompleted = milestone.isCompleted;
    final isOverdue = milestone.isOverdue;
    final daysUntilTarget = milestone.daysUntilTarget;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = '${milestone.daysOverdue} days overdue';
    } else if (daysUntilTarget <= 7) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'Due in $daysUntilTarget days';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.pending;
      statusText = milestone.status.value;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMilestoneDetails(milestone),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getMilestoneTypeColor(milestone.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getMilestoneTypeIcon(milestone.type),
                      color: _getMilestoneTypeColor(milestone.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          milestone.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (milestone.description.isNotEmpty)
                          Text(
                            milestone.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Target: ${_formatDate(milestone.targetDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (milestone.targetAmount != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Target: \$${milestone.targetAmount!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              if (milestone.targetAmount != null && milestone.currentAmount > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: milestone.progressPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${milestone.progressPercentage.toStringAsFixed(1)}% complete',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getMilestoneTypeColor(MilestoneType type) {
    switch (type) {
      case MilestoneType.funding:
        return Colors.blue;
      case MilestoneType.preparation:
        return Colors.orange;
      case MilestoneType.planting:
        return Colors.green;
      case MilestoneType.growth:
        return Colors.lightGreen;
      case MilestoneType.harvest:
        return Colors.amber;
      case MilestoneType.processing:
        return Colors.purple;
      case MilestoneType.distribution:
        return Colors.indigo;
      case MilestoneType.payout:
        return Colors.teal;
    }
  }

  IconData _getMilestoneTypeIcon(MilestoneType type) {
    switch (type) {
      case MilestoneType.funding:
        return Icons.monetization_on;
      case MilestoneType.preparation:
        return Icons.build;
      case MilestoneType.planting:
        return Icons.eco;
      case MilestoneType.growth:
        return Icons.trending_up;
      case MilestoneType.harvest:
        return Icons.agriculture;
      case MilestoneType.processing:
        return Icons.settings;
      case MilestoneType.distribution:
        return Icons.local_shipping;
      case MilestoneType.payout:
        return Icons.account_balance_wallet;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showMilestoneDetails(CampaignMilestone milestone) {
    showDialog(
      context: context,
      builder: (context) => MilestoneDetailsDialog(
        milestone: milestone,
        onUpdate: () {
          _loadMilestones();
          widget.onMilestoneUpdated?.call();
        },
      ),
    );
  }

  void _showAddMilestoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMilestoneDialog(
        campaignId: widget.campaignId,
        onAdd: () {
          _loadMilestones();
          widget.onMilestoneAdded?.call();
        },
      ),
    );
  }
}

/// Dialog for showing milestone details
class MilestoneDetailsDialog extends StatelessWidget {
  final CampaignMilestone milestone;
  final VoidCallback? onUpdate;

  const MilestoneDetailsDialog({
    super.key,
    required this.milestone,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(milestone.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(milestone.description),
            const SizedBox(height: 16),
            
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            _buildDetailRow('Type', milestone.type.value),
            _buildDetailRow('Status', milestone.status.value),
            _buildDetailRow('Target Date', _formatDate(milestone.targetDate)),
            
            if (milestone.completedDate != null)
              _buildDetailRow('Completed Date', _formatDate(milestone.completedDate!)),
            
            if (milestone.targetAmount != null) ...[
              _buildDetailRow('Target Amount', '\$${milestone.targetAmount!.toStringAsFixed(2)}'),
              _buildDetailRow('Current Amount', '\$${milestone.currentAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Progress', '${milestone.progressPercentage.toStringAsFixed(1)}%'),
            ],
            
            if (milestone.notes != null && milestone.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(milestone.notes!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (!milestone.isCompleted)
          ElevatedButton(
            onPressed: () => _markAsCompleted(context),
            child: const Text('Mark as Completed'),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _markAsCompleted(BuildContext context) async {
    try {
      final milestoneService = MilestoneTrackingService();
      await milestoneService.completeMilestone(milestone.id);
      
      if (context.mounted) {
        Navigator.of(context).pop();
        onUpdate?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milestone marked as completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update milestone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog for adding new milestones
class AddMilestoneDialog extends StatefulWidget {
  final String campaignId;
  final VoidCallback? onAdd;

  const AddMilestoneDialog({
    super.key,
    required this.campaignId,
    this.onAdd,
  });

  @override
  State<AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<AddMilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _notesController = TextEditingController();
  
  MilestoneType _selectedType = MilestoneType.preparation;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Milestone'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<MilestoneType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: MilestoneType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: _selectTargetDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Target Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount (Optional)',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createMilestone,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _selectTargetDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _targetDate = date;
      });
    }
  }

  Future<void> _createMilestone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final milestoneService = MilestoneTrackingService();
      
      final targetAmount = _targetAmountController.text.isNotEmpty
          ? double.tryParse(_targetAmountController.text)
          : null;
      
      final notes = _notesController.text.isNotEmpty
          ? _notesController.text
          : null;

      await milestoneService.createMilestone(
        campaignId: widget.campaignId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        targetDate: _targetDate,
        targetAmount: targetAmount,
        notes: notes,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onAdd?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milestone created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create milestone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
