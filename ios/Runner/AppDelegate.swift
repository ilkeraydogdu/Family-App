import AVFoundation
import AudioToolbox
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var alarmPlayer: AVAudioPlayer?
  private var vibrationTimer: Timer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    let widgetChannel = FlutterMethodChannel(
      name: "com.ilkeraydogdu.family_app/home_widget",
      binaryMessenger: messenger
    )
    widgetChannel.setMethodCallHandler { call, result in
      if call.method == "updateHomeWidget", let args = call.arguments as? [String: Any] {
        let defaults = UserDefaults.standard
        defaults.set(args["hadithText"] as? String ?? "", forKey: "widget_hadithText")
        defaults.set(args["hadithSource"] as? String ?? "", forKey: "widget_hadithSource")
        defaults.set(args["duaArabic"] as? String ?? "", forKey: "widget_duaArabic")
        defaults.set(args["duaTurkish"] as? String ?? "", forKey: "widget_duaTurkish")
        defaults.set(args["duaSource"] as? String ?? "", forKey: "widget_duaSource")
        defaults.set(args["zikir"] as? String ?? "", forKey: "widget_zikir")
        defaults.set(args["prayerSummary"] as? String ?? "", forKey: "widget_prayerSummary")
        defaults.set(args["nextPlanSummary"] as? String ?? "", forKey: "widget_nextPlanSummary")
        defaults.set(args["widgetStyle"] as? String ?? "hadith_dua", forKey: "widget_style")
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let alarmChannel = FlutterMethodChannel(
      name: "com.ilkeraydogdu.family_app/alarm_audio",
      binaryMessenger: messenger
    )
    alarmChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "startAlarmLoop":
        if let args = call.arguments as? [String: Any],
           let typedData = args["wavBytes"] as? FlutterStandardTypedData {
          self?.startNativeAlarm(wavData: typedData.data)
        } else {
          self?.startNativeAlarm(wavData: nil)
        }
        result(true)
      case "stopAlarmLoop":
        self?.stopNativeAlarm()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startNativeAlarm(wavData: Data?) {
    stopNativeAlarm()
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .default,
        options: [.duckOthers]
      )
      try AVAudioSession.sharedInstance().setActive(true)
      if let data = wavData, !data.isEmpty {
        let player = try AVAudioPlayer(data: data)
        player.numberOfLoops = -1
        player.volume = 1.0
        player.prepareToPlay()
        player.play()
        alarmPlayer = player
      } else {
        AudioServicesPlaySystemSound(1005)
      }
    } catch {
      AudioServicesPlaySystemSound(1005)
    }

    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { _ in
      AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
  }

  private func stopNativeAlarm() {
    vibrationTimer?.invalidate()
    vibrationTimer = nil
    alarmPlayer?.stop()
    alarmPlayer = nil
  }
}
