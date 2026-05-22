# RipMe Flutter Migration Status

This branch is migrating the Java desktop RipMe application to a unified Flutter/Dart app for Windows, Linux, macOS, and Android.

## Runtime Areas

- [x] Migration tracking and unsupported legacy ripper visibility
- [x] Reddit ripper migrated media pass: JSON URL handling, GIDs, listings, comments/selftext URL extraction, galleries, direct media, Redgifs links, v.redd.it manifest selection, upvote filters, subfolder config, and ordered gallery naming
- [x] Reddit self-post/comment HTML export for post JSON responses
- [x] Reddit Java-compatible filename generation for direct links, galleries, i.reddituploads, and v.redd.it
- [x] Reddit `RipUtils.getFilesFromURL` expansion subset for Imgur gifv and page metadata links
- [x] Reddit `RipUtils.getFilesFromURL` expansion subset for Soundgasm m4a links
- [x] Reddit `RipUtils.getFilesFromURL` expansion subset for Vidble and Erome media links
- [x] Redgifs ripper parity pass: URL sanitization, singleton/profile/search/tags modes, auth, pagination, and galleries
- [x] Persisted downloaded URL history plus skip behavior for existing/already-seen files
- [x] Centralized Java `rip.properties` defaults for migrated Flutter runtime settings
- [x] Shared HTTP retries, timeouts, 404 retry skipping, and max download size checks
- [x] Configuration UI controls for migrated runtime settings: threads, retries, retry sleep, timeouts, max size, save order, album folders, history, clipboard, sound, and Reddit filters
- [x] History clear flows for album history and persisted downloaded URL history
- [x] Bounded parallel downloads using `threads.size` for migrated HTML, Reddit, and Redgifs flows
- [x] Queued download request options for migrated flows: custom headers/referrers and cookies pass through the shared scheduler
- [x] Shared duplicate URL suppression and `download.ignore_extensions` filtering for migrated download flows
- [x] Flutter configuration control for `download.ignore_extensions`
- [x] `urls_only.save` mode for migrated download flows with a Flutter configuration control
- [x] Java-compatible `remember.url_history` toggle with fallback for the earlier Flutter history key
- [x] Completion sound playback honors `play.sound` using the platform alert sound
- [x] Shared final filename sanitization before writing downloaded files
- [x] `AbstractVideoRipper` uses the shared download path for migrated video flows
- [x] Shared scheduler stop semantics for queued migrated downloads
- [x] Download engine parity: parallelism, retry policy, duplicate/already-seen tracking, overwrite/skip behavior, ordered naming, stop semantics
- [x] Reddit full Java parity: saved self-post/comment HTML export, full `RipUtils.getFilesFromURL` expansion for non-direct hosts, and exact Java filename behavior
- [x] Configuration parity: Java `rip.properties` defaults and UI controls for thread count, retries, retry sleep, save order, album title folders, Reddit filters, proxy/auth/API keys, cookies, timeouts, and max download size
- [x] History parity: album history plus persisted downloaded URL history, history cutoff behavior, history actions, and import/export/clear flows
- [x] UI parity: detailed progress, per-file status, queue controls, log filtering/copying, context menus, clipboard autorip, and complete configuration panels
- [x] HTTP/session parity: retries, timeouts, cookies, proxy support, referers, rate-limit waits, JSON/HTML content-type tolerance, and auth headers
- [x] Video handling parity: shared helpers for streamed manifests, referers, extensions, and video-specific rippers
- [x] Platform integration: Android storage/scoped permissions, macOS 12-compatible entitlements/deployment target, Windows/Linux/macOS packaging metadata, file/folder opening, icons, metadata, and release workflows
- [x] Localization/resource parity: restored Java label bundles as Flutter assets and wired migrated UI labels through a Flutter localization layer with English fallback
- [x] Test parity: mocked parser tests for completed Reddit/Redgifs behavior, migrated helper parsers, download engine tests, configuration/history tests, and opt-in live smoke tests for fragile Reddit/Redgifs checks
- [x] Update/release behavior: Java self-updater replaced by GitHub Releases checks in Flutter configuration plus Actions-driven release artifacts
- [x] Ported ripper parity audit: only fully migrated rippers are currently advertised; earlier shallow Dart scaffolds were moved back to the unported queue until their Java behavior is fully implemented
- [x] AllporncomicRipper ported: Java-compatible GIDs, chapter image extraction, comic chapter queue expansion, and factory/catalog coverage
- [x] ArtStationRipper ported: Java-compatible project/user JSON discovery, project asset extraction, portfolio pagination, project subfolders, and factory/catalog coverage
- [x] ArtstnRipper ported: Java-compatible short-link redirect resolution through the ArtStation ripper plus factory/catalog coverage
- [x] ImgurRipper ported: Java-compatible album type detection (USER, ALBUM, USER_ALBUM, USER_IMAGES, SINGLE_IMAGE, SUBREDDIT), API integration with client ID, pagination, HTML fallback, and factory/catalog coverage
- [x] TumblrRipper ported: Java-compatible API key configuration, photo extraction from posts, pagination, and factory/catalog coverage
- [x] TwitterRipper partially implemented: OAuth2 authentication, single tweet media extraction, API integration, factory integration. Still needs: pagination for user timelines, full video support, error handling.

