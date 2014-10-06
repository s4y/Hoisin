//
//  HoisinTask.swift
//  Hoisin
//
//  Created by Sidney San Martín on 8/19/14.
//  Copyright (c) 2014 s4y. All rights reserved.
//

import Foundation
import WebKit

let ENV_DIRS: [NSURL] = {
    let envRoot = NSBundle.mainBundle().URLForResource("env", withExtension: nil)!
    if let envDirs = NSFileManager.defaultManager().contentsOfDirectoryAtURL(
        envRoot, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions(0), error: nil
    ) as? [NSURL] {
        return envDirs
    } else {
        return []
    }
}()

@objc protocol HoisinTaskJS: JSExport {
    var argv: [String] { get set }
    var env: [String:String] { get set }
    // JSExport doesn't support setting closure properties (you can call them but setting them does nothing)
    var onstdout: JSValue? { get set }
    var onstderr: JSValue? { get set }
    var onmessage: JSValue? { get set }
    
    func launch(JSValue)
    func send(AnyObject)
}

class HoisinTask : NSObject, HoisinTaskJS {
    var argv: [String] = []
    var env: [String:String] = [:]
    var pid: pid_t = 0
    var exitstatus: Int32? = nil
    var control: JSONTransport? = nil
    var stdout: NSFileHandle? = nil
    var stderr: NSFileHandle? = nil
    
    var onstdout: JSValue?
    var onstderr: JSValue?
    var onmessage: JSValue?

    func launch(completion: JSValue) {
        launch {
            completion.callWithArguments([NSNumber(int: $0)])
            return ()
        }
    }
    
    func launch(completion: (Int32) -> ()) {
        var env = self.env
        
        for dir in ENV_DIRS {
            let path = dir.path!
            let name = path.lastPathComponent
            if let existing = env[name] {
                env[name] = "\(path):\(existing)"
                // Quick hack to make PATH work with posix_spawnp, we should replace this
                // all with a more legit environment system.
                setenv(name, "\(path):\(existing)", 1)
            } else {
                env[name] = path
            }
        }
        
        var socks: [Int32] = [0, 0]
        socketpair(PF_LOCAL, SOCK_STREAM, 0, &socks)
        
        control = JSONTransport(NSFileHandle(fileDescriptor: socks[0], closeOnDealloc: true))
        
        env["HOISINCHANNEL"] = String(socks[1])
        
        var envArray: [String] = []
        for (k, v) in env {
            envArray.append("\(k)=\(v)")
        }
        
        let stdoutPipe = NSPipe()
        let stderrPipe = NSPipe()
        
        stdout = stdoutPipe.fileHandleForReading
        stderr = stderrPipe.fileHandleForReading
        
        control!.readHandler = { (message: AnyObject) in
            dispatch_after(0, dispatch_get_main_queue()) {
                self.onmessage?.callWithArguments([message])
                return ()
            }
        }
        
        stdout!.readabilityHandler = {
            self.onstdout?.callWithArguments([NSString(data: $0.availableData, encoding: NSUTF8StringEncoding)!])
            return ()
        }
        
        stderr!.readabilityHandler = {
            self.onstderr?.callWithArguments([NSString(data: $0.availableData, encoding: NSUTF8StringEncoding)!])
            return ()
        }
        
        let onexit = { (status: Int32) -> () in
            self.exitstatus = status
            self.stdout!.readabilityHandler = nil
            self.stderr!.readabilityHandler = nil
            self.control!.close()
            completion(status)
        }
        
        var file_actions = posix_spawn_file_actions_t()
        posix_spawn_file_actions_init(&file_actions)
        posix_spawn_file_actions_adddup2(&file_actions, stdoutPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&file_actions, stderrPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        posix_spawn_file_actions_addinherit_np(&file_actions, socks[1])
        
        withCStrings(Slice(envArray)) { env -> () in
            withCStrings(Slice(self.argv)) { argv -> () in
                let ret = posix_spawnp(&self.pid, self.argv[0], &file_actions, nil, argv, env)
                if ret != 0 {
                    onexit(-1)
                }
            }
        }
        
        posix_spawn_file_actions_destroy(&file_actions)
        close(socks[1])
        if exitstatus == nil {
            childCatcher.waitpid(pid, onexit)
        }
    }
    
    func send(obj: AnyObject) {
        control!.write(obj)
    }
}