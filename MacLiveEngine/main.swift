//
//  main.swift
//  MacLiveEngine
//

import Cocoa

print(">>> main.swift: Starting application")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

print(">>> main.swift: Running main loop")
app.run()
