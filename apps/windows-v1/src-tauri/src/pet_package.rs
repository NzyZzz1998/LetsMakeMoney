use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

const RUNTIME_PATHS: [&str; 7] = [
    "assets/atlas-00.webp",
    "evidence/license.json",
    "evidence/provenance.json",
    "evidence/source-evidence.json",
    "hitmasks/atlas-00.hitmask.json",
    "motion-manifest.json",
    "package-index.json",
];

const ATLAS: &[u8] =
    include_bytes!("../pet-packages/classic-first-return-vnext/assets/atlas-00.webp");
const LICENSE: &[u8] =
    include_bytes!("../pet-packages/classic-first-return-vnext/evidence/license.json");
const PROVENANCE: &[u8] =
    include_bytes!("../pet-packages/classic-first-return-vnext/evidence/provenance.json");
const SOURCE_EVIDENCE: &[u8] =
    include_bytes!("../pet-packages/classic-first-return-vnext/evidence/source-evidence.json");
const HIT_MASKS: &[u8] =
    include_bytes!("../pet-packages/classic-first-return-vnext/hitmasks/atlas-00.hitmask.json");
const MANIFEST: &[u8] =
    include_bytes!("../pet-packages/classic-first-return-vnext/motion-manifest.json");
const PACKAGE_INDEX: &[u8] =
    include_bytes!("../pet-packages/classic-first-return-vnext/package-index.json");

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct PackageIndex {
    schema_version: u32,
    package_version: String,
    pet_id: String,
    manifest: String,
    manifest_sha256: String,
    package_tree_sha256: String,
    status: String,
    ready: bool,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct MotionManifest {
    schema_version: u32,
    package_version: String,
    pet_id: String,
    actions: Vec<MotionAction>,
    sha256: ManifestHashes,
}

#[derive(Debug, Deserialize)]
struct ManifestHashes {
    files: BTreeMap<String, String>,
}

#[derive(Debug, Deserialize)]
struct MotionAction {
    id: String,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct RuntimePackageSummary {
    pub pet_id: String,
    pub package_version: String,
    pub action_count: usize,
    pub manifest_sha256: String,
    pub package_tree_sha256: String,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ProductPackageStatus {
    pub available: bool,
    pub reason: Option<String>,
    pub package: Option<RuntimePackageSummary>,
}

pub fn runtime_file_paths() -> Vec<&'static str> {
    RUNTIME_PATHS.to_vec()
}

pub fn runtime_file(relative_path: &str) -> Option<&'static [u8]> {
    match relative_path.replace('\\', "/").as_str() {
        "assets/atlas-00.webp" => Some(ATLAS),
        "evidence/license.json" => Some(LICENSE),
        "evidence/provenance.json" => Some(PROVENANCE),
        "evidence/source-evidence.json" => Some(SOURCE_EVIDENCE),
        "hitmasks/atlas-00.hitmask.json" => Some(HIT_MASKS),
        "motion-manifest.json" => Some(MANIFEST),
        "package-index.json" => Some(PACKAGE_INDEX),
        _ => None,
    }
}

pub fn validate_runtime_package() -> Result<RuntimePackageSummary, String> {
    let index: PackageIndex = serde_json::from_slice(PACKAGE_INDEX)
        .map_err(|_| "pet_package_index_invalid".to_string())?;
    if index.schema_version != 1
        || index.manifest != "motion-manifest.json"
        || index.status != "approved"
        || !index.ready
    {
        return Err("pet_package_index_not_ready".to_string());
    }
    let manifest_sha256 = format!("{:X}", Sha256::digest(MANIFEST));
    if manifest_sha256 != index.manifest_sha256 {
        return Err("pet_package_manifest_hash_mismatch".to_string());
    }
    let manifest: MotionManifest =
        serde_json::from_slice(MANIFEST).map_err(|_| "pet_package_manifest_invalid".to_string())?;
    if manifest.schema_version != 2
        || manifest.pet_id != index.pet_id
        || manifest.package_version != index.package_version
        || manifest.actions.len() != 12
        || manifest
            .actions
            .iter()
            .any(|action| action.id.trim().is_empty())
    {
        return Err("pet_package_manifest_contract_mismatch".to_string());
    }
    validate_bound_file_hashes(&manifest.sha256.files)?;
    validate_package_tree_hash(
        &manifest.sha256.files,
        &manifest_sha256,
        &index.package_tree_sha256,
    )?;
    Ok(RuntimePackageSummary {
        pet_id: index.pet_id,
        package_version: index.package_version,
        action_count: manifest.actions.len(),
        manifest_sha256,
        package_tree_sha256: index.package_tree_sha256,
    })
}

fn validate_bound_file_hashes(files: &BTreeMap<String, String>) -> Result<(), String> {
    for (relative_path, expected_hash) in files {
        let bytes = runtime_file(relative_path)
            .ok_or_else(|| "pet_package_bound_file_missing".to_string())?;
        let actual_hash = format!("{:X}", Sha256::digest(bytes));
        if !actual_hash.eq_ignore_ascii_case(expected_hash) {
            return Err("pet_package_bound_file_hash_mismatch".to_string());
        }
    }
    Ok(())
}

fn validate_package_tree_hash(
    files: &BTreeMap<String, String>,
    manifest_sha256: &str,
    expected_tree_hash: &str,
) -> Result<(), String> {
    let mut tree_files = files.clone();
    tree_files.insert(
        "motion-manifest.json".to_string(),
        manifest_sha256.to_string(),
    );
    let mut payload = Vec::new();
    for (relative_path, file_hash) in tree_files {
        payload.extend_from_slice(relative_path.as_bytes());
        payload.push(0);
        payload.extend_from_slice(file_hash.as_bytes());
    }
    let actual_tree_hash = format!("{:X}", Sha256::digest(payload));
    if !actual_tree_hash.eq_ignore_ascii_case(expected_tree_hash) {
        return Err("pet_package_tree_hash_mismatch".to_string());
    }
    Ok(())
}

pub fn preflight() -> Result<RuntimePackageSummary, String> {
    let summary = validate_runtime_package()?;
    let license: serde_json::Value =
        serde_json::from_slice(LICENSE).map_err(|_| "pet_package_license_invalid".to_string())?;
    let provenance: serde_json::Value = serde_json::from_slice(PROVENANCE)
        .map_err(|_| "pet_package_provenance_invalid".to_string())?;
    let product_approved = provenance["productReturnApproved"].as_bool() == Some(true);
    let redistribution = license["redistribution"].as_str() == Some("product-runtime");
    if !product_approved || !redistribution {
        return Err("pet_package_not_approved_for_product".to_string());
    }
    Ok(summary)
}

pub fn product_status() -> ProductPackageStatus {
    match preflight() {
        Ok(package) => ProductPackageStatus {
            available: true,
            reason: None,
            package: Some(package),
        },
        Err(reason) => ProductPackageStatus {
            available: false,
            reason: Some(reason),
            package: validate_runtime_package().ok(),
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use sha2::{Digest, Sha256};

    #[test]
    fn formal_package_contains_only_the_sanitized_runtime_allowlist() {
        assert_eq!(
            runtime_file_paths(),
            vec![
                "assets/atlas-00.webp",
                "evidence/license.json",
                "evidence/provenance.json",
                "evidence/source-evidence.json",
                "hitmasks/atlas-00.hitmask.json",
                "motion-manifest.json",
                "package-index.json",
            ]
        );
        for path in runtime_file_paths() {
            assert!(!runtime_file(path).expect("allowlisted file").is_empty());
        }
    }

    #[test]
    fn package_identity_and_reduced_action_catalog_are_locked() {
        let manifest = runtime_file("motion-manifest.json").expect("manifest");
        let manifest_sha = format!("{:X}", Sha256::digest(manifest));
        assert_eq!(
            manifest_sha,
            "78DD5FEC1C046BBC22CFC887C799E26DAEE8F4E28D3D5A52A63CD39869412F89"
        );
        let parsed: serde_json::Value = serde_json::from_slice(manifest).expect("valid manifest");
        let actions = parsed["actions"]
            .as_array()
            .expect("actions")
            .iter()
            .map(|action| action["id"].as_str().expect("action id"))
            .collect::<Vec<_>>();
        assert_eq!(
            actions,
            vec![
                "working_play_loop_a",
                "working_play_loop_b",
                "working_observe",
                "working_ack",
                "awake_rest_loop",
                "rest_ack",
                "sleeping_loop",
                "sleep_twitch",
                "sleep_ack",
                "run_prepare",
                "run_loop",
                "run_stop",
            ]
        );
    }

    #[test]
    fn approved_reduced_package_opens_only_the_classic_product_candidate() {
        let summary = validate_runtime_package().expect("valid reduced runtime package");
        assert_eq!(summary.pet_id, "letsmakemoney-classic-pro");
        assert_eq!(summary.action_count, 12);
        assert_eq!(summary.package_version, "0.4.1-rc.1");
        assert_eq!(
            summary.package_tree_sha256,
            "8B8C3A2562A0509F9D9D713D283B38E3D1BC128007519E6E491B109BF87165D3"
        );
        assert_eq!(
            preflight()
                .expect("approved product candidate")
                .package_version,
            "0.4.1-rc.1"
        );
        let status = product_status();
        assert!(status.available);
        assert!(status.reason.is_none());
        assert_eq!(status.package.expect("approved package").action_count, 12);
    }

    #[test]
    fn embedded_package_validates_every_bound_file_and_the_package_tree() {
        let manifest: MotionManifest =
            serde_json::from_slice(MANIFEST).expect("valid motion manifest");
        validate_bound_file_hashes(&manifest.sha256.files).expect("bound file hashes");

        let index: PackageIndex =
            serde_json::from_slice(PACKAGE_INDEX).expect("valid package index");
        validate_package_tree_hash(
            &manifest.sha256.files,
            &index.manifest_sha256,
            &index.package_tree_sha256,
        )
        .expect("package tree hash");
    }
}
