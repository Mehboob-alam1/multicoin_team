# Remote Config (Firebase)

Use **one boolean** to enable/disable all ads, and **one URL** for Chrome Custom Tabs when you prefer opening a link instead of showing an ad.

## Template format

`remote_config_defaults.json` uses the same structure as Firebase Remote Config (parameters with `defaultValue.value` and `valueType`). You can import it in Firebase Console or copy the keys/values.

## Keys

| Key | Type | Description |
|-----|------|-------------|
| `ads_enabled` | Boolean | **Only** toggle: when `false`, no ads and no custom tab anywhere. |
| `use_custom_tab` | Boolean | When `true`, open `custom_tab_url` in Chrome Custom Tabs instead of showing any ad (interstitial, app open, rewarded). |
| `custom_tab_url` | String | URL used when `use_custom_tab` is true. |
| `interstitial_ad_unit` | String | AdMob interstitial unit ID. |
| `interstitial_admanager_unit` | String | Ad Manager interstitial unit ID. |
| `rewarded_ad_unit` | String | AdMob rewarded unit ID. |
| `rewarded_admanager_unit` | String | Ad Manager rewarded unit ID. |
| `native_ad_unit` | String | AdMob native unit ID. |
| `native_admanager_unit` | String | Ad Manager native unit ID. |
| `admob_app_open_android` | String | AdMob app-open unit ID. |
| `admanager_app_open` | String | Ad Manager app-open unit ID. |
| `banner_ad_unit` | String | AdMob banner unit ID. |
| `banner_admanager_unit` | String | Ad Manager banner unit ID. |

## Behavior

- **ads_enabled = false** → All ad slots and custom-tab fallback are off.
- **ads_enabled = true, use_custom_tab = false** → Show ads (unit IDs from Remote Config).
- **ads_enabled = true, use_custom_tab = true** → Open `custom_tab_url` in custom tabs instead of ads; pacing/cooldowns still apply.
