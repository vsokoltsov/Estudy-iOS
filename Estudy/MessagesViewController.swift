//
//  MessagesViewController.swift
//  Estudy
//
//  Created by vsokoltsov on 03.03.16.
//  Copyright © 2016 vsokoltsov. All rights reserved.
//

import UIKit
import Foundation
import SocketIOClientSwift

class MessagesViewController: ApplicationViewController, UITableViewDelegate, UITableViewDataSource, Messages {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var messageFormView: UIView!
    @IBOutlet var messageFormHeightConstraint: NSLayoutConstraint!
    @IBOutlet var messageFormHeightValue: NSLayoutConstraint!
    
    var keyboardIsVisible = false
    var messageFormDefaultHeight: CGFloat!
    let minFormHeight = CGFloat(50)
    let maxFormHeight = CGFloat(160)
    var defaultKeyboardHeight: CGFloat!
    var chat: Chat!
    var messageFormContent: MessageForm!
    var cellIdentifier = "messageCell"
    var currentUserCellIdentifier = "currentUserMessageCell"
    var personalCellIdentifier = "personalCellIdentifier"
    var currentUserPersonalCellIdentifier = "currentUserPersonalCellIdentifier"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidHide:", name: UIKeyboardDidHideNotification, object: nil)
        setSocketData()
        setMessageForm();
        setNavigationBarData()
        tableView.setContentOffset(CGPoint(x: CGFloat(0), y: CGFloat.max), animated: true)
        tableView.registerNib(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView.registerNib(UINib(nibName: "CurrentUserMessageCell", bundle: nil), forCellReuseIdentifier: currentUserCellIdentifier)
        tableView.registerNib(UINib(nibName: "PersonalMessageCell", bundle: nil), forCellReuseIdentifier: personalCellIdentifier)
        tableView.registerNib(UINib(nibName: "CurrentUserPersonalMessageCell", bundle: nil), forCellReuseIdentifier: currentUserPersonalCellIdentifier)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let message = chat.messages[indexPath.row]
        if (hasMultipleUsers()) {
            if (message.user.id == AuthService.sharedInstance.currentUser.id) {
                return currentUserMessageCellInstance(message, indexPath: indexPath) as UITableViewCell
            }
            else {
                return messageCellInstance(message, indexPath: indexPath) as UITableViewCell
            }
        }
        else {
            if (message.user.id == AuthService.sharedInstance.currentUser.id) {
                return currentUserPersonalMessageCellInstance(message, indexPath: indexPath) as UITableViewCell
            }
            else {
                return personalMessageCellInstance(message, indexPath: indexPath) as UITableViewCell
            }
        }
        
        
    }
    
    func currentUserMessageCellInstance(message: Message, indexPath: NSIndexPath) -> CurrentUserMessageCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(currentUserCellIdentifier, forIndexPath: indexPath) as! CurrentUserMessageCell
        cell.setDataToMessageData(message)
        return cell
    }
    
    func messageCellInstance(message: Message, indexPath: NSIndexPath) -> MessageCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! MessagesCell
        cell.setDataToMessageData(message)
        return cell
    }
    
    func personalMessageCellInstance(message: Message, indexPath: NSIndexPath) -> PersonalMessageCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(personalCellIdentifier, forIndexPath: indexPath) as! PersonalMessageCell
        cell.setDataToMessageData(message)
        return cell
    }
    
    func currentUserPersonalMessageCellInstance(message: Message, indexPath: NSIndexPath) -> CurrentUserPersonalMessageCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(currentUserPersonalCellIdentifier, forIndexPath: indexPath) as! CurrentUserPersonalMessageCell
        cell.setDataToMessageData(message)
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (hasMultipleUsers()) {
            return 90
        }
        else {
            return 50
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chat.messages.count
    }
    
    func hasMultipleUsers() -> Bool {
        return chat.users!.count > 2
    }
    
    func setNavigationBarData() {
        if (!hasMultipleUsers()) {
            let view = NSBundle.mainBundle().loadNibNamed("PersonalNavigationBar", owner: nil, options: nil).first as! PersonalNavigationBar
            var member = returnOtherChatMembers().first as! User!
            view.setMemberData(member)
            self.navigationItem.titleView = view
        }
    }
    
    func returnOtherChatMembers() -> [User] {
        return (chat.users?.filter({ $0.id != AuthService.sharedInstance.currentUser.id }))!
    }
    
    func setMessageForm() {
        messageFormContent = NSBundle.mainBundle().loadNibNamed("MessageForm", owner: nil, options: nil).first as! MessageForm
        messageFormDefaultHeight = view.frame.size.height
        messageFormContent.delegate = self
        messageFormView.addSubview(messageFormContent)
    }
    
    func keyboardDidShow(notification: NSNotification) {
        if (!keyboardIsVisible) {
            keyboardIsVisible = true
            var height = getKeyboardHeight(notification)
            messageFormHeightConstraint.constant = messageFormHeightConstraint.constant + height
            scrollDownTableView()
        }
    }
    
    func keyboardDidHide(notification: NSNotification) {
        if (keyboardIsVisible) {
            keyboardIsVisible = false
            var height = getKeyboardHeight(notification)
            messageFormHeightConstraint.constant = messageFormHeightConstraint.constant - height

        }
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo:NSDictionary = notification.userInfo!
        let keyboardFrame:NSValue = userInfo.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.CGRectValue()
        defaultKeyboardHeight = keyboardRectangle.height
        return defaultKeyboardHeight
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func textViewChangeSize(textView: UITextView!) {
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        if (newSize.height > minFormHeight && newSize.height <= maxFormHeight) {
            messageFormHeightValue.constant = newSize.height
        }
        if (textView.text == "") {
            setDefaultMessageFormHeight()
        }
    }
    
    func createMessage(text: String!) {
        let user = AuthService.sharedInstance.currentUser
        var params: NSDictionary = [
            "message": ["user_id": user.id as Int, "chat_id": chat.id!, "text": text!]
        ]
        MessagesFactory.sharedInstance.create(params, success: successCreateMessageCallback, error: failureCreateMessageCallback)
    }
    
    func successCreateMessageCallback(message: Message!) {
        chat.messages.append(message)
        tableView.reloadData()
        scrollDownTableView()
        messageFormContent.resetFormText()
        setDefaultMessageFormHeight()
    }
    
    func failureCreateMessageCallback(error: ServerError) {
        
    }
    
    func scrollDownTableView() {
        var diff: CGFloat!
        let indexPath = NSIndexPath(forRow: chat.messages.count - 1, inSection: 0)
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        if (keyboardIsVisible) {
            diff = cell!.frame.origin.y - defaultKeyboardHeight - minFormHeight
        }
        else {
            diff = cell!.frame.origin.y
        }
        var y = diff
        tableView.setContentOffset(CGPointMake(0, y ), animated: true)
    }
    
    func setDefaultMessageFormHeight() {
        messageFormHeightValue.constant = minFormHeight
    }
    
    func setSocketData() {
        socket.on("user\(AuthService.sharedInstance.currentUser.id)chatmessage") {data, ack in
            if let action = data.first!["action"] {
                switch(String(action!)) {
                case "chatmessage":
                    if let object = data.first!["obj"] {
                        self.addMessageToList(String(object!))
                    }
                default: break
                }
            }
        }
        
        socket.connect()
    }
    
    func addMessageToList(messageData: String!) {
        let message = MessagesFactory.sharedInstance.parseObject(messageData)
        if (message.user.id != AuthService.sharedInstance.currentUser.id) {
            chat.messages.append(message)
            tableView.reloadData()
            scrollDownTableView()
        }
//
    }

}