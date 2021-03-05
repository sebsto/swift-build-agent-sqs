//
//  SQSConsumer.swift
//  
//
//  Created by Sebastien Stormacq on 2/23/21.
//

import Foundation
import SQSAgentLib

//public let requestQueue  = "https://sqs.us-east-2.amazonaws.com/486652066693/cicd-command"
//public let responseQueue = "https://sqs.us-east-2.amazonaws.com/486652066693/cicd-response"

let arguments = ProcessInfo.processInfo.arguments
guard arguments.count == 2 else {
    printUsage()
    exit(-1)
}

let requestQueue = arguments[1]
guard requestQueue.starts(with: "https://") else {
    printUsage()
    print("Error: queue URL must start with https://")
    exit(-1)
}


let sqsManager = SQSManager(requestQueueUrl: requestQueue)
let fm = FileManager()

while true {
    let messages = try sqsManager.receiveMessage()
    for msg in messages {
        
        guard let responseQueue = msg.attributes["responseQueue"],
              let correlationid = msg.attributes["correlationId"] else {
            
            break
        }
                    
        let filePath = "/tmp/" + correlationid
        fm.createFile(atPath: filePath, contents: msg.body.data(using: String.Encoding.utf8), attributes: [ FileAttributeKey.posixPermissions : 510 ]) // 510 = 777 in octal
        print("Going to execute : \(filePath)")
        
        if #available(OSX 10.13, *) {
            let (result, error) = executeCommand(cmd: filePath)
            let response = "*** STDERR ***\n" + error + "\n\n*** STDOUT ***\n" + result
            
            sqsManager.postResponse(queueUrl: responseQueue, correlationId: correlationid, response: response)
        } else {
            print("Only works on macOS 10.13 or more recent")
            exit(-1)
        }
        
    }
}

@available(OSX 10.13, *)
func executeCommand(cmd: String, args: [String] = []) -> (String, String) {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: cmd)

    if args.count > 0 {
        task.arguments = args
    }
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    task.standardOutput = outputPipe
    task.standardError = errorPipe
    
    try? task.run()
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

    let output = String(decoding: outputData, as: UTF8.self)
    let error = String(decoding: errorData, as: UTF8.self)
    
    return (output, error)
}

func printUsage() {
    print("Usage: SQSBuildAgent https://request_queue_url")
}
