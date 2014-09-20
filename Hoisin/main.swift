//
//  main.swift
//  Hoisin
//
//  Created by Sidney San Martín on 8/19/14.
//  Copyright (c) 2014 s4y. All rights reserved.
//

import Cocoa

signal(SIGPIPE, CFunctionPointer<((Int32) -> Void)>(COpaquePointer(bitPattern: 1)))

NSUserDefaults.standardUserDefaults().registerDefaults([
    "WebKitDeveloperExtras": true
])

NSApplicationMain(C_ARGC, C_ARGV)
