# Come funziona l’app – BTC Mining Simulator

Questa guida descrive il flusso dell’app e come tutte le funzionalità sono collegate, per dare una sensazione reale e coerente all’utente.

---

## 1. Avvio e autenticazione

- **Route iniziale (`/`)**: se l’utente è loggato → **HomeShell** (app principale), altrimenti → **LoginScreen**.
- **Login**: tramite **AuthService** (Firebase Auth). Dopo il login si va su **HomeShell**.
- In **HomeShell** (`initState`):
  - **GameStateService** riceve `userId` e `displayName` e carica i dati (locale + Firebase).
  - Vengono caricati: **ProgressionService**, **DailyBoostService**, **LuckySpinService**, **AchievementService**, **EventService**, **RandomDropService**, **EnergyCoolingService**, **LeaderboardService**, **AdPacingService**, **AdRemoteConfigService**.
  - Dopo il caricamento della Remote Config → preload di **rewarded**, **interstitial** e **app open** (SmartAdManager).
  - Se c’è un **daily boost** da reclamare → viene mostrato il dialog “Daily Boost Ready”.
  - **IapService** viene inizializzato e `onPurchaseSuccess` viene collegato al **GameStateService** (premium, boost 1h, pacchetti one-time).

Tutto il gioco ruota attorno a **GameStateService**: salvataggio locale (SharedPreferences) + sync su Firebase (FirebaseSyncService).

---

## 2. Loop di gioco (timer 1 secondo)

In **HomeShell** un **Timer.periodic(1 secondo)** aggiorna ogni secondo:

- **GameStateService**: applica i modificatori esterni (eventi, daily boost, efficienza energia, capacità location, sconto rig) e chiama **updateTick()** (mining: BTC guadagnati in base a `totalBtcPerMin`, sessioni, ecc.).
- **EnergyCoolingService**: `tickHeat()` in base a numero rig e mining attivo.
- **ProgressionService**: `evaluateUnlocks()` (sblocchi in base a balance e hash rate).
- **AchievementService**: valutazione achievement (first miner, 10 rig, 100 ore, factory unlock) → premi BTC tramite **GameStateService.grantDirectBtc()**.

Quindi: **mining, energia, progressione e achievement sono tutti collegati al game state e aggiornati ogni secondo.**

---

## 3. Sync e leaderboard

- **Timer ogni 3 minuti**: **GameStateService.syncToCloud()** salva i dati su Firebase (se utente loggato).
- Stesso timer: **LeaderboardService.updateUser()** aggiorna la classifica con `lifetimeMinedBtc`, `totalBtcPerMin`, `ownedRigIds.length` (con throttling: almeno 10 minuti o variazione significativa di mined/hash).

I dati di gioco e la classifica restano quindi allineati nel tempo.

---

## 4. Schermate principali (tab bottom nav)

La **bottom nav** ha 5 tab: **Dashboard**, **Farm**, **Shop**, **Ranks**, **Rewards**.

- **Tap su un tab**:
  1. Cambio tab (setState `_index`).
  2. Se Remote Config lo permette: **interstitial** (se ads abilitati e pacing ok).
  3. Se è abilitato il **website redirect**: apertura **Chrome Custom Tab** con l’URL configurato.

Quindi: **navigazione → possibile interstitial → possibile apertura sito**. Nessun redirect automatico all’apertura app; il redirect avviene solo al tap sul tab.

---

## 5. Dashboard

- **Bilancio BTC**, valore in USD (BtcPriceService), **BTC/min**, boost/premium attivi.
- **Idle earnings**: se l’utente è stato assente oltre una soglia, guadagni calcolati e mostrati (poi applicati al balance).
- **Stats**: sessioni, tempo di sessione, ecc.
- **Mining session**: avvio sessione mining (bonus 1.25x per 30 min) → collegato a **GameStateService** (sessioni e mining).
- **Daily boost**: claim del boost 2× per 30 minuti → **DailyBoostService.claim()**.
- **Energy & cooling**: stato calore/efficienza → **EnergyCoolingService** (influenza moltiplicatore mining).
- **Map progression**: location sbloccate → **ProgressionService** (capacity bonus, ecc.).
- **Random drop**: se disponibile, claim drop → **RandomDropService** + **GameStateService.grantDirectBtc(bonus)**.
- **Grafico prezzo BTC** (BtcPriceService).
- **Open website**: card “Open website” se `canShowWebsiteRedirect` → **AdRemoteConfigService.openCustomTab()**.
- **Native + Banner**: se `adsActive` (Remote Config).

Tutto ciò che si fa in Dashboard (sessioni, boost, drop) modifica lo stato di gioco e/o i servizi collegati.

---

## 6. Mining Farm

- Lista **rig posseduti** (da **GameStateService.ownedRigIds**) con conteggi e capacità (farm level + **ProgressionService** per capacity bonus).
- **Acquisto rig con BTC**: **GameStateService.buyRig(rig)** (costo con sconto eventi `rigDiscount`).
- **Upgrade farm**: costo in BTC per livello successivo (**FarmTiers**), applicato al game state.
- **Native + Banner** se ads attivi.

Farm e Shop sono le due fonti di “potenza mining”: rig comprati in Farm (BTC) o da Shop (BTC/IAP).

---

## 7. Shop

- **Rig acquistabili con BTC**: stessi rig del gioco → **GameStateService.buyRig(rig)**.
- **Prodotti one-time (IAP)**: starter pack, satoshi pack, mega pack, boost 2× 1h. Acquisto tramite **IapService**; callback **onPurchaseSuccess** in HomeShell applica:
  - **activateBoost1h()** per `boost_2x_1h`,
  - **applyOneTimePurchase()** per gli altri (BTC, rig, moltiplicatori mining).
