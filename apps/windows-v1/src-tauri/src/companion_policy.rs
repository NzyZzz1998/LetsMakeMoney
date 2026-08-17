use crate::config::DesktopCompanionMode;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct CompanionSwitchPlan {
    pub source_label: &'static str,
    pub target_label: &'static str,
    pub changed: bool,
}

pub fn companion_window_label(mode: DesktopCompanionMode) -> &'static str {
    match mode {
        DesktopCompanionMode::Mini => "mini",
        DesktopCompanionMode::Pet => "pet",
    }
}

pub fn companion_switch_plan(
    current: DesktopCompanionMode,
    requested: DesktopCompanionMode,
) -> CompanionSwitchPlan {
    CompanionSwitchPlan {
        source_label: companion_window_label(current),
        target_label: companion_window_label(requested),
        changed: current != requested,
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CompanionPreVisibility {
    MiniExpanded,
    MiniPrivacyRetracted,
    PetVisible,
    HiddenByUser,
    NotPresent,
}

impl CompanionPreVisibility {
    pub fn label(self) -> &'static str {
        match self {
            Self::MiniExpanded => "mini_expanded",
            Self::MiniPrivacyRetracted => "mini_privacy_retracted",
            Self::PetVisible => "pet_visible",
            Self::HiddenByUser => "hidden_by_user",
            Self::NotPresent => "not_present",
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CompanionRestoreAction {
    ShowMiniExpanded,
    ShowMiniPrivacyRetracted,
    ShowPet,
    KeepHidden,
}

pub fn companion_restore_action(visibility: CompanionPreVisibility) -> CompanionRestoreAction {
    match visibility {
        CompanionPreVisibility::MiniExpanded => CompanionRestoreAction::ShowMiniExpanded,
        CompanionPreVisibility::MiniPrivacyRetracted => {
            CompanionRestoreAction::ShowMiniPrivacyRetracted
        }
        CompanionPreVisibility::PetVisible => CompanionRestoreAction::ShowPet,
        CompanionPreVisibility::HiddenByUser | CompanionPreVisibility::NotPresent => {
            CompanionRestoreAction::KeepHidden
        }
    }
}

pub fn companion_visibility_after_mode_switch(
    visibility: CompanionPreVisibility,
    requested: DesktopCompanionMode,
) -> CompanionPreVisibility {
    match visibility {
        CompanionPreVisibility::NotPresent => CompanionPreVisibility::NotPresent,
        _ => match requested {
            DesktopCompanionMode::Mini => CompanionPreVisibility::MiniExpanded,
            DesktopCompanionMode::Pet => CompanionPreVisibility::PetVisible,
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::DesktopCompanionMode;

    #[test]
    fn mini_and_pet_have_stable_window_labels() {
        assert_eq!(companion_window_label(DesktopCompanionMode::Mini), "mini");
        assert_eq!(companion_window_label(DesktopCompanionMode::Pet), "pet");
    }

    #[test]
    fn switch_plan_never_keeps_both_companions_active() {
        let plan = companion_switch_plan(DesktopCompanionMode::Mini, DesktopCompanionMode::Pet);
        assert!(plan.changed);
        assert_eq!(plan.source_label, "mini");
        assert_eq!(plan.target_label, "pet");

        let reverse = companion_switch_plan(DesktopCompanionMode::Pet, DesktopCompanionMode::Mini);
        assert!(reverse.changed);
        assert_eq!(reverse.source_label, "pet");
        assert_eq!(reverse.target_label, "mini");
    }

    #[test]
    fn selecting_the_current_mode_is_an_idempotent_noop() {
        let plan = companion_switch_plan(DesktopCompanionMode::Mini, DesktopCompanionMode::Mini);
        assert!(!plan.changed);
        assert_eq!(plan.source_label, plan.target_label);
    }

    #[test]
    fn workbench_restore_preserves_the_exact_companion_state() {
        assert_eq!(
            companion_restore_action(CompanionPreVisibility::MiniExpanded),
            CompanionRestoreAction::ShowMiniExpanded
        );
        assert_eq!(
            companion_restore_action(CompanionPreVisibility::MiniPrivacyRetracted),
            CompanionRestoreAction::ShowMiniPrivacyRetracted
        );
        assert_eq!(
            companion_restore_action(CompanionPreVisibility::PetVisible),
            CompanionRestoreAction::ShowPet
        );
        assert_eq!(
            companion_restore_action(CompanionPreVisibility::HiddenByUser),
            CompanionRestoreAction::KeepHidden
        );
        assert_eq!(
            companion_restore_action(CompanionPreVisibility::NotPresent),
            CompanionRestoreAction::KeepHidden
        );
    }

    #[test]
    fn switching_modes_rebases_the_restore_target_and_reveals_a_user_hidden_companion() {
        assert_eq!(
            companion_visibility_after_mode_switch(
                CompanionPreVisibility::MiniPrivacyRetracted,
                DesktopCompanionMode::Pet,
            ),
            CompanionPreVisibility::PetVisible,
        );
        assert_eq!(
            companion_visibility_after_mode_switch(
                CompanionPreVisibility::PetVisible,
                DesktopCompanionMode::Mini,
            ),
            CompanionPreVisibility::MiniExpanded,
        );
        assert_eq!(
            companion_visibility_after_mode_switch(
                CompanionPreVisibility::HiddenByUser,
                DesktopCompanionMode::Pet,
            ),
            CompanionPreVisibility::PetVisible,
        );
    }
}
