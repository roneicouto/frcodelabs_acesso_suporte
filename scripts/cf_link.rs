use hbb_common::{bail, config, ResultType};
use std::sync::{Once, OnceLock};

use crate::cf_link_config::{
    decode, DEFAULT_RECEIVE_PASSWORD_ENC, FULL_APP_NAME, ID_SERVER_ENC, PUBLIC_KEY_ENC,
    QS_APP_NAME, RELAY_SERVER_ENC, SECONDARY_RECEIVE_PASSWORD_ENC,
};

static INIT: Once = Once::new();

fn id_server() -> &'static str {
    static VAL: OnceLock<String> = OnceLock::new();
    VAL.get_or_init(|| decode(ID_SERVER_ENC)).as_str()
}

fn relay_server() -> &'static str {
    static VAL: OnceLock<String> = OnceLock::new();
    VAL.get_or_init(|| decode(RELAY_SERVER_ENC)).as_str()
}

fn public_key() -> &'static str {
    static VAL: OnceLock<String> = OnceLock::new();
    VAL.get_or_init(|| decode(PUBLIC_KEY_ENC)).as_str()
}

fn default_receive_password() -> &'static str {
    static VAL: OnceLock<String> = OnceLock::new();
    VAL.get_or_init(|| decode(DEFAULT_RECEIVE_PASSWORD_ENC)).as_str()
}

fn secondary_receive_password() -> &'static str {
    static VAL: OnceLock<String> = OnceLock::new();
    VAL.get_or_init(|| decode(SECONDARY_RECEIVE_PASSWORD_ENC)).as_str()
}

#[cfg(windows)]
pub fn installed_update_exe() -> String {
    if cfg!(feature = "cf-qs") {
        return String::new();
    }
    let (_, _, _, installed) = crate::platform::get_install_info();
    match (std::env::current_exe().and_then(std::fs::canonicalize), std::fs::canonicalize(&installed)) {
        (Ok(current), Ok(target)) if current == target => installed,
        _ => String::new(),
    }
}

pub fn init() {
    INIT.call_once(|| {
        *config::APP_NAME.write().unwrap() = if cfg!(feature = "cf-qs") {
            QS_APP_NAME
        } else {
            FULL_APP_NAME
        }
        .to_owned();

        config::OVERWRITE_SETTINGS.write().unwrap().extend(
            [
                ("custom-rendezvous-server", id_server()),
                ("relay-server", relay_server()),
                ("key", public_key()),
                ("api-server", ""),
                ("allow-auto-update", "N"),
                ("direct-server", "N"),
            ]
            .into_iter()
            .map(|(k, v)| (k.to_owned(), v.to_owned())),
        );
        config::BUILTIN_SETTINGS.write().unwrap().extend(
            [
                ("hide-server-settings", "Y"),
                ("hide-network-settings", "Y"),
                ("register-device", "N"),
                ("cf-profile", if cfg!(feature = "cf-qs") { "qs" } else { "full" }),
                ("cf-dark-only", "Y"),
                ("default-connect-password", ""),
            ]
            .into_iter()
            .map(|(k, v)| (k.to_owned(), v.to_owned())),
        );
        config::HARD_SETTINGS.write().unwrap().extend(
            [("disable-account", "Y"), ("disable-ab", "Y"),
             ("password", default_receive_password()), ("disable-change-permanent-password", "Y")]
                .into_iter()
                .map(|(k, v)| (k.to_owned(), v.to_owned())),
        );
        config::DEFAULT_LOCAL_SETTINGS
            .write()
            .unwrap()
            .insert("lang".to_owned(), "pt-br".to_owned());
        config::OVERWRITE_LOCAL_SETTINGS
            .write()
            .unwrap()
            .insert("theme".to_owned(), "dark".to_owned());
        config::DEFAULT_DISPLAY_SETTINGS.write().unwrap()
            .insert("view-style".to_owned(), "adaptive".to_owned());
        config::OVERWRITE_SETTINGS.write().unwrap().extend(
            [("verification-method", "use-both-passwords"), ("temporary-password-length", "8"),
             ("approve-mode", "both")]
                .into_iter().map(|(k, v)| (k.to_owned(), v.to_owned())),
        );

        if cfg!(feature = "cf-qs") {
            config::HARD_SETTINGS.write().unwrap().extend(
                [
                    ("conn-type", "incoming"),
                    ("disable-installation", "Y"),
                    ("disable-settings", "Y"),
                ]
                .into_iter()
                .map(|(k, v)| (k.to_owned(), v.to_owned())),
            );
            config::OVERWRITE_SETTINGS.write().unwrap().extend(
                [
                    ("approve-mode", "both"),
                    ("verification-method", "use-both-passwords"),
                    ("temporary-password-length", "8"),
                    ("allow-only-conn-window-open", "Y"),
                ]
                .into_iter()
                .map(|(k, v)| (k.to_owned(), v.to_owned())),
            );
        } else {
            config::DEFAULT_SETTINGS.write().unwrap().extend(
                [
                    ("approve-mode", "both"),
                    ("verification-method", "use-both-passwords"),
                ]
                .into_iter()
                .map(|(k, v)| (k.to_owned(), v.to_owned())),
            );
        }
    });
}

