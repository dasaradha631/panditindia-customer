import '../../models/booking.dart';
import '../theme/app_theme.dart';

enum StageStatus { completed, current, upcoming, cancelled }

/// One step of the sacred ritual lifecycle (port of the web
/// `getCeremonyTrackingStages` helper).
class CeremonyStage {
  const CeremonyStage({
    required this.num,
    required this.title,
    required this.description,
    required this.detail,
    required this.status,
  });

  final int num;
  final String title;
  final String description;
  final String detail;
  final StageStatus status;

  bool get isDone => status == StageStatus.completed;
  bool get isCurrent => status == StageStatus.current;
}

class CeremonyLifecycle {
  const CeremonyLifecycle({
    required this.stages,
    required this.currentStepIdx,
    required this.isCancelled,
    required this.isCompleted,
    required this.isPanditAssigned,
    required this.isEnRoute,
    required this.isInProgress,
  });

  final List<CeremonyStage> stages;
  final int currentStepIdx;
  final bool isCancelled;
  final bool isCompleted;
  final bool isPanditAssigned;
  final bool isEnRoute;
  final bool isInProgress;
}

/// Computes the 6-stage lifecycle (1-6) for [booking], mirroring the web
/// dashboard behaviour.
CeremonyLifecycle ceremonyLifecycle(Booking booking) {
  final raw = (booking.rawStatus ?? booking.status ?? 'pending').toLowerCase();
  final isCancelled = raw.contains('cancel');
  final isCompleted = raw.contains('complete');

  final rawPandit = booking.assignedPandit;
  final isPanditAssigned =
      rawPandit != null &&
      rawPandit.isNotEmpty &&
      rawPandit != 'Unassigned' &&
      rawPandit != 'None' &&
      rawPandit != 'Pending';

  final isEnRoute =
      raw.contains('route') ||
      raw.contains('transit') ||
      raw.contains('way') ||
      (booking.isTracking ?? false);

  final isInProgress =
      raw.contains('progress') ||
      raw.contains('live') ||
      raw.contains('arrived') ||
      raw.contains('aarti');

  int step = 0;
  if (isCompleted) {
    step = 5;
  } else if (isInProgress) {
    step = 4;
  } else if (isEnRoute) {
    step = 3;
  } else if (isPanditAssigned) {
    step = 2;
  }

  StageStatus statusFor(int idx) {
    if (isCancelled) return StageStatus.cancelled;
    if (step > idx) return StageStatus.completed;
    if (step == idx) {
      // The final node never renders as "current" on the web dashboard —
      // reaching it means the ceremony is done.
      if (idx == 5) return StageStatus.completed;
      return StageStatus.current;
    }
    return StageStatus.upcoming;
  }

  final ref = AppStatus.normalizeBookingId(booking.bookingId ?? '');

  final stages = <CeremonyStage>[
    CeremonyStage(
      num: 1,
      title: 'Booking Confirmed',
      description: 'Ref #$ref verified',
      detail: (booking.createdAt?.isNotEmpty ?? false)
          ? booking.createdAt!
          : 'Verified & Locked',
      status: isCancelled
          ? StageStatus.cancelled
          : (!isPanditAssigned && step == 0)
          ? StageStatus.current
          : StageStatus.completed,
    ),
    CeremonyStage(
      num: 2,
      title: isPanditAssigned ? 'Acharya Assigned' : 'Acharya Allocation',
      description: isPanditAssigned
          ? rawPandit
          : 'Allocating Gurukul Acharya',
      detail: isPanditAssigned
          ? ((booking.panditVeda?.isNotEmpty ?? false)
                ? '${booking.panditVeda} Scholar'
                : 'Verified Acharya')
          : 'In Allocation',
      status: isCancelled
          ? StageStatus.cancelled
          : isPanditAssigned
          ? StageStatus.completed
          : (step == 0
                ? StageStatus.current
                : StageStatus.upcoming),
    ),
    CeremonyStage(
      num: 3,
      title: 'Ceremony Preparation',
      description: (booking.samagri?.isNotEmpty ?? false)
          ? booking.samagri!
          : '100% Sealed Eco-Samagri Kit Packed',
      detail: 'Mandap Prep Ready',
      status: statusFor(2),
    ),
    CeremonyStage(
      num: 4,
      title: isEnRoute ? 'Acharya En Route' : 'Ceremony Scheduled',
      description: '${booking.bookingDate ?? 'Upcoming'} • ${booking.timeSlot ?? 'Morning Muhurat'}',
      detail: isEnRoute ? 'Live GPS Active' : 'Muhurat Locked',
      status: statusFor(3),
    ),
    CeremonyStage(
      num: 5,
      title: 'Live Ceremony & Homam',
      description: 'Mandap Sthapana & 108 Ahutis',
      detail: 'Agni Hotra',
      status: statusFor(4),
    ),
    CeremonyStage(
      num: 6,
      title: 'Ceremony Completed',
      description: 'Purna Ahuti, Aarti & Blessings',
      detail: 'Prasad & 80G Receipt',
      status: statusFor(5),
    ),
  ];

  return CeremonyLifecycle(
    stages: stages,
    currentStepIdx: step,
    isCancelled: isCancelled,
    isCompleted: isCompleted,
    isPanditAssigned: isPanditAssigned,
    isEnRoute: isEnRoute,
    isInProgress: isInProgress,
  );
}
