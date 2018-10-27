//
//  TaskQueue.swift
//  SimpleTaskQueue
//
//  Created by Mostafa Abdellateef on 6/30/18.
//  Copyright © 2018 Mostafa Abdellateef. All rights reserved.
//


import Foundation

public class TaskQueue: LockDelegate {
    
    private static var queues = [String: TaskQueue]()
    fileprivate var isExecutingTasks: Bool = false
    fileprivate var headNode: TaskNode? = nil
    private var queueLock = QueueLock()
    
    public let recorder = Recorder()
    
    public static func getQueue(identifier: String) -> TaskQueue {
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
    
    public func setInDebugMode(_ isInDebugMode: Bool) {
        isInDebugMode ? recorder.startRecording() : recorder.stopRecording()
    }
    
    public func push(task: Task){
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

public class QueueLock {
    
    fileprivate weak var delegate: LockDelegate?
    
    public func release() {
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

public protocol Task {
    var tag: String { get }
    func execute(queueLock: QueueLock)
}

public class Recorder {
    
    private let dateFormatter = DateFormatter()
    private var shouldRecordActions: Bool = false
    
    init() {
        dateFormatter.dateFormat = "HH:mm:ss"
    }
    
    fileprivate func startRecording() {
        shouldRecordActions = true
    }
    
    fileprivate func stopRecording() {
        shouldRecordActions = false
        actions.removeAll()
    }
    
    public func reply() {
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
    }
    
    fileprivate func onTaskQueued(task: Task) {
        if shouldRecordActions {
            actions.append(.queued(task: task, time: Date()))
        }
    }
    
    fileprivate func onTaskStarted(task: Task) {
        if shouldRecordActions {
            actions.append(.started(task: task, time: Date()))
        }
    }
    
    fileprivate func onLockReleased(task: Task) {
        if shouldRecordActions {
            actions.append(.releasedLock(task: task, time: Date()))
        }
    }
    
    fileprivate func reset () {
        actions.removeAll()
    }
}
