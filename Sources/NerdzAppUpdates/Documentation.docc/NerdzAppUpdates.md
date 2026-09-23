# ``NerdzAppUpdates``

Check whether the installed app version is up to date and prompt for soft or hard updates.

## Overview

NerdzAppUpdates verifies the installed version against a distribution service using one or more providers, then presents a soft update (skippable) or a hard update (blocking).

The library ships two built in providers, ``AppStoreVersionProvider`` (compares the installed version against the public iTunes lookup API) and ``FirebaseConfigVersionProvider`` (reads thresholds from Firebase Remote Config). You can also implement your own provider by conforming to ``VersionProviderType``.

``VersionVerifier`` accepts one or more providers, aggregates their results, and presents the highest priority outcome (hard update takes precedence over soft update, which takes precedence over no update).

## Topics

### Essentials

- <doc:GettingStarted>
- ``VersionVerifier``
- ``VersionProviderType``

### Providers

- ``AppStoreVersionProvider``
- ``FirebaseConfigVersionProvider``
- ``AppStoreCountry``

### Update Configuration

- ``LoadingIndicationMode``
- ``LoadingIndicationScreenType``
- ``SoftUpdateMode``
- ``SoftUpdateScreenType``
- ``HardUpdateMode``
- ``HardUpdateScreenType``

### Models

- ``AppUpdateType``
- ``VersionVerifierError``

### Closures

- ``AppUpdateAction``
- ``VersionProviderResult``
- ``VersionVerifierEmptyAction``
- ``VersionVerifierStringAction``
