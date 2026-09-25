// Run on iPhone 17e / iOS 27, Safari in portrait with French software keyboard.
// Precondition: local game profile screen open, nickname empty, no install dialog.
// Generate with xcodegen in tests/ios, then run the KeyboardQA scheme.
import XCTest
final class KeyboardTests: XCTestCase {
 func shot(_ app: XCUIApplication, _ name: String) { let a = XCTAttachment(screenshot: app.screenshot()); a.name=name; a.lifetime = .keepAlways; add(a) }
 func testKeyboard() throws {
  let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari"); safari.activate()
  let done = safari.buttons["Fermer le clavier"]
  if done.exists { done.tap() }
  for i in 0..<5 {
   safari.coordinate(withNormalizedOffset: CGVector(dx:0.5,dy:0.525)).tap()
   XCTAssertTrue(done.waitForExistence(timeout:5), "Software keyboard geometry detected cycle \(i)")
   XCTAssertTrue(safari.keyboards.firstMatch.exists)
   if i == 0 {
    safari.keys["C"].tap(); safari.keys["a"].tap()
    safari.coordinate(withNormalizedOffset: CGVector(dx:0.5,dy:0.424)).tap()
    XCTAssertTrue(done.exists, "Tap in field keeps keyboard open")
    shot(safari,"typing-and-field-tap")
   }
   if i % 2 == 0 { safari.coordinate(withNormalizedOffset: CGVector(dx:0.08,dy:0.30)).tap() }
   else { done.tap() }
   XCTAssertTrue(done.waitForNonExistence(timeout:5), "Dismiss control closes cycle \(i)")
   XCTAssertTrue(safari.keyboards.firstMatch.waitForNonExistence(timeout:5), "Keyboard closes cycle \(i)")
   shot(safari,"closed-cycle-\(i)")
  }
  safari.coordinate(withNormalizedOffset: CGVector(dx:0.5,dy:0.525)).tap()
  XCTAssertTrue(done.waitForExistence(timeout:5))
  safari.buttons["OK"].tap()
  XCTAssertTrue(safari.keyboards.firstMatch.waitForNonExistence(timeout:5))
  shot(safari,"native-done")
 }
}
