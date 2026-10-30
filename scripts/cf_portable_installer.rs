use std::path::Path;

const FULL_PAYLOAD: &str = "__CF_FULL_APP_NAME__";

pub fn is_full_installer(payload: &str, args: &[String]) -> bool {
    args.is_empty()
        && Path::new(payload)
            .file_stem()
            .and_then(|name| name.to_str())
            .map(|name| name.eq_ignore_ascii_case(FULL_PAYLOAD))
            .unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn full_is_installer_independent_of_download_filename() {
        assert!(is_full_installer(&format!(".\\{FULL_PAYLOAD}.exe"), &[]));
    }

    #[test]
    fn explicit_modes_bypass_default_installation() {
        for flag in ["--noinstall", "--update", "--version", "--install"] {
            assert!(!is_full_installer(&format!("{FULL_PAYLOAD}.exe"), &[flag.to_owned()]));
        }
    }

    #[test]
    fn qs_and_original_payloads_keep_their_previous_behavior() {
        assert!(!is_full_installer("FRCodeLabsQS.exe", &[]));
        assert!(!is_full_installer("rustdesk.exe", &[]));
    }
}

