//
//  TaskQueue.swift
//  SimpleTaskQueue
//
//  Created by Mostafa Abdellateef on 6/30/18.
//  Copyright © 2018 Mostafa Abdellateef. All rights reserved.
//


import Foundation

class TaskQueue: LockDelegate {
    
    private static var queues = [String: TaskQueue]()
    fileprivate var isExecutingTasks: Bool = false
    fileprivate var headNode: TaskNode? = nil
    private var queueLock = QueueLock()
    
    public let recorder = Recorder()
    
    static func getQueue(identifier: String) -> TaskQueue {
        if let queue = queues[identifier] {
            return queue
        } else {
            let newQueue = TaskQueue()
            queues[identifier] = newQueue
            return newQueue
        }
    }
    
    private init() {
        queueLock.delegate = self
    }
    
    func push(task: Task){
        let newTaskNode = TaskNode(currentTask: task, nextNode: nil)
        
        if let tail = headNode?.getTail() {
            tail.nextNode = newTaskNode
        } else {
            headNode = newTaskNode
        }
        recorder.onTaskQueued(task: task)
        processQueue()
    }
    
    fileprivate func processQueue() {
        if !isExecutingTasks, let initialTaskNode = headNode {
            isExecutingTasks = true
            func executeNode (node: TaskNode) {
                if let task = node.currentTask {
                    recorder.onTaskStarted(task: task)
                    task.execute(queueLock: self.queueLock)
                }
            }
            executeNode(node: initialTaskNode)
        }
    }
    
    fileprivate func onRelease() {
        isExecutingTasks = false
        if let headNodeTask = headNode?.currentTask {
            recorder.onLockReleased(task: headNodeTask)
        }
        
        if let headNode = self.headNode?.nextNode {
            self.headNode = headNode
        } else {
            self.headNode = nil
        }
        processQueue()
    }
}

class QueueLock {
    
    fileprivate weak var delegate: LockDelegate?
    
    func release() {
        delegate?.onRelease()
    }
}

fileprivate protocol LockDelegate: class {
    func onRelease()
}

private class TaskNode {
    var currentTask: Task?
    var nextNode: TaskNode?
    
    init(currentTask: Task?, nextNode: TaskNode?) {
        self.currentTask = currentTask
        self.nextNode = nextNode
    }
    
    func getTail() -> TaskNode? {
        guard let nextNode = self.nextNode else {
            return self
        }
        return nextNode.getTail()
    }
}

protocol Task {
    var tag: String { get }
    func execute(queueLock: QueueLock)
}

class Recorder {
    
    private let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateFormat = "HH:mm:ss"
    }
    
    func reply() {
        actions.forEach {
            switch $0 {
            case .queued(let task, let time):
                print("\(dateFormatter.string(from: time)): Task \(task.tag) pushed to queue")
            case .started(let task, let time):
                print("\(dateFormatter.string(from: time)): Task \(task.tag) started - accuired lock")
            case .releasedLock(let task, let time):
                print("\(dateFormatter.string(from: time)): Task \(task.tag) finished - released lock")
            }
        }
    }
    
    private var actions = [Action] ()
    private var callbacksForFinish = [(index: Int, callback: ()-> Void)]()
    
    private enum Action {
        case started(task: Task, time: Date)
        case queued(task: Task, time: Date)
        case releasedLock(task: Task, time: Date)
        
//       private  var date: Date {
//            switch self {
//            case .started(_, let time),
//                 .releasedLock(_ , let time),
//                 .queued(_ ,let time):
//                return time
//            }
//        }
//
//        private var task: Task {
//            switch self {
//            case .started(let task, _):
//                return task
//            case .releasedLock(let task , _):
//                return task
//            case .queued(let task , _):
//                return task
//            }
//        }
    }
    
    fileprivate func onTaskQueued(task: Task) {
        actions.append(.queued(task: task, time: Date()))
    }
    
    fileprivate func onTaskStarted(task: Task) {
        actions.append(.started(task: task, time: Date()))
    }
    
    fileprivate func onLockReleased(task: Task) {
        actions.append(.releasedLock(task: task, time: Date()))
    }
    
    fileprivate func reset () {
        actions = [Action]()
    }
}
