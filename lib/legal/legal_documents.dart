class LegalSection {
  final String heading;
  final String body;

  const LegalSection(this.heading, this.body);
}

/// In-app Privacy Policy and Terms for Solana Mining Tycoon.
class LegalDocuments {
  LegalDocuments._();

  static const lastUpdated = 'October 12, 2026';
  static const appName = 'Solana Mining Tycoon';
  static const packageName = 'com.crypto.blockchain.mining.tycoon';

  static const List<LegalSection> privacy = [
    LegalSection(
      '1. Who we are',
      'This Privacy Policy explains how $appName (“the App”, “we”, “us”) collects, uses, and shares information when you use the App on Android or iOS. The App is an entertainment product: an idle mining simulation themed around Solana. It is not a cryptocurrency exchange, wallet, or financial service.',
    ),
    LegalSection(
      '2. Information we collect',
      'Account: If you sign in with Google, we receive your Firebase user ID, display name, and email from Google Sign-In. If you continue as a guest, Firebase creates an anonymous user ID.\n\n'
          'Gameplay: Mining progress, balances of in-game SOL, owned rigs, referrals, rewards, streaks, and similar save data so your farm can be restored on this or another device.\n\n'
          'Purchases: Google Play order IDs, product IDs, and purchase tokens when you buy coins, boosts, or premium — so we can deliver and restore items.\n\n'
          'Device & ads: Advertising ID (where allowed), approximate device info, crash logs, and ad interaction data used by Google Mobile Ads / AdMob (and similar partners) to show and measure ads.\n\n'
          'Analytics & messaging: App opens, screen views, and campaign events via Firebase Analytics / Cloud Messaging and, if configured, Meta App Events. Push tokens are stored so we can send optional reminders (for example mining complete).',
    ),
    LegalSection(
      '3. How we use information',
      'We use this information to: run the App and sync your save; create and look up your referral code; process in-app purchases; show ads (unless you have premium); measure performance and fix bugs; send optional notifications you can disable in system settings; and comply with store and legal requirements.',
    ),
    LegalSection(
      '4. Legal bases (EEA/UK)',
      'Where GDPR/UK GDPR applies, we process data to perform the service you request (account, saves, purchases), with your consent (optional analytics/ads/notifications where required), and for our legitimate interests in keeping the App secure, fair, and working.',
    ),
    LegalSection(
      '5. Sharing',
      'We share data with processors who help us run the App: Google (Firebase, Google Sign-In, Play Billing, AdMob), and Meta if App Events are enabled. They process data under their own terms. We do not sell your personal information. We may disclose information if required by law or to protect users and the App.',
    ),
    LegalSection(
      '6. Ads and tracking',
      'The free version shows banner, interstitial, rewarded, and similar ads. Ad partners may use cookies or advertising IDs to personalize or measure ads. You can limit ad tracking in your device settings (for example Android “Delete advertising ID” / App ads, or iOS Tracking permission). Premium may remove ads where stated in the offer.',
    ),
    LegalSection(
      '7. Retention',
      'We keep account and save data while your account exists and for a reasonable period afterward so you can restore progress. You may sign out at any time. Guest progress is tied to this device’s anonymous ID and may be lost if you uninstall or reset the App without linking Google.',
    ),
    LegalSection(
      '8. Children',
      'The App is not directed at children under 13 (or the minimum age in your country). We do not knowingly collect personal information from children. If you believe a child has used the App, contact us via the Play Store listing and we will delete the data.',
    ),
    LegalSection(
      '9. Your rights',
      'Depending on your country, you may have rights to access, correct, delete, or export your data, or to object to certain processing. Sign-out is available in Profile. For deletion of cloud saves and account data, contact us through the Google Play listing for $appName ($packageName).',
    ),
    LegalSection(
      '10. International transfers',
      'Firebase and advertising partners may process data on servers outside your country (including the United States). We rely on appropriate safeguards offered by those providers.',
    ),
    LegalSection(
      '11. Changes',
      'We may update this policy. The “Last updated” date at the top of this screen will change. Continued use after an update means you accept the revised policy.',
    ),
    LegalSection(
      '12. Contact',
      'Questions about privacy: use the support / contact option on the $appName Google Play listing (package $packageName).',
    ),
  ];

