import Foundation

private let ENV_DIRS: [NSURL] = {
    let envRoot = NSBundle.mainBundle().URLForResource("env", withExtension: nil)!
    if let envDirs = (try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(
        envRoot, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions(rawValue: 0))) {
        return envDirs
    } else {
        return []
    }
}()

class Task: NSObject {
    var argv: [String] = []
    var env: [String:String] = [:]
    var pid: pid_t = 0
    var control: JSONTransport? = nil
    var stdin: NSFileHandle? = nil
    var stdout: NSFileHandle? = nil
    var stderr: NSFileHandle? = nil
    
    func launch(onexit: (Int32) -> ()) {
        var env = self.env
        
        for dir in ENV_DIRS {
            let path = dir.path!
            let name = NSURL(string: path)!.lastPathComponent!
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
        
        let stdinPipe = NSPipe()
        let stdoutPipe = NSPipe()
        let stderrPipe = NSPipe()
        
        stdin = stdinPipe.fileHandleForWriting
        stdout = stdoutPipe.fileHandleForReading
        stderr = stderrPipe.fileHandleForReading
        
        var file_actions: posix_spawn_file_actions_t = nil
        posix_spawn_file_actions_init(&file_actions)
        posix_spawn_file_actions_adddup2(&file_actions, stdinPipe.fileHandleForReading.fileDescriptor, STDIN_FILENO)
        posix_spawn_file_actions_adddup2(&file_actions, stdoutPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&file_actions, stderrPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        posix_spawn_file_actions_addinherit_np(&file_actions, socks[1])
        
        withCStrings(ArraySlice(envArray)) { env -> () in
            withCStrings(ArraySlice(self.argv)) { argv -> () in
                let ret = posix_spawnp(&self.pid, self.argv[0], &file_actions, nil, argv, env)
                if ret == 0 {
                    childCatcher.waitpid(self.pid, cb: onexit)
                } else {
                    onexit(-1)
                }
            }
        }
        
        posix_spawn_file_actions_destroy(&file_actions)
        close(socks[1])
        stdinPipe.fileHandleForReading.closeFile()
        stdoutPipe.fileHandleForWriting.closeFile()
        stderrPipe.fileHandleForWriting.closeFile()
    }
    
    func send(obj: AnyObject) {
        control!.write(obj)
    }
    
    func sendStdin(s: String) {
        stdin!.writeData(s.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
    }

    func kill(signal: Int32) {
        Foundation.kill(pid, signal)
    }
}