pub fn validate_peer(peer: &str, has_other_server: bool) -> ResultType<()> {
    if cfg!(feature = "cf-qs") {
        bail!("Incoming only mode");
    }
    if has_other_server || hbb_common::is_ip_str(peer) || hbb_common::is_domain_port_str(peer) {
        bail!("FR CODE LABS only connects to IDs on the company server");
    }
    Ok(())
}

pub fn receive_password() -> Option<&'static str> {
    let pwd = default_receive_password();
    if pwd.is_empty() { None } else { Some(pwd) }
}

pub fn receive_passwords() -> Vec<&'static str> {
    [default_receive_password(), secondary_receive_password()]
        .into_iter()
        .filter(|pwd| !pwd.is_empty())
        .collect()
}

pub fn has_receive_passwords() -> bool {
    !default_receive_password().is_empty() || !secondary_receive_password().is_empty()
}

pub fn init_peer_storage() {
    #[cfg(all(feature = "cf-full", not(any(target_os = "android", target_os = "ios"))))]
    {
        let mut app_dir = config::APP_DIR.write().unwrap();
        if app_dir.is_empty() {
            *app_dir = config::Config::path("").to_string_lossy().into_owned();
        }
    }
}

pub fn peer_config(mut peer: config::PeerConfig) -> config::PeerConfig {
    // Migrate older peers once; subsequent manual scale selections remain effective.
    if !peer.options.contains_key("cf-adaptive-default-v1") {
        peer.view_style = "adaptive".to_owned();
        peer.options.insert("cf-adaptive-default-v1".to_owned(), "Y".to_owned());
    }
    peer
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn connection_policy() {
        assert!(validate_peer("123456789", true).is_err());
        assert!(validate_peer("192.0.2.1", false).is_err());
        assert!(validate_peer("other.example:21118", false).is_err());
        assert_eq!(validate_peer("123456789", false).is_ok(), !cfg!(feature = "cf-qs"));
    }

    #[test]
    fn embedded_settings_take_precedence() {
        init();
        let options = config::Config::get_options();
        assert_eq!(options.get("custom-rendezvous-server").map(String::as_str), Some(id_server()));
        assert_eq!(options.get("relay-server").map(String::as_str), Some(relay_server()));
        assert_eq!(options.get("key").map(String::as_str), Some(public_key()));
        assert_eq!(config::is_incoming_only(), cfg!(feature = "cf-qs"));
        assert_eq!(config::is_disable_installation(), cfg!(feature = "cf-qs"));
        config::LocalConfig::set_option("theme".to_owned(), "light".to_owned());
        assert_eq!(config::LocalConfig::get_option("theme"), "dark");
        if cfg!(feature = "cf-qs") {
            assert_eq!(config::Config::get_option("approve-mode"), "both");
            assert_eq!(config::Config::get_option("verification-method"), "use-both-passwords");
            assert_eq!(config::Config::get_option("temporary-password-length"), "8");
            assert!(hbb_common::password_security::temporary_enabled());
            assert!(hbb_common::password_security::permanent_enabled());
            assert_eq!(hbb_common::password_security::temporary_password().len(), 8);
            assert_eq!(config::Config::get_option("allow-only-conn-window-open"), "Y");
        }
        assert!(hbb_common::password_security::temporary_enabled());
        assert!(hbb_common::password_security::permanent_enabled());
        assert!(!config::Config::get_preset_password_storage_and_salt().0.is_empty());
        assert!(receive_password().is_some());
        assert!(has_receive_passwords());
        assert!(!receive_passwords().is_empty());
    }

    #[test]
    fn adaptive_migration_preserves_manual_choice_and_saved_login() {
        init();
        let mut peer = config::PeerConfig::default();
        peer.view_style = "original".to_owned();
        peer.password = vec![1, 2, 3];
        let mut peer = peer_config(peer);
        assert_eq!(peer.view_style, "adaptive");
        assert_eq!(peer.password, vec![1, 2, 3]);
        peer.view_style = "original".to_owned();
        assert_eq!(peer_config(peer).view_style, "original");
    }

    #[cfg(all(feature = "cf-full", not(any(target_os = "android", target_os = "ios"))))]
    #[test]
    fn recent_and_favorite_peers_do_not_require_documents_directory() {
        init();
        let original = config::APP_DIR.read().unwrap().clone();
        config::APP_DIR.write().unwrap().clear();
        init_peer_storage();
        assert_eq!(*config::APP_DIR.read().unwrap(), config::Config::path("").to_string_lossy());
        *config::APP_DIR.write().unwrap() = "existing-documents".to_owned();
        init_peer_storage();
        assert_eq!(*config::APP_DIR.read().unwrap(), "existing-documents");
        *config::APP_DIR.write().unwrap() = original;
    }
}