  static const List<LegalSection> terms = [
    LegalSection(
      '1. Agreement',
      'These Terms & Conditions govern your use of $appName. By downloading, signing in, or tapping Continue as guest, you agree to these Terms and to the Privacy Policy. If you do not agree, do not use the App.',
    ),
    LegalSection(
      '2. The App is entertainment',
      '$appName is a simulation / idle game. In-game “SOL”, mining output, validators, farms, leaderboards, and withdrawals are virtual game features for entertainment. Nothing in the App is real cryptocurrency, financial advice, an investment product, or a promise of real-world profit. Market prices shown (if any) are for flavour and may be delayed or inaccurate.',
    ),
    LegalSection(
      '3. Accounts',
      'You may sign in with Google or continue as a guest. You are responsible for activity on your account. Guest (anonymous) progress stays on this device until you link Google. We may suspend accounts that cheat, abuse referrals, or interfere with other players.',
    ),
    LegalSection(
      '4. Virtual items and SOL',
      'In-game currency, rigs, boosts, spins, and similar items have no cash value outside the App unless we expressly complete a verified withdrawal. We may change rates, economy values, or features at any time to keep the game fair. Virtual items are licensed to you, not sold, and are not transferable except as the App allows (for example referral bonuses).',
    ),
    LegalSection(
      '5. In-app purchases',
      'Optional purchases and subscriptions are billed by Google Play (or Apple) under their payment terms. Prices are shown in the store. We deliver the matching in-game item after the store confirms the purchase. Refunds are handled by the platform (Google Play / App Store), not by the App directly. Restore purchases from the same store account if you reinstall.',
    ),
    LegalSection(
      '6. Ads, premium, and energy',
      'The free App may show ads, including rewarded ads you choose to watch for extra energy or rewards. Frequency is paced so the game stays playable. Premium, if purchased, removes or reduces ads as described on the offer screen for the length of the entitlement.',
    ),
    LegalSection(
      '7. Referrals',
      'Your referral code is derived from your Firebase user ID (last or first 6 digits) when you are signed in, or a random code if you are a guest. Codes and friend lists are stored in Firebase so bonuses can be granted. You may not buy, sell, or farm referrals, use fake accounts, or mislead others. We may withhold referral rewards in cases of abuse.',
    ),
    LegalSection(
      '8. Withdrawals',
      'If the App offers a withdrawal feature, it is subject to eligibility tasks, a minimum balance (currently described in Profile as a USD-equivalent threshold), review, and applicable law. We may require identity or wallet verification. We may refuse, delay, or reverse withdrawals that look fraudulent, automated, or in violation of these Terms. Completion is not guaranteed.',
    ),
    LegalSection(
      '9. Acceptable use',
      'You agree not to: reverse engineer or cheat (bots, modified clients, exploits); attack our services; scrape other users’ data; use the App for anything unlawful; or impersonate us. We may ban devices or accounts and reset unfairly obtained items.',
    ),
    LegalSection(
      '10. Intellectual property',
      'The App, art, UI, and Solana-themed presentation (except third-party marks) are owned by us or licensed to us. Solana, SOL, and related marks belong to their owners. We are not affiliated with, endorsed by, or a partner of the Solana Foundation or Solana Labs unless we say so in writing.',
    ),
    LegalSection(
      '11. Disclaimer',
      'THE APP IS PROVIDED “AS IS”. We do not warrant uninterrupted service, accurate prices, or that mining or withdrawals will produce any real-world value. To the fullest extent allowed by law, we disclaim implied warranties of merchantability, fitness, and non-infringement.',
    ),
    LegalSection(
      '12. Limitation of liability',
      'To the fullest extent allowed by law, we are not liable for lost profits, lost data, or indirect damages arising from the App. Our total liability for any claim relating to the App is limited to the amount you paid us for the App in the 12 months before the claim (or USD 10 if you paid nothing). Some jurisdictions do not allow certain limits; in those places, our liability is limited to the maximum permitted.',
    ),
    LegalSection(
      '13. Termination',
      'You may stop using the App and sign out at any time. We may stop offering the App or close accounts that violate these Terms. Unused virtual items have no refund value except where the platform requires it.',
    ),
    LegalSection(
      '14. Changes',
      'We may update these Terms. The “Last updated” date on this screen will change. If you continue to use the App after an update, you accept the new Terms.',
    ),
    LegalSection(
      '15. Contact',
      'Support: Google Play listing for $appName (package $packageName).',
    ),
  ];
}
