/// Huami / Mi Band 5 BLE UUIDs and protocol constants.
///
/// Values derived from Gadgetbridge (AGPLv3):
///  - devices/huami/HuamiService.java
///  - service/devices/huami/operations/init/InitOperation.java
class HuamiUuids {
  HuamiUuids._();

  // ---- GATT services ----
  /// Main Huami service (steps, activity, battery, realtime, config).
  static const String serviceMain = '0000fee0-0000-1000-8000-00805f9b34fb';

  /// Auth service (also holds the chunked-transfer characteristic).
  static const String serviceAuth = '0000fee1-0000-1000-8000-00805f9b34fb';

  static const String serviceHeartRate = '0000180d-0000-1000-8000-00805f9b34fb';

  // ---- Characteristics under FEE0 ----
  static const String charConfig3       = '00000003-0000-3512-2118-0009af100700';
  static const String charActivityData  = '00000005-0000-3512-2118-0009af100700';
  static const String charBatteryInfo   = '00000006-0000-3512-2118-0009af100700';
  static const String charRealtimeSteps = '00000007-0000-3512-2118-0009af100700';
  static const String charUserSettings  = '00000008-0000-3512-2118-0009af100700';

  // ---- Characteristics under FEE1 ----
  /// The authentication characteristic (read / write / write-without-response + notify).
  static const String charAuth            = '00000009-0000-3512-2118-0009af100700';
  /// Chunked transfer (used for larger payloads / firmware / workout).
  static const String charChunkedTransfer = '00000020-0000-3512-2118-0009af100700';

  // ---- Standard GATT ----
  static const String charCurrentTime   = '00002a2b-0000-1000-8000-00805f9b34fb';
  static const String charHeartRateMeas = '00002a37-0000-1000-8000-00805f9b34fb';
  static const String charHeartRateCtrl = '00002a39-0000-1000-8000-00805f9b34fb';

  // ---- Auth protocol constants ----
  /// Every device notification on the auth char starts with this byte.
  static const int authResponse = 0x10;
  /// Status byte meaning "success".
  static const int authSuccess = 0x01;
  /// Status byte meaning "authentication failed".
  static const int authFail = 0x02;

  /// Step 1: send the secret key.
  static const int authSendKey = 0x01;
  /// Step 2: request a random number from the band.
  static const int authRequestRandom = 0x02;
  /// Step 3: send the encrypted random number back.
  static const int authSendEncrypted = 0x03;

  /// "Auth flags" byte. Gadgetbridge's AUTH_BYTE = 0x08.
  static const int authByte = 0x08;
}
