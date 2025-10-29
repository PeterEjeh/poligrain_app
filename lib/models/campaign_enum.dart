enum CampaignType {
  loan('Loan'),
  investment('Investment'),
  crowdfunding('Crowdfunding');

  const CampaignType(this.value);
  final String value;

  static CampaignType fromString(String type) {
    return CampaignType.values.firstWhere(
      (e) => e.value.toLowerCase() == type.toLowerCase(),
      orElse: () => CampaignType.loan,
    );
  }
}

enum CampaignStatus {
  draft('Draft'),
  active('Active'),
  funded('Funded'),
  completed('Completed'),
  cancelled('Cancelled'),
  deleted('Deleted');

  const CampaignStatus(this.value);
  final String value;

  static CampaignStatus fromString(String status) {
    return CampaignStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == status.toLowerCase(),
      orElse: () => CampaignStatus.draft,
    );
  }
}
