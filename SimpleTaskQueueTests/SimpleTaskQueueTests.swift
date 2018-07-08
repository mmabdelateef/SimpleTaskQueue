//
//  SimpleTaskQueueTests.swift
//  SimpleTaskQueueTests
//
//  Created by Mostafa Abdellateef on 6/30/18.
//  Copyright © 2018 Mostafa Abdellateef. All rights reserved.
//

import XCTest
@testable import SimpleTaskQueue

class SimpleTaskQueueTests: XCTestCase {
    
    var recoder = ExecutionRecorder()
    
    override func setUp() {
        super.setUp()
        recoder.reset()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let test = expectation(description: "Example")
        
        let numberOfRandomLenghtTasks = 20
        let queue = TaskQueue.getQueue(identifier: "Test")
        _ = (1...numberOfRandomLenghtTasks).map {
            queue.push(task: RandomTimeTask(index: $0, recoder: recoder))
        }
        
        recoder.notifyOnTaskFinish(taskIndex: numberOfRandomLenghtTasks) {
            test.fulfill()
            queue.recorder.reply()
        }
        
        
        waitForExpectations(timeout: 100, handler: nil)
        
        assert(recoder.getOrderedIndexsOfFinishedTasks() == Array(1...numberOfRandomLenghtTasks))
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func generateRandomTask(index: Int) -> Task {
        return RandomTimeTask(index: index, recoder: recoder)
    }
}

class RandomTimeTask: Task {
    var tag: String
    
    let index : Int
    let recoder: ExecutionRecorder
    
    init(index: Int, recoder: ExecutionRecorder) {
        self.index = index
        self.tag = "\(index)"
        self.recoder = recoder
    }
    
    func execute(queueLock: QueueLock) {
        recoder.onTaskStart(task: self)
        let randomDelay = Int(arc4random_uniform(6) + 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(randomDelay)) {
            self.recoder.onTaskFinish(task: self)
            queueLock.release()
        }
    }
}

class ExecutionRecorder {
    
    private var actions = [Action] ()
    private var callbacksForFinish = [(index: Int, callback: ()-> Void)]()
    
    enum Action {
        case start(task: RandomTimeTask, time: Date)
        case end(task: RandomTimeTask, time: Date)
        
        var date: Date {
            switch self {
            case .start(_, let time):
                return time
            case .end(_, let time):
                return time
            }
        }
        
        var task: RandomTimeTask {
            switch self {
            case .start(let task, _):
                return task
            case .end(let task, _):
                return task
            }
        }
    }
    
    public func onTaskStart(task: RandomTimeTask) {
        actions.append(.start(task: task, time: Date()))
    }
    
    public func onTaskFinish(task: RandomTimeTask) {
        actions.append(.end(task: task, time: Date()))
        self.callbacksForFinish.filter {
            $0.index == task.index
            }.forEach { $0.callback() }
    }
    
    public func getOrderedIndexsOfFinishedTasks() -> [Int] {
        return actions.filter {
            switch $0 {
            case .end( _ , _):
                return true
            default:
                return false
            }
            }.sorted {
                $0.date < $1.date
            }.map {
                $0.task.index
        }
    }
    
    public func reset () {
        actions = [Action]()
    }
    
    func notifyOnTaskFinish(taskIndex: Int, callback: @escaping ()-> Void) {
        self.callbacksForFinish.append((index: taskIndex, callback: callback))
    }
}
