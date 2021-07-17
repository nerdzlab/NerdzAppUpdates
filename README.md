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
To install `AppStoreVersionProvider` use `provider/appstore` branch.
To install `BackendVersionProvider` use `provider/backend` branch.
To install `FirebaseVersionProvider` use `provider/firebase` branch.

## Use examples
Example of use `AppStoreVersionProvider` with custom loading indication.

```
import NerdzAppUpdates // Line 1
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    private lazy var versionVerifyer: VersionVerifier =  { // Line 2
    
        let provider = AppStoreVersionProvider(country: .germany) // Line 3
    
        let verifier = VersionVerifier(
            versionDataProvider: provider,
            loadingIndicationMode: .screen(LoaderScreen()), // Line 4
            softUpdateMode: .screen(SoftUpdateScreen(), true), // Line 5
            hardUpdateMode: .screen(HardUpdateScreen()) // Line 6
        )
        
        return verifier
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
        verifyVersion() // Line 7
        
        return true
    }
    
    private func verifyVersion() {
        versionVerifyer.verifyVersion { [weak self] result in // Line 8
            guard case .failure(let error) = result else {
                return
            }
            
            self?.showError(error.localizedDescription) // Line 9
        }
    }
}
```
Let's go through some important lines of code of above mentioned snippet.
  - Line 1 - import library
  - Line 2 - version verifier object initialization
  - Line 3 - initializition of version provider
  - Line 4 - passing custom screen for loading indication, typicaly is copy of app launch storyboard with loading indicator
  - Line 5 - passing soft update configuration, where `SoftUpdateScreen()` is screen that provides user posibility to open app distribution service,
or skip an update, and `animated` - is boolean option to animate dissapearing of screen mentioned above or not
  - Line 6 - passing hard update configuration with screen which should be displayed in case hard update is needed
  - Line 7 - calling a use defined function to trigger start of version verification
  - Line 8 - calling library function 
  - Line 9 - displaying error in case of verification check

## PAY ATTENTION. 
  1. Make sure to store reference to versionVerifier object, so this object won't be deinited before the version check is completed.
  2. In case you're using `AppStoreVersionProvider`, please specify country in version provider initializer. You can see list of available countries in [AppStoreCountry file](https://github.com/nerdzlab/NerdzAppUpdates/blob/provider/appstore/Sources/NerdzAppUpdates/VersionProviders/AppStore/AppStoreCountry.swift).
