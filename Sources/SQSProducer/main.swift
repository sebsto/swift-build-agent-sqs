//
//  Producer.swift
//
//
//  Created by Sebastien Stormacq on 2/23/21.
//

import Foundation

import SQSAgentLib

let arguments = ProcessInfo.processInfo.arguments
guard arguments.count == 4 else {
    printUsage()
    exit(-1)
}

let requestQueue = arguments[1]
let responseQueue = arguments[2]
guard requestQueue.starts(with: "https://"),
      responseQueue.starts(with: "https://") else {
    printUsage()
    print("Error: queues URL must start with https://")
    exit(-1)
}

let filePath = arguments[3]
let fm = FileManager()
guard fm.fileExists(atPath: filePath) else {
    printUsage()
    print("Error: \(filePath) does not exist")
    exit(-1)
}

let sqsManager = SQSManager(requestQueueUrl: requestQueue, responseQueueUrl: responseQueue)

let message  = try String(contentsOfFile: filePath, encoding: String.Encoding.utf8)
let (response, exitCode) = try sqsManager.sendRequestWithResponse(body: message)
print("response received: ", response )

exit(exitCode)

func printUsage() {
    print("Usage: SQSProducer https://request_queue_url https://response_queue_url /path/to/command/file")
}