- **Abbonamenti**: premium monthly/yearly → **activatePremium()** (moltiplicatore 1.5×, senza cap giornaliero sessioni).
- **Stato “purchased”**: da **GameStateService.hasPurchasedOneTime()** / Firebase.

Shop e IAP sono quindi collegati al game state e a Firebase (acquisti e abbonamenti).

---

## 8. Leaderboard (Ranks)

- Lista caricata da **LeaderboardService** (Firestore `leaderboard`); cache locale.
- Ordinamento per `totalMined` (o campo configurato).
- I dati dell’utente vengono aggiornati dal timer in HomeShell (vedi §3).

La classifica riflette i dati reali di mining e farm.

---

## 9. Rewards

- **Daily reward (7 giorni)**:
  - **GameStateService.canClaimDaily** / **nextDailyStreakDay**.
  - Tap “Claim Day X” → **GameStateService.claimDaily()** (BTC + eventuale rig al giorno 3 e 7).
- **Lucky Spin**:
  - **LuckySpinService.canSpin** (cooldown 24h).
  - Tap “Spin!” → **Navigator.pushNamed('/lucky-spin')** → **LuckySpinScreen**.
- **Lucky Spin Screen**:
  - Se ads abilitati → **interstitial**.
  - **LuckySpinService.spin()** → risultato (BTC / rig / boost).
  - Animazione ruota → alla fine **grantDirectBtc / grantRig / activateBoost** e dialog “You won!” → pop.
- **Reward da annuncio** (es. “Watch ad for BTC”): **SmartAdManager** rewarded → **GameStateService.grantDirectBtc()** (o altro reward).
- **Milestones**: claim in base a sessioni, BTC lifetime, ecc. → **GameStateService** (grant BTC, rig, boost) e **claimedMilestones**.
- **Open website**: stesso flusso della Remote Config (azione sul bottone, non automatica).
- **Native + Banner** se ads attivi.

Rewards (daily, spin, ads, milestones) sono tutti collegati a **GameStateService** e/o **LuckySpinService**.

---

## 10. Profile

- Dati utente (AuthService).
- Logout → ritorno a Login.
- Sync manuale / stato sync / errori (GameStateService, Firebase).
- (In dev) pulsanti “Grant BTC”, “Grant rig”, “Activate boost” → **GameStateService** per test.

---

## 11. Annunci e Remote Config

- **AdRemoteConfigService**: parametri da Firebase (o default locale):  
  `ads_enabled`, `use_custom_tab`, `custom_tab_url`, ad unit IDs.
- **SmartAdManager**: preload sempre; **mostra** interstitial/rewarded/app open solo se **ads_enabled** / **ads_active**.
- **AdPacingService**: nessun cap giornaliero; **shouldShowInterstitial** = sempre true (tentativo interstitial a ogni tap tab).
- Interstitial: tab bottom nav + Lucky Spin (prima dello spin).
- App open: in **didChangeAppLifecycleState(resumed)** se condizioni rispettate.
- Custom tab: solo su azione utente (tab o pulsante “Open website”), mai in automatico all’avvio.

Tutti i punti in cui compaiono annunci o il sito sono controllati dalla stessa config e dagli stessi servizi.

---

## 12. Riepilogo connessioni

| Funzionalità            | Servizi / schermate coinvolti |
|-------------------------|--------------------------------|
| Mining nel tempo        | GameStateService, timer 1s, MiningEngine (moltiplicatori) |
| Salvataggio / sync      | GameStateService, FirebaseSyncService, timer 3 min |
| Leaderboard             | LeaderboardService, GameStateService (updateUser dal timer) |
| Acquisto rig (BTC)      | Mining Farm + Shop → GameStateService.buyRig |
| IAP / premium           | Shop, IapService, HomeShell.onPurchaseSuccess, GameStateService |
| Daily reward            | Rewards → GameStateService.claimDaily |
| Lucky spin              | Rewards → /lucky-spin → LuckySpinService + GameStateService |
| Daily boost             | Dashboard → DailyBoostService.claim |
| Mining session          | Dashboard → GameStateService (sessioni) |
| Eventi / sconti         | EventService → applyExternalGameplayModifiers |
| Energia / raffreddamento| EnergyCoolingService → efficienza → modificatori |
| Progressione / mappa    | ProgressionService → capacity, unlock |
| Achievement             | HomeShell timer → AchievementService + grantDirectBtc |
| Random drop             | Dashboard → RandomDropService + grantDirectBtc |
| Annunci                 | AdRemoteConfigService, SmartAdManager, AdPacingService |
| Apertura sito           | AdRemoteConfigService.openCustomTab (solo su tap) |

---

## Conclusione

L’app è strutturata così che:

1. **Un solo stato di gioco** (GameStateService) sia la fonte di verità per balance, rig, boost, premium, daily, milestone.
2. **Timer e sync** aggiornano mining, energia, progressione, achievement e leaderboard in modo coerente.
3. **Dashboard, Farm, Shop, Rewards e Profile** leggono/scrivono sempre attraverso i servizi (game state, IAP, Firebase, ads).
4. **Lucky Spin** è integrato: da Rewards si apre la schermata ruota, si vede l’interstitial, si esegue lo spin e i premi vengono applicati al game state.
5. **Annunci e redirect** sono controllati da Remote Config e mostrati solo dove previsto (tab, lucky spin, “Open website”), senza redirect automatico all’avvio.

In questo modo l’utente ha un’esperienza coerente: ogni azione (mining, acquisti, reward, spin, boost, sessioni) si riflette sullo stato di gioco e, quando previsto, su Firebase e sulla classifica.
