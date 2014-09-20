//
//  childCatcher.swift
//  Hoisin
//
//  Created by Sidney San Martín on 8/23/14.
//  Copyright (c) 2014 s4y. All rights reserved.
//

import Foundation

func WEXITSTATUS (x: Int32) -> Int32 { return x >> 8 & 0x000000ff }

class ChildCatcher {
    
    let source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, UInt(SIGCHLD), 0, dispatch_get_main_queue())
    var waiters: [pid_t:(Int32) -> ()] = [:]
    
    init() {
        dispatch_source_set_event_handler(source) {
            var stat_loc: Int32 = 0
            let pid = wait(&stat_loc)
            if let waiter = self.waiters[pid] {
                self.waiters.removeValueForKey(pid)
                waiter(WEXITSTATUS(stat_loc))
            }
        }
        dispatch_resume(source)
    }
    
    func waitpid(pid: pid_t, cb: (Int32) -> ()) {
        waiters[pid] = cb
    }
}

let childCatcher = ChildCatcher()