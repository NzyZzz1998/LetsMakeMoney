use crate::companion_policy::CompanionPreVisibility;
use crate::platform::{physical_pixels, Rect};

pub const MINI_SAFE_GRAB_WIDTH_LOGICAL_PX: i32 = 28;
pub const MINI_SAFE_GRAB_HEIGHT_LOGICAL_PX: i32 = 48;
pub const STANDARD_SAFE_GRAB_LOGICAL_PX: i32 = 48;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum VisibilityLeasePhase {
    Closed,
    Opening,
    Open,
    Compensating,
    Failed,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum WorkbenchReadyStrategy {
    AwaitFrontend,
    ConfirmNatively,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CompanionSwitchLeaseStrategy {
    Direct,
    Rebase,
    Retry,
}

pub fn workbench_ready_strategy(window_preexisted: bool) -> WorkbenchReadyStrategy {
    if window_preexisted {
        WorkbenchReadyStrategy::ConfirmNatively
    } else {
        WorkbenchReadyStrategy::AwaitFrontend
    }
}

pub fn companion_switch_lease_strategy(
    phase: VisibilityLeasePhase,
) -> CompanionSwitchLeaseStrategy {
    match phase {
        VisibilityLeasePhase::Open => CompanionSwitchLeaseStrategy::Rebase,
        VisibilityLeasePhase::Opening | VisibilityLeasePhase::Compensating => {
            CompanionSwitchLeaseStrategy::Retry
        }
        VisibilityLeasePhase::Closed | VisibilityLeasePhase::Failed => {
            CompanionSwitchLeaseStrategy::Direct
        }
    }
}

impl VisibilityLeasePhase {
    pub fn label(self) -> &'static str {
        match self {
            Self::Closed => "closed",
            Self::Opening => "opening",
            Self::Open => "open",
            Self::Compensating => "compensating",
            Self::Failed => "failed",
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct VisibilityLease {
    pub transaction_id: u64,
    pub phase: VisibilityLeasePhase,
    pub companion_before: CompanionPreVisibility,
}

#[derive(Debug)]
pub struct VisibilityLeaseMachine {
    next_transaction_id: u64,
    current: VisibilityLease,
}

impl Default for VisibilityLeaseMachine {
    fn default() -> Self {
        Self {
            next_transaction_id: 1,
            current: VisibilityLease {
                transaction_id: 0,
                phase: VisibilityLeasePhase::Closed,
                companion_before: CompanionPreVisibility::NotPresent,
            },
        }
    }
}

impl VisibilityLeaseMachine {
    pub fn current(&self) -> VisibilityLease {
        self.current
    }

    pub fn begin(&mut self, companion_before: CompanionPreVisibility) -> (VisibilityLease, bool) {
        if matches!(
            self.current.phase,
            VisibilityLeasePhase::Opening
                | VisibilityLeasePhase::Open
                | VisibilityLeasePhase::Compensating
        ) {
            return (self.current, false);
        }
        let transaction_id = self.next_transaction_id;
        self.next_transaction_id = self.next_transaction_id.saturating_add(1);
        self.current = VisibilityLease {
            transaction_id,
            phase: VisibilityLeasePhase::Opening,
            companion_before,
        };
        (self.current, true)
    }

    pub fn transition(
        &mut self,
        transaction_id: u64,
        phase: VisibilityLeasePhase,
    ) -> Option<VisibilityLease> {
        if self.current.transaction_id != transaction_id {
            return None;
        }
        self.current.phase = phase;
        Some(self.current)
    }

    pub fn begin_compensation(&mut self, transaction_id: u64) -> Option<VisibilityLease> {
        self.transition(transaction_id, VisibilityLeasePhase::Compensating)
    }

    pub fn rebase_companion(
        &mut self,
        from: CompanionPreVisibility,
        to: CompanionPreVisibility,
    ) -> bool {
        if self.current.companion_before != from
            || !matches!(
                self.current.phase,
                VisibilityLeasePhase::Opening
                    | VisibilityLeasePhase::Open
                    | VisibilityLeasePhase::Compensating
            )
        {
            return false;
        }
        self.current.companion_before = to;
        true
    }
}

pub fn safe_grab_logical_size(label: &str) -> (i32, i32) {
    if label == "mini" {
        (
            MINI_SAFE_GRAB_WIDTH_LOGICAL_PX,
            MINI_SAFE_GRAB_HEIGHT_LOGICAL_PX,
        )
    } else {
        (STANDARD_SAFE_GRAB_LOGICAL_PX, STANDARD_SAFE_GRAB_LOGICAL_PX)
    }
}

pub fn recover_to_safe_grab_region(
    window: Rect,
    work_area: Rect,
    scale_factor: f64,
    grab_width_logical_px: i32,
    grab_height_logical_px: i32,
) -> (i32, i32) {
    let grab_width =
        physical_pixels(grab_width_logical_px.max(1), scale_factor).min(window.width.max(1) as i32);
    let grab_height = physical_pixels(grab_height_logical_px.max(1), scale_factor)
        .min(window.height.max(1) as i32);
    let work_right = work_area.x.saturating_add(work_area.width as i32);
    let work_bottom = work_area.y.saturating_add(work_area.height as i32);
    let min_x = work_area
        .x
        .saturating_sub(window.width as i32)
        .saturating_add(grab_width);
    let max_x = work_right.saturating_sub(grab_width);
    let min_y = work_area
        .y
        .saturating_sub(window.height as i32)
        .saturating_add(grab_height);
    let max_y = work_bottom.saturating_sub(grab_height);

    (
        window.x.clamp(min_x.min(max_x), min_x.max(max_x)),
        window.y.clamp(min_y.min(max_y), min_y.max(max_y)),
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lease_is_idempotent_and_ignores_late_transitions() {
        let mut machine = VisibilityLeaseMachine::default();
        let (first, started) = machine.begin(CompanionPreVisibility::MiniPrivacyRetracted);
        assert!(started);
        let (same, started_again) = machine.begin(CompanionPreVisibility::MiniExpanded);
        assert!(!started_again);
        assert_eq!(same, first);
        assert!(machine
            .transition(first.transaction_id, VisibilityLeasePhase::Open)
            .is_some());
        assert!(machine
            .transition(
                first.transaction_id.saturating_add(1),
                VisibilityLeasePhase::Failed
            )
            .is_none());
        assert_eq!(machine.current().phase, VisibilityLeasePhase::Open);
        machine.transition(first.transaction_id, VisibilityLeasePhase::Closed);
        let (second, restarted) = machine.begin(CompanionPreVisibility::HiddenByUser);
        assert!(restarted);
        assert!(second.transaction_id > first.transaction_id);
    }

    #[test]
    fn reused_workbench_is_confirmed_without_waiting_for_a_remount() {
        assert_eq!(
            workbench_ready_strategy(false),
            WorkbenchReadyStrategy::AwaitFrontend
        );
        assert_eq!(
            workbench_ready_strategy(true),
            WorkbenchReadyStrategy::ConfirmNatively
        );
    }

    #[test]
    fn companion_switch_rebases_an_open_workbench_instead_of_rejecting_it() {
        assert_eq!(
            companion_switch_lease_strategy(VisibilityLeasePhase::Open),
            CompanionSwitchLeaseStrategy::Rebase,
        );
        assert_eq!(
            companion_switch_lease_strategy(VisibilityLeasePhase::Opening),
            CompanionSwitchLeaseStrategy::Retry,
        );
        assert_eq!(
            companion_switch_lease_strategy(VisibilityLeasePhase::Compensating),
            CompanionSwitchLeaseStrategy::Retry,
        );
        assert_eq!(
            companion_switch_lease_strategy(VisibilityLeasePhase::Closed),
            CompanionSwitchLeaseStrategy::Direct,
        );
    }

    #[test]
    fn active_workbench_lease_rebases_failed_pet_to_mini() {
        let mut machine = VisibilityLeaseMachine::default();
        let (lease, started) = machine.begin(CompanionPreVisibility::PetVisible);
        assert!(started);
        machine.transition(lease.transaction_id, VisibilityLeasePhase::Open);

        assert!(machine.rebase_companion(
            CompanionPreVisibility::PetVisible,
            CompanionPreVisibility::MiniExpanded,
        ));
        assert_eq!(
            machine.current().companion_before,
            CompanionPreVisibility::MiniExpanded
        );
    }

    #[test]
    fn compensation_uses_the_latest_rebased_companion() {
        let mut machine = VisibilityLeaseMachine::default();
        let (lease, started) = machine.begin(CompanionPreVisibility::MiniExpanded);
        assert!(started);
        machine.transition(lease.transaction_id, VisibilityLeasePhase::Open);

        let stale_observation = machine.current();
        assert!(machine.rebase_companion(
            CompanionPreVisibility::MiniExpanded,
            CompanionPreVisibility::PetVisible,
        ));

        let compensation = machine
            .begin_compensation(stale_observation.transaction_id)
            .expect("active lease must enter compensation");
        assert_eq!(compensation.phase, VisibilityLeasePhase::Compensating);
        assert_eq!(
            compensation.companion_before,
            CompanionPreVisibility::PetVisible,
            "a close transaction must restore the rebased pet, not its stale Mini snapshot"
        );
    }

    #[test]
    fn safe_grab_recovery_allows_partial_offscreen_positions() {
        let work = Rect {
            x: 0,
            y: 0,
            width: 1920,
            height: 1040,
        };
        let mini = Rect {
            x: -316,
            y: 200,
            width: 344,
            height: 108,
        };
        assert_eq!(
            recover_to_safe_grab_region(mini, work, 1.0, 28, 48),
            (-316, 200),
            "the 28px privacy tab is a valid reachable Mini position"
        );
        let lost = Rect {
            x: -900,
            y: -500,
            ..mini
        };
        assert_eq!(
            recover_to_safe_grab_region(lost, work, 1.0, 28, 48),
            (-316, -60)
        );
    }

    #[test]
    fn safe_grab_thresholds_scale_at_100_125_and_150_percent() {
        let work = Rect {
            x: 0,
            y: 0,
            width: 1920,
            height: 1080,
        };
        let window = Rect {
            x: 1910,
            y: 1070,
            width: 760,
            height: 560,
        };
        assert_eq!(
            recover_to_safe_grab_region(window, work, 1.0, 48, 48),
            (1872, 1032)
        );
        assert_eq!(
            recover_to_safe_grab_region(window, work, 1.25, 48, 48),
            (1860, 1020)
        );
        assert_eq!(
            recover_to_safe_grab_region(window, work, 1.5, 48, 48),
            (1848, 1008)
        );
    }
}
