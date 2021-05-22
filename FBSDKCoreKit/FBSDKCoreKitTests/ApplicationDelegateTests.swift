// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit
import XCTest

class ApplicationDelegateTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional weak_delegate
  var delegate: ApplicationDelegate!
  var center = TestNotificationCenter()
  var featureChecker = TestFeatureManager()
  var appEvents = TestAppEvents()

  override class func setUp() {
    super.setUp()

    TestAccessTokenWallet.reset()
    TestSettings.reset()
    TestGateKeeperManager.reset()
    TestServerConfigurationProvider.reset()
  }

  override func setUp() {
    super.setUp()

    ApplicationDelegate.reset()
    delegate = ApplicationDelegate(
      notificationObserver: center,
      tokenWallet: TestAccessTokenWallet.self,
      settings: TestSettings.self,
      featureChecker: featureChecker,
      appEvents: appEvents,
      serverConfigurationProvider: TestServerConfigurationProvider.self
    )
  }

  override func tearDown() {
    super.tearDown()

    TestAccessTokenWallet.reset()
    TestSettings.reset()
    TestGateKeeperManager.reset()
    TestServerConfigurationProvider.reset()
  }

  func testDefaultDependencies() {
    XCTAssertEqual(
      ApplicationDelegate.shared.notificationObserver as? NotificationCenter,
      NotificationCenter.default,
      "Should use the default system notification center"
    )
    XCTAssertTrue(
      ApplicationDelegate.shared.tokenWallet is AccessToken.Type,
      "Should use the expected default access token setter"
    )
    XCTAssertEqual(
      ApplicationDelegate.shared.featureChecker as? FeatureManager,
      FeatureManager.shared,
      "Should use the default feature checker"
    )
    XCTAssertEqual(
      ApplicationDelegate.shared.appEvents as? AppEvents,
      AppEvents.singleton,
      "Should use the expected default app events instance"
    )
    XCTAssertTrue(
      ApplicationDelegate.shared.serverConfigurationProvider is ServerConfigurationManager.Type,
      "Should use the expected default server configuration provider"
    )
  }

  func testCreatingWithDependencies() {
    XCTAssertTrue(
      delegate.notificationObserver is TestNotificationCenter,
      "Should be able to create with a custom notification center"
    )
    XCTAssertTrue(
      delegate.tokenWallet is TestAccessTokenWallet.Type,
      "Should be able to create with a custom access token setter"
    )
    XCTAssertEqual(
      delegate.featureChecker as? TestFeatureManager,
      featureChecker,
      "Should be able to create with a feature checker"
    )
    XCTAssertEqual(
      delegate.appEvents as? TestAppEvents,
      appEvents,
      "Should be able to create with an app events instance"
    )
    XCTAssertTrue(
      delegate.serverConfigurationProvider is TestServerConfigurationProvider.Type,
      "Should be able to create with a server configuration provider"
    )
  }

  func testInitializingSdkTriggersApplicationLifecycleNotificationsForAppEvents() {
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertTrue(
      appEvents.wasStartObservingApplicationLifecycleNotificationsCalled,
      "Should have app events start observing application lifecycle notifications upon initialization"
    )
  }

  func testInitializingSdkObservesSystemNotifications() {
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertTrue(
      center.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: delegate as Any,
          name: UIApplication.didEnterBackgroundNotification,
          selector: #selector(ApplicationDelegate.applicationDidEnterBackground(_:)),
          object: nil
        )
      ),
      "Should start observing application backgrounding upon initialization"
    )
    XCTAssertTrue(
      center.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: delegate as Any,
          name: UIApplication.didBecomeActiveNotification,
          selector: #selector(ApplicationDelegate.applicationDidBecomeActive(_:)),
          object: nil
        )
      ),
      "Should start observing application foregrounding upon initialization"
    )
    XCTAssertTrue(
      center.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: delegate as Any,
          name: UIApplication.willResignActiveNotification,
          selector: #selector(ApplicationDelegate.applicationWillResignActive(_:)),
          object: nil
        )
      ),
      "Should start observing application resignation upon initializtion"
    )
  }

  func testDidFinishLaunchingLoadsServerConfiguration() {
    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertTrue(
      TestServerConfigurationProvider.loadServerConfigurationWasCalled,
      "Should load a server configuration on finishing launching the application"
    )
  }

  func testOpeningURLChecksAEMFeatureAvailability() {
    delegate.application(
      UIApplication.shared,
      open: SampleUrls.validApp,
      options: [:]
    )
    XCTAssertTrue(
      featureChecker.capturedFeaturesContains(.AEM),
      "Opening a deep link should check if the AEM feature is enabled"
    )
  }
}
