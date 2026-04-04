class GroupMembershipState {
  final bool isMember;
  final bool isOwner;
  final bool isAdmin;
  final bool isBanned;
  final bool isMuted;
  final bool canSend;
  final bool notificationsMuted;
  final String role;

  const GroupMembershipState({
    required this.isMember,
    required this.isOwner,
    required this.isAdmin,
    required this.isBanned,
    required this.isMuted,
    required this.canSend,
    required this.notificationsMuted,
    required this.role,
  });

  factory GroupMembershipState.none() {
    return const GroupMembershipState(
      isMember: false,
      isOwner: false,
      isAdmin: false,
      isBanned: false,
      isMuted: false,
      canSend: false,
      notificationsMuted: false,
      role: 'none',
    );
  }
}
