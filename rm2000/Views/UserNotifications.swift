import UserNotifications

func displayTestingGlobalNotication() async {
	let center = UNUserNotificationCenter.current()
	
	do {
		try await center.requestAuthorization(options: [.alert, .criticalAlert, .provisional])
	} catch {
		print("User Notifications not enabled.")
	}
	
	let content = UNMutableNotificationContent()
	
	content.title = "RM2000 Tape Recorder"
	content.body = "Global recording shortcut presssed!"
	let uuid = UUID().uuidString
	
	let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
	print(trigger)
	let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)
	
	do {
		try await center.add(request)
	} catch {
		print("not enabled")
	}
}
