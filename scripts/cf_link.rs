use hbb_common::{bail, config, ResultType};
use std::sync::Once;

use crate::cf_link_config::{FULL_APP_NAME, ID_SERVER, PUBLIC_KEY, QS_APP_NAME, RELAY_SERVER};

static INIT: Once = Once::new();

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
                ("custom-rendezvous-server", ID_SERVER),
                ("relay-server", RELAY_SERVER),
                ("key", PUBLIC_KEY),
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
            ]
            .into_iter()
            .map(|(k, v)| (k.to_owned(), v.to_owned())),
        );
        config::HARD_SETTINGS.write().unwrap().extend(
            [("disable-account", "Y"), ("disable-ab", "Y")]
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
                    ("verification-method", "use-temporary-password"),
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
        bail!("CF Link only connects to IDs on the company server");
    }
    Ok(())
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
        assert_eq!(options.get("custom-rendezvous-server").map(String::as_str), Some(ID_SERVER));
        assert_eq!(options.get("relay-server").map(String::as_str), Some(RELAY_SERVER));
        assert_eq!(options.get("key").map(String::as_str), Some(PUBLIC_KEY));
        assert_eq!(config::is_incoming_only(), cfg!(feature = "cf-qs"));
        assert_eq!(config::is_disable_installation(), cfg!(feature = "cf-qs"));
        config::LocalConfig::set_option("theme".to_owned(), "light".to_owned());
        assert_eq!(config::LocalConfig::get_option("theme"), "dark");
        if cfg!(feature = "cf-qs") {
            assert_eq!(config::Config::get_option("approve-mode"), "both");
            assert_eq!(config::Config::get_option("verification-method"), "use-temporary-password");
            assert_eq!(config::Config::get_option("temporary-password-length"), "8");
            assert!(hbb_common::password_security::temporary_enabled());
            assert!(!hbb_common::password_security::permanent_enabled());
            assert_eq!(hbb_common::password_security::temporary_password().len(), 8);
            assert_eq!(config::Config::get_option("allow-only-conn-window-open"), "Y");
        }
    }
}
