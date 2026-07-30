use std::{env, fs, path::PathBuf};

fn main() {
    generate_calendar_index();
    tauri_build::build();
}

fn generate_calendar_index() {
    let manifest_dir = PathBuf::from("../calendar-data");
    let manifest_path = manifest_dir.join("manifest.json");
    let manifest_bytes =
        fs::read(&manifest_path).expect("calendar manifest must be readable during build");
    let manifest: serde_json::Value =
        serde_json::from_slice(&manifest_bytes).expect("calendar manifest must be valid JSON");
    let datasets = manifest
        .get("datasets")
        .and_then(serde_json::Value::as_array)
        .expect("calendar manifest datasets must be an array");

    let mut generated =
        String::from("const CALENDAR_DATASETS: &[(i32, &str, &str)] = &[\n");
    for dataset in datasets {
        let year = dataset
            .get("year")
            .and_then(serde_json::Value::as_i64)
            .expect("calendar dataset year must be an integer");
        let file = dataset
            .get("file")
            .and_then(serde_json::Value::as_str)
            .expect("calendar dataset file must be a string");
        let dataset_path = manifest_dir.join(file);
        let absolute_path = fs::canonicalize(&dataset_path)
            .unwrap_or_else(|_| panic!("calendar dataset is missing: {}", dataset_path.display()));
        let include_path = absolute_path.to_string_lossy().replace('\\', "/");
        generated.push_str(&format!(
            "    ({year}, {file:?}, include_str!(r#\"{include_path}\"#)),\n"
        ));
        println!("cargo:rerun-if-changed={}", dataset_path.display());
    }
    generated.push_str("];\n");

    let output_path =
        PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR must be set")).join("calendar_index.rs");
    fs::write(output_path, generated).expect("calendar index must be generated");
    println!("cargo:rerun-if-changed={}", manifest_path.display());
}