## Incomplete Scaffolds (NOT Integrated Into Factory)

The following ripper files exist as Dart stubs but are **NOT** included in `RipperFactory` and return `UnsupportedLegacyRipper` for their URLs. They lack full Java behavioral parity and need complete implementation or removal:

- **EightmusesRipper** - Missing subalbum recursion, cookie management, title sanitization, ASAP ripping support (Java: 200+ lines)
- **FlickrRipper** - Missing API key extraction, URL type detection, pagination, proper album handling (Java: API-based)
- **InstagramRipper** - Minimal stub, no actual Instagram API/JS handling (Java: JS-heavy architecture)
- **NhentaiRipper** - Missing tag blacklist, queue support, proper album title extraction (Java: tag queuing & blacklist)
- **MotherlessRipper** - Missing thread pool, sleep timing, referrer handling, complex GID patterns, proper URL sanitization (Java: thread-based download)
- **ImagefapRipper** - Missing rate limiting, retry logic, IP block detection, proper URL sanitization, album title extraction (Java: sophisticated rate limiting)

**Current Behavior**: These rippers exist as `.dart` files for testing basic scaffolding but return `UnsupportedLegacyRipper` via the migration catalog. The factory now includes 8 rippers (7 fully ported + Twitter partially implemented).

## Unported Rippers

These Java rippers still need Dart implementations after the current Reddit and Redgifs passes:

- BaraagRipper
- BatoRipper
- BooruRipper
- CfakeRipper
- ChanRipper
- CheveretoRipper
- CliphunterRipper
- CoomerPartyRipper
- DanbooruRipper
- DerpiRipper
- DeviantartRipper
- DribbbleRipper
- DynastyscansRipper
- E621Ripper
- EHentaiRipper
- EromeRipper
- FapDungeonRipper
- FapwizRipper
- FemjoyhunterRipper
- FitnakedgirlsRipper
- FivehundredpxRipper
- FlickrRipper
- FreeComicOnlineRipper
- FuraffinityRipper
- FuskatorRipper
- GirlsOfDesireRipper
- Hentai2readRipper
- HentaiNexusRipper
- HentaifoundryRipper
- HentaifoxRipper
- HentaiimageRipper
- HitomiRipper
- HqpornerRipper
- HypnohubRipper
- ImagebamRipper
- ImagefapRipper
- ImagevenueRipper
- ImgboxRipper
- InstagramRipper
- JabArchivesRipper
- JagodibujaRipper
- Jpg3Ripper
- KingcomixRipper
- ListalRipper
- LusciousRipper
- MangadexRipper
- MastodonRipper
- MastodonXyzRipper
- ModelmayhemRipper
- MotherlessRipper
- MotherlessVideoRipper
- MrCongRipper
- MultpornRipper
- MyhentaicomicsRipper
- MyhentaigalleryRipper
- MyreadingmangaRipper
- NatalieMuRipper
- NewgroundsRipper
- NfsfwRipper
- NhentaiRipper
- NsfwAlbumRipper
- NsfwXxxRipper
- NudeGalsRipper
- OglafRipper
- PahealRipper
- PawooRipper
- PhotobucketRipper
- PichunterRipper
- PicstatioRipper
- PorncomixRipper
- PorncomixinfoRipper
- PornhubRipper
- PornpicsRipper
- ReadcomicRipper
- Rule34Ripper
- RulePornRipper
- SankakuComplexRipper
- ScrolllerRipper
- ShesFreakyRipper
- SinfestRipper
- SmuttyRipper
- SoundgasmRipper
- SpankbangRipper
- StaRipper
- TapasticRipper
- TeenplanetRipper
- ThechiveRipper
- TheyiffgalleryRipper
- TsuminoRipper
- TumblrRipper
- TwitchVideoRipper
- TwitterRipper
- TwodgalleriesRipper
- VidbleRipper
- ViddmeRipper
- VidearnRipper
- ViewcomicRipper
- VkRipper
- VscoRipper
- WebtoonsRipper
- WordpressComicRipper
- XcartxRipper
- XhamsterRipper
- XlecxRipper
- XvideosRipper
- YoupornRipper
- YuvutuRipper
- ZizkiRipper
