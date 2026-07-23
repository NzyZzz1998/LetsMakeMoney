param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$GodotExe = "",
    [switch]$StaticOnly
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$petPath = Join-Path $root "src\scenes\pet\pet.gd"
$mainPath = Join-Path $root "src\scenes\main\main.gd"
$arbiterPath = Join-Path $root "src\utils\pet_input_arbiter.gd"
$pet = Get-Content -LiteralPath $petPath -Raw
$main = Get-Content -LiteralPath $mainPath -Raw
$arbiter = Get-Content -LiteralPath $arbiterPath -Raw

$staticContracts = @(
    @{ Label = "event driven animation completion"; Text = $pet; Pattern = '_on_sprite_animation_finished' },
    @{ Label = "animation timeout protection"; Text = $pet; Pattern = '_animation_controller\.tick\(now_ms\)' },
    @{ Label = "debug interaction uses pet lifecycle"; Text = $main; Pattern = 'trigger_interaction_from_debug' },
    @{ Label = "drag threshold"; Text = $pet; Pattern = 'const DRAG_THRESHOLD := 5\.0' },
    @{ Label = "hold threshold"; Text = $pet; Pattern = 'const LONG_PRESS_THRESHOLD_MS := 500' },
    @{ Label = "separate input arbiter"; Text = $pet; Pattern = 'InputArbiterScript' },
    @{ Label = "immediate single dispatch"; Text = $pet; Pattern = '"single":\s+_fire_click_interaction\(PetManager\.PetInteraction\.CLICKED_SINGLE\)' },
    @{ Label = "run prepare dispatch"; Text = $pet; Pattern = '"run_prepare":\s+_start_run' },
    @{ Label = "run movement dispatch"; Text = $pet; Pattern = '"run_move":\s+_update_run' },
    @{ Label = "run settle dispatch"; Text = $pet; Pattern = '"run_settle":\s+_end_run' },
	@{ Label = "approved run stop playback"; Text = $pet; Pattern = 'resolved in \["run_stop", "run_settle"\]' },
    @{ Label = "run entry after hold threshold"; Text = $arbiter; Pattern = 'now_ms - _press_time_ms >= _hold_threshold_ms' },
    @{ Label = "run movement event"; Text = $arbiter; Pattern = '"type": "run_move"' }
)

foreach ($contract in $staticContracts) {
    if ($contract.Text -notmatch $contract.Pattern) {
        throw "v0.9 behavior baseline changed: $($contract.Label)"
    }
}

if ($pet -match '"double":\s+_fire_click_interaction' -or $main -match 'PetInteraction\.CLICKED_DOUBLE') {
    throw "v0.9 behavior baseline changed: double click must not remain a product input action"
}

if (-not $StaticOnly) {
    $godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
    [void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $root -ScriptPath "res://scripts/verify_v09_behavior_baseline.gd" -Label "v09-behavior-baseline" -SuccessMarker "v0.9 behavior baseline verification passed")
}

Write-Host "v0.9 behavior baseline passed"
