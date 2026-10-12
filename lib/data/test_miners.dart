import '../services/leaderboard_service.dart';

/// Seed miners so the board looks global even when Firebase is quiet.
class TestMiners {
  TestMiners._();

  static const asia = 'asia';
  static const europe = 'europe';
  static const americas = 'americas';
  static const africa = 'africa';
  static const oceania = 'oceania';
  static const middleEast = 'middle_east';

  static List<GlobalLeaderboardEntry> get all => [
        // ── Asia ──────────────────────────────────────────────────────────
        _m('bot_jp_hiroshi', 'Hiroshi Tanaka', '🇯🇵', asia, 1.842, 0.00041, 18),
        _m('bot_cn_mei', 'Mei Lin', '🇨🇳', asia, 1.610, 0.00036, 16),
        _m('bot_kr_minjun', 'Min-jun Park', '🇰🇷', asia, 1.275, 0.00031, 14),
        _m('bot_jp_yuki', 'Yuki Sato', '🇯🇵', asia, 0.940, 0.00022, 11),
        _m('bot_cn_wei', 'Wei Chen', '🇨🇳', asia, 0.815, 0.00019, 10),
        _m('bot_in_priya', 'Priya Sharma', '🇮🇳', asia, 0.702, 0.00017, 9),
        _m('bot_in_arjun', 'Arjun Patel', '🇮🇳', asia, 0.558, 0.00015, 8),
        _m('bot_vn_nguyen', 'Nguyen Tran', '🇻🇳', asia, 0.421, 0.00012, 7),
        _m('bot_id_putri', 'Putri Wulandari', '🇮🇩', asia, 0.336, 0.00010, 6),
        _m('bot_th_somchai', 'Somchai Prasert', '🇹🇭', asia, 0.248, 0.00008, 5),
        _m('bot_my_aisha', 'Aisha Rahman', '🇲🇾', asia, 0.187, 0.00007, 4),
        _m('bot_ph_miguel', 'Miguel Santos', '🇵🇭', asia, 0.142, 0.00006, 4),
        _m('bot_sg_kai', 'Kai Tan', '🇸🇬', asia, 0.980, 0.00024, 12),
        _m('bot_jp_kenji', 'Kenji Nakamura', '🇯🇵', asia, 0.465, 0.00013, 7),
        // ── Europe ────────────────────────────────────────────────────────
        _m('bot_de_lukas', 'Lukas Müller', '🇩🇪', europe, 1.720, 0.00038, 17),
        _m('bot_it_sofia', 'Sofia Rossi', '🇮🇹', europe, 1.355, 0.00033, 15),
        _m('bot_fr_pierre', 'Pierre Dubois', '🇫🇷', europe, 1.118, 0.00027, 13),
        _m('bot_pl_anna', 'Anna Kowalska', '🇵🇱', europe, 0.874, 0.00021, 11),
        _m('bot_gb_james', 'James Walker', '🇬🇧', europe, 0.763, 0.00018, 10),
        _m('bot_se_ingrid', 'Ingrid Berg', '🇸🇪', europe, 0.641, 0.00016, 9),
        _m('bot_no_henrik', 'Henrik Larsen', '🇳🇴', europe, 0.512, 0.00014, 8),
        _m('bot_es_lucia', 'Lucía García', '🇪🇸', europe, 0.398, 0.00011, 7),
        _m('bot_nl_daan', 'Daan Visser', '🇳🇱', europe, 0.311, 0.00009, 6),
        _m('bot_gr_nikos', 'Nikos Papadopoulos', '🇬🇷', europe, 0.226, 0.00008, 5),
        _m('bot_pt_tomas', 'Tomás Silva', '🇵🇹', europe, 0.174, 0.00006, 4),
        _m('bot_ie_aoife', 'Aoife Byrne', '🇮🇪', europe, 0.129, 0.00005, 3),
        _m('bot_cz_petra', 'Petra Novák', '🇨🇿', europe, 0.291, 0.00009, 6),
        _m('bot_ro_andrei', 'Andrei Popescu', '🇷🇴', europe, 0.205, 0.00007, 5),
        // ── Americas ──────────────────────────────────────────────────────
        _m('bot_us_jordan', 'Jordan Hale', '🇺🇸', americas, 1.490, 0.00034, 15),
        _m('bot_mx_carlos', 'Carlos Mendoza', '🇲🇽', americas, 0.886, 0.00020, 10),
        _m('bot_br_sofia', 'Sofia Alves', '🇧🇷', americas, 0.674, 0.00016, 9),
        _m('bot_ca_emma', 'Emma Roy', '🇨🇦', americas, 0.533, 0.00014, 8),
        _m('bot_ar_mateo', 'Mateo Fernández', '🇦🇷', americas, 0.318, 0.00010, 6),
        _m('bot_co_camila', 'Camila Restrepo', '🇨🇴', americas, 0.211, 0.00007, 5),
        // ── Africa ────────────────────────────────────────────────────────
        _m('bot_ng_amara', 'Amara Okafor', '🇳🇬', africa, 0.905, 0.00021, 11),
        _m('bot_gh_kwame', 'Kwame Boateng', '🇬🇭', africa, 0.447, 0.00012, 7),
        _m('bot_ke_zuri', 'Zuri Mwangi', '🇰🇪', africa, 0.268, 0.00008, 5),
        _m('bot_za_thabo', 'Thabo Nkosi', '🇿🇦', africa, 0.359, 0.00011, 6),
        _m('bot_sn_amina', 'Amina Diallo', '🇸🇳', africa, 0.163, 0.00006, 4),
        // ── Middle East ───────────────────────────────────────────────────
        _m('bot_ae_omar', 'Omar Hassan', '🇦🇪', middleEast, 1.040, 0.00025, 12),
        _m('bot_eg_yasmin', 'Yasmin Farouk', '🇪🇬', middleEast, 0.492, 0.00013, 8),
        _m('bot_tr_elif', 'Elif Yılmaz', '🇹🇷', middleEast, 0.377, 0.00011, 7),
        // ── Oceania ───────────────────────────────────────────────────────
        _m('bot_au_liam', 'Liam Crowe', '🇦🇺', oceania, 0.728, 0.00017, 9),
        _m('bot_nz_hana', 'Hana Reid', '🇳🇿', oceania, 0.284, 0.00009, 6),
      ];

