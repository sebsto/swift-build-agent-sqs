////
////  SQSConsumer.swift
////
////
////  Created by Sebastien Stormacq on 2/23/21.
////
//
//import Foundation
//import SotoSQS
//
//enum MessageError : String, Error {
//    case noHandler = "No message handler, to delete the message"
//}
//
//let client = AWSClient(httpClientProvider: .createNew)
//defer { try? client.syncShutdown() }
//
//let sqs = SQS(client: client, region: .useast2)
//let queue = "https://sqs.us-east-2.amazonaws.com/486652066693/cicd-response"
//
//// Poll for messages, waiting for up to 10 seconds
//let request = SQS.ReceiveMessageRequest(messageAttributeNames: [ "All" ], queueUrl: queue, waitTimeSeconds: 20)
//
//while true {
//    print("Polling for messages...")
//    let eventLoop = sqs.receiveMessage(request).flatMapThrowing({ (result) -> EventLoopFuture<Void> in // <== QUESTION
//        for message in result.messages ?? [] {
//            print("Message Id:", message.messageId ?? "[no id]")
//            print("Content:", message.body ?? "[no message]")
//            print("CorrelationId: ", message.messageAttributes?["correlationId"] ?? "no correlation id")
//
//            guard let handle = message.receiptHandle else {
//                throw MessageError.noHandler // <== QUESTION
//            }
//            let deleteRequest = SQS.DeleteMessageRequest(queueUrl: queue, receiptHandle: handle)
//            sqs.deleteMessage(deleteRequest) // <== QUESTION
//        }
//        
//        // How to return a Future with the union of all deleteMessage's Futures ?
//        // Is the solution to collect an array of loops returned from each deleteMessage() and then call reduce() ?
//        
//        return client.eventLoopGroup.next().makeSucceededVoidFuture()
//    })
//    
//    //where to handle the error thrown in flatMapThrowing() ??
//    
//    //where to handle errors produced by receiveMessage() ?? (how to chain calls to .map() or .flatMap() with .whenFailed() ) ?
//
//    _ = try? eventLoop.wait() // <== QUESTION how to wait for a result when called inside an event loop ?
//    print("Done polling")
//}
//
//// pattern
//// postMessage()
////    .whenFailure( ... )
////    .whenSuccess(
////          pollForMessages()  <== this involves a wait()
////              .whenFailure( ... )
////              .whenSuccess( ... )
////    )
