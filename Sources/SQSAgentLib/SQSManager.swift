//
//  SQSManager.swift
//  
//
//  Created by Stormacq, Sebastien on 27/02/2021.
//

import Foundation

import SotoSQS

// the message structure to communicate with client of this class
public struct Message {
    public var body       : String
    public var attributes : [ String : String ]
}

// the error this class can raise
enum MessageError : String, Error {
    case noHandler = "No message handler, to delete the message"
    case noMessage = "No message returned, despite success"
    case noCorrelationId = "There is no correlationId in the message attributes"
    case noResponseQueue = "Please pass a response queue if youe xpect a response"
}

// manage the low level details of SQS and rhe request / response pattern
public class SQSManager {
    
    private var sqs    : SQS
    private var client : AWSClient
    
    private let requestQueueUrl  : String
    private let responseQueueUrl : String?
        
    public init (requestQueueUrl : String, responseQueueUrl: String? = nil) {
        
        self.requestQueueUrl  = requestQueueUrl
        self.responseQueueUrl = responseQueueUrl

        if (SQSManager.onEC2()) {
            client = AWSClient(credentialProvider: .selector(.ec2, .configFile()) ,httpClientProvider: .createNew)
        } else {
            client = AWSClient(httpClientProvider: .createNew)
        }
        sqs    = SQS(client: client, region: .useast2)

    }
    
    deinit {
        try? client.syncShutdown()
    }
    
    //are we running on EC2 ?
    private static func onEC2() -> Bool {
        var result = true
        do {
            let client = AWSClient(httpClientProvider: .createNew)
            defer { try? client.syncShutdown() }
            let metadataRequest = AWSHTTPRequest(url: URL(string: "http://169.254.169.254/latest/meta-data/hostname")!, method: .GET)
            let httpResponse = try client.httpClient.execute(request: metadataRequest, timeout: TimeAmount.milliseconds(100), on: client.eventLoopGroup.next(), logger: AWSClient.loggingDisabled).wait()
            print("Running on EC2:", String(buffer: httpResponse.body!))
        } catch {
            print("Error when contacting EC2 meta-data service")
            result = false
        }
        return result
    }
    
    // sync function. It returns the response message body
    // TODO manage timeouts
    public func sendRequestWithResponse(body : String) throws -> String {
        
        guard let responseQueue = self.responseQueueUrl else {
            throw MessageError.noResponseQueue
        }
        
        // prepare message attributes
        let uuid = UUID().uuidString
        let messageAttributes = [
            "correlationId" : SQS.MessageAttributeValue(dataType:"String", stringValue: uuid),
            "responseQueue" : SQS.MessageAttributeValue(dataType:"String", stringValue: responseQueue)
        ]
        
        // post message
        print("posting message with correlation id: ", uuid)
        let data = body.data(using: String.Encoding.utf8)
        let sendRequest = SQS.SendMessageRequest(messageAttributes: messageAttributes, messageBody: data!.base64EncodedString(), queueUrl: self.requestQueueUrl)
        
        let sendResult = try! sqs.sendMessage(sendRequest).wait()
        print("message sent, id: ", sendResult.messageId ?? "[No id]")
        
        return try self.pollForResponse(queueURL: responseQueue, correlationId: uuid)
    }
    
    private func pollForResponse(queueURL: String, correlationId : String) throws -> String {
        
        // Poll for messages, waiting for up to 15 seconds
        let request = SQS.ReceiveMessageRequest(maxNumberOfMessages: 10, messageAttributeNames: [ "All" ], queueUrl: queueURL, waitTimeSeconds: 15)

        var receivedResponse = false
        var matchingMessages : [SQS.Message] = []
        
        while !receivedResponse {
            
            print("Polling for messages with correlationId = ", correlationId)
            
            let messages = try self.sqs.receiveMessage(request)
                .map { (result) -> [SQS.Message] in
                
                    print("Received \(result.messages?.count ?? 0)")
                    return (result.messages ?? [])
                }
                .wait()
            
            matchingMessages = messages.filter { msg in
                return msg.messageAttributes?["correlationId"]?.stringValue == correlationId
            }
            print("Received \(matchingMessages.count) messages matching the correlationId")

            receivedResponse = matchingMessages.count > 0
            print("Done polling. \(receivedResponse ? "" : "re-starting.")")
        }
        
        //when we found the matching messages, delete them
        for m in matchingMessages {
            print("Deleting message: ", m.messageId ?? "[no id]")
            deleteMessage(queueUrl: queueURL, message: m) // do not wait, we don't care about the result
        }
        
        // returns just the body of the first message
        let data = Data(base64Encoded: matchingMessages[0].body ?? "")
        let result = String(data: data!, encoding: String.Encoding.utf8)
        return result!
    }
    
    private func deleteMessage(queueUrl : String, message : SQS.Message) {
        if let handle = message.receiptHandle  {
            let deleteRequest = SQS.DeleteMessageRequest(queueUrl: queueUrl, receiptHandle: handle)
            try? self.sqs.deleteMessage(deleteRequest).wait()
        } else {
            print("No handler to delete message id: ", message.messageId ?? "[no id]")
        }
    }
    
    public func receiveMessage() throws -> [Message] {
        // Poll for messages, waiting for up to 15 seconds
        let request = SQS.ReceiveMessageRequest(messageAttributeNames: [ "All" ], queueUrl: self.requestQueueUrl, waitTimeSeconds: 15)

        print("Polling for messages...")
        var result : [Message] = []
        let resultReceive = try sqs.receiveMessage(request).wait()
                
        for message in resultReceive.messages ?? [] {
            
            guard let msgBody = message.body,
                  let correlationId = message.messageAttributes?["correlationId"]?.stringValue,
                  let responseQueue = message.messageAttributes?["responseQueue"]?.stringValue else {
                print("ERROR : Invalid message, it does not contain correlationId or responseQueue message attributes")
                break
            }
             
            let data = Data(base64Encoded: msgBody)!
            let msg = String(data: data, encoding: String.Encoding.utf8)!

            print("Message Id:    ", message.messageId ?? "[no id]")
            //print("Content:       ", msg)
            print("CorrelationId: ", correlationId)
            
            guard let handle = message.receiptHandle else {
                throw MessageError.noHandler
            }
            let deleteRequest = SQS.DeleteMessageRequest(queueUrl: self.requestQueueUrl, receiptHandle: handle)
            try sqs.deleteMessage(deleteRequest).wait()
            
            result.append(Message(body: msg, attributes: [ "responseQueue": responseQueue, "correlationId": correlationId ] ))
        }
        print("Done polling")
        return result
    }
    
    public func postResponse(queueUrl : String, correlationId : String, response : String) {
        // prepare message attributes
        let uuid = UUID().uuidString
        let messageAttributes = [
            "correlationId" : SQS.MessageAttributeValue(dataType:"String", stringValue: correlationId)        ]
        
        // post message
        print("posting response for correlation id: ", uuid)
        let data = response.data(using: String.Encoding.utf8)
        let sendRequest = SQS.SendMessageRequest(messageAttributes: messageAttributes, messageBody: data!.base64EncodedString(), queueUrl: queueUrl)
        let sendResult = try! sqs.sendMessage(sendRequest).wait()
        print("message sent, id: ", sendResult.messageId ?? "[No id]")

    }
    
}