  static GlobalLeaderboardEntry _m(
    String uid,
    String name,
    String flag,
    String region,
    double totalMined,
    double hashRate,
    int farmSize,
  ) =>
      GlobalLeaderboardEntry(
        uid: uid,
        name: name,
        totalMined: totalMined,
        hashRate: hashRate,
        farmSize: farmSize,
        region: region,
        flag: flag,
      );

  static String regionFromCountryCode(String? code) {
    final cc = (code ?? '').toUpperCase();
    const asia = {
      'CN', 'JP', 'KR', 'IN', 'ID', 'VN', 'TH', 'MY', 'PH', 'SG', 'PK', 'BD',
      'TW', 'HK', 'MO', 'MN', 'KH', 'LA', 'MM', 'NP', 'LK', 'BT', 'BN',
    };
    const europe = {
      'GB', 'DE', 'FR', 'IT', 'ES', 'PL', 'NL', 'SE', 'NO', 'DK', 'FI', 'PT',
      'GR', 'RO', 'HU', 'CZ', 'AT', 'BE', 'IE', 'CH', 'UA', 'RU', 'SK', 'BG',
      'HR', 'SI', 'LT', 'LV', 'EE', 'IS', 'LU', 'RS', 'BA', 'MK', 'AL', 'MD',
    };
    const americas = {
      'US', 'CA', 'MX', 'BR', 'AR', 'CO', 'CL', 'PE', 'VE', 'EC', 'UY', 'PY',
      'BO', 'CR', 'PA', 'GT', 'HN', 'SV', 'NI', 'DO', 'CU', 'PR', 'JM',
    };
    const africa = {
      'NG', 'GH', 'KE', 'ZA', 'EG', 'MA', 'SN', 'ET', 'TZ', 'UG', 'CI', 'CM',
      'AO', 'MZ', 'ZW', 'RW', 'TN', 'DZ',
    };
    const oceania = {'AU', 'NZ', 'FJ', 'PG', 'WS', 'TO'};
    const middleEast = {'AE', 'SA', 'QA', 'KW', 'BH', 'OM', 'JO', 'LB', 'IQ', 'IR', 'IL', 'TR', 'YE'};
    if (asia.contains(cc)) return TestMiners.asia;
    if (europe.contains(cc)) return TestMiners.europe;
    if (americas.contains(cc)) return TestMiners.americas;
    if (africa.contains(cc)) return TestMiners.africa;
    if (oceania.contains(cc)) return TestMiners.oceania;
    if (middleEast.contains(cc)) return TestMiners.middleEast;
    return 'all';
  }
}
