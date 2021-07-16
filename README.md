# NerdzAppUpdates

## About
NerdzAppUpdates is library that provide user posibility to check if currently installed version is up to date with distribution service.

Library supports two types of updates hard updates, and soft updates.

App supports multiple types of version providers:
  - `AppStoreVersionProvider` - that uses Itunes lookup api, to retreive current AppStore version of the app and than perform version check.
  - `BackendVersionProvider` - that provides ability for user to retreive current required and recommended versions of the app from your server.
  - `FirebaseVersionProvider` - that uses Firebase remote config to retreive current required and recommended versions of the app.

`AppStoreVersionProvider` is build to work with [Semantic Versioning](https://semver.org/) system.
Hard update is triggered when app major number is different. For example, `1.0.0` - installed version and `2.0.0` - store provided.
Soft update is triggered when app minor number is diffent. For example, `0.2.0` - installed version and `0.3.0` - store provided.
When using `BackendVersionProvider` and `FirebaseVersionProvider` you can set required and recommendd version on your server by your own.

## Instalation
You can install this library using Swift Package Manager.
To install `AppStorVersionProvider` use `provider/appstore` branch.
To install `BackendVersionProvider` use `provider/backend` or `master` branch.
To install `FirebaseVersionProvider` use `provider/firebase` branch.

## Use examples
