//
//  ReplyContentViewController.swift
//  guanggoo-iOS
//
//  Created by tdx on 2017/12/27.
//  Copyright © 2017年 tdx. All rights reserved.
//

import UIKit
import YYText
import Toast_Swift
import MBProgressHUD
import Alamofire

class ReplyContentViewController: UIViewController ,YYTextViewDelegate,GuangGuVCDelegate{
    
    fileprivate var initString:String = "";
    fileprivate var commentURLString:String = "";
    fileprivate var commentID = "";
    fileprivate var nameList:[String]?;
    fileprivate var keyboardOffset:CGFloat = 0;
    fileprivate var containerView = UIView.init();
    fileprivate var toolView:TextToolView!;
    fileprivate var originY:CGFloat = 0;                //记录初始view的y值，第三方键盘会影响view下移
    
    fileprivate var _textView:YYTextView!
    fileprivate var textView:YYTextView {
        get {
            guard _textView == nil else {
                return _textView;
            }
            _textView = YYTextView()
            _textView.scrollsToTop = false
            _textView.backgroundColor = UIColor.white;
            _textView.font = UIFont.systemFont(ofSize: 18);
            _textView.delegate = self
            _textView.textColor = UIColor.black;
            _textView.placeholderText = "请输入回复内容";
            _textView.textParser = GGMentionedBindingParser()
            _textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10)
            _textView.keyboardDismissMode = .interactive
            _textView.layer.borderColor = UIColor.lightGray.cgColor;
            _textView.layer.cornerRadius = 5;
            _textView.layer.borderWidth = 0.5;
            _textView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 40, right: 0);
            //_textView.becomeFirstResponder();
            
            let str = NSMutableAttributedString(string: self.initString)
            str.yy_font = UIFont.systemFont(ofSize: 18);
            str.yy_color = UIColor.black;
            
            _textView.attributedText = str
            
            _textView.selectedRange = NSMakeRange(self.initString.count, 0);
            
            return _textView;
        }
    }
    
    fileprivate var _completion:HandleCompletion?
    required init(string:String,urlString:String,nameArray:[String]?,completion:HandleCompletion?)
    {
        super.init(nibName: nil, bundle: nil);
        self.initString = string;
        self.nameList = nameArray;
        
        var commentLink = urlString;
        let result1 = commentLink.range(of: "/t/",
                                        options: NSString.CompareOptions.literal,
                                        range: commentLink.startIndex..<commentLink.endIndex,
                                        locale: nil)
        if let rang = result1 {
            let start = rang.upperBound;
            commentLink = String(commentLink[start..<commentLink.endIndex]);
        }
        let result2 = commentLink.range(of: "?p",
                                        options: NSString.CompareOptions.literal,
                                        range: commentLink.startIndex..<commentLink.endIndex,
                                        locale: nil)
        if let rang = result2 {
            let end = rang.lowerBound;
            commentLink = String(commentLink[commentLink.startIndex..<end]);
        }
        self.commentID = commentLink;
        
        let result3 = urlString.range(of: "?p",
                                      options: NSString.CompareOptions.literal,
                                      range: urlString.startIndex..<urlString.endIndex,
                                      locale: nil)
        if let rang = result3 {
            let end = rang.lowerBound;
            self.commentURLString = String(urlString[urlString.startIndex..<end]);
        }
        else {
            self.commentURLString = urlString;
        }
        
        self._completion = completion;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let leftButton = UIButton.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40));
        leftButton.setTitle("取消", for: .normal);
        leftButton.setTitleColor(UIColor.init(red: 75.0/255.0, green: 145.0/255.0, blue: 214.0/255.0, alpha: 1), for: .normal);
        leftButton.addTarget(self, action: #selector(CenterViewController.leftClick(sender:)), for: .touchUpInside);
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: leftButton);
        
        let rightButton = UIButton.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40));
        rightButton.setTitle("提交", for: .normal);
        rightButton.setTitleColor(UIColor.init(red: 75.0/255.0, green: 145.0/255.0, blue: 214.0/255.0, alpha: 1), for: .normal);
        rightButton.addTarget(self, action: #selector(CenterViewController.rightClick(sender:)), for: .touchUpInside);
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: rightButton);
        
        self.view.backgroundColor = UIColor.white;
        self.view.window?.backgroundColor = UIColor.white;
        
        self.view.addSubview(self.containerView);
        self.containerView.snp.makeConstraints { (make) in
            make.left.equalTo(self.view).offset(10);
            make.right.equalTo(self.view).offset(-10);
            make.top.equalTo(self.topLayoutGuide.snp.bottom).offset(10);
            if #available(iOS 11, *) {
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottomMargin).offset(-10);
            } else {
                make.bottom.equalTo(self.view).offset(-10);
            }
        }
        
        self.containerView.addSubview(self.textView);
        self.textView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.containerView);
        }
        
        self.toolView = TextToolView.init(nameArray: self.nameList, nav: self.navigationController);
        self.toolView.vcDelegate = self;
        self.toolView.backgroundColor = UIColor.clear;
        self.textView.addSubview(self.toolView);
        self.toolView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.containerView);
            make.bottom.equalTo(self.containerView).offset(-7);
            make.height.equalTo(30);
        }
        
        //add keyboard notification
        NotificationCenter.default.addObserver(self, selector: #selector(ReplyContentViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ReplyContentViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        self.originY = self.view.frame.origin.y;
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func textViewDidChange(_ textView: YYTextView) {
//        if textView.text.count == 0{
//            textView.textColor = UIColor.lightGray;
//        }
    }
    
    @objc func leftClick(sender: UIButton) -> Void {
        self.textView.resignFirstResponder();
        let text = self.textView.text;
        if text != self.initString {
            let alert = UIAlertController.init(title: "提示", message: "确定放弃修改并返回？", preferredStyle: .alert);
            let ok = UIAlertAction.init(title: "确定", style: .default, handler: { (alert) in
                self.navigationController?.popViewController(animated: true);
            })
            let cancel = UIAlertAction.init(title: "取消", style: .cancel, handler: nil);
            alert.addAction(ok);
            alert.addAction(cancel);
            self.present(alert, animated: true, completion: nil);
        } else {
            self.navigationController?.popViewController(animated: true);
        }
    }
    
    @objc func rightClick(sender: UIButton) -> Void {
        self.textView.resignFirstResponder();
        if self.textView.text == nil || self.textView.text.count <= 0 {
            self.view.makeToast("请输入内容", duration: 1.0, position: .center)
            return;
        }
        
        var dict = [String:String]();
        dict["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"
        dict["Accept-Encoding"] = "gzip, deflate"
        dict["Content-Type"] = "application/x-www-form-urlencoded"
        
    
        let uuid = GuangGuAccount.shareInstance.cookie;
        let para = [
            "tid": self.commentID,
            "content": self.textView.text!,
            "_xsrf": uuid
        ]
        
        //        dict["Cookie"] = "_xsrf=" + uuid;
        //        dict["Referer"] = self.commentURLString;
        //        dict["Host"] = "www.guanggoo.com";
        //        dict["Origin"] = GUANGGUSITE;
        //        dict["User-Agent"] =  USER_AGENT;
        //        dict["Connection"] = "keep-alive";
        //        dict["Cache-Control"] = "max-age=0";
        
        MBProgressHUD.showAdded(to: self.view, animated: true);
        
        //登录
        Alamofire.request(self.commentURLString, method: .post, parameters: para, headers: dict).responseString { (response) in
            MBProgressHUD.hide(for: self.view, animated: true);
            switch(response.result) {
            case .success( _):
                if let completion = self._completion {
                    completion(true);
                }
                self.navigationController?.popViewController(animated: true);
                break;
            case .failure(_):
                self.view.makeToast("回复失败！")
                if let completion = self._completion {
                    completion(false);
                }
                break;
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.textView.resignFirstResponder();
    }
    
    
    @objc func keyboardWillShow(notification: NSNotification) {
        //在真机上有自定义键盘，第一次打开键盘此消息会响应两次
        if let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double,let keyboardFrame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? CGRect{
            UIView.animate(withDuration: duration, animations: {
                if self.view.frame.origin.y < 0,self.keyboardOffset > 0 {
                    self.view.frame.origin.y += self.keyboardOffset;
                }
                self.keyboardOffset = keyboardFrame.height;
                self.view.frame.origin.y -= self.keyboardOffset;
                self.containerView.snp.updateConstraints({ (make) in
                    make.top.equalTo(self.topLayoutGuide.snp.bottom).offset(10+self.keyboardOffset);
                })
                self.view.layoutIfNeeded();
                self.view.updateConstraintsIfNeeded();
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double,let _ = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? CGRect {
            UIView.animate(withDuration: duration, animations: {
                self.view.frame.origin.y = self.originY;
                self.containerView.snp.updateConstraints({ (make) in
                    make.top.equalTo(self.topLayoutGuide.snp.bottom).offset(10);
                })
                self.view.setNeedsLayout();
                self.view.layoutIfNeeded();
            })
        }
    }
    
    
    func OnPushVC(msg: NSDictionary) {
        if let msgtype = msg["MSGTYPE"] as? String {
            if msgtype == "InsertContent" {
                if let insertContent = msg["PARAM1"] as? String {
                    let text = self.textView.text + insertContent;
                    self.textView.text = text;
                }
            }
            else if msgtype == "CloseKeyboard" {
                self.textView.resignFirstResponder();
            }
        }
    }
}


class GGMentionedBindingParser: NSObject ,YYTextParser{
    var regex:NSRegularExpression
    override init() {
        self.regex = try! NSRegularExpression(pattern: "@(\\S+)\\s", options: [.caseInsensitive])
        super.init()
    }
    
    func parseText(_ text: NSMutableAttributedString?, selectedRange: NSRangePointer?) -> Bool {
        guard let text = text else {
            return false;
        }
        self.regex.enumerateMatches(in: text.string, options: [.withoutAnchoringBounds], range: text.yy_rangeOfAll()) { (result, flags, stop) -> Void in
            if let result = result {
                let range = result.range
                if range.location == NSNotFound || range.length < 1 {
                    return ;
                }
                
                if  text.attribute(NSAttributedStringKey(rawValue: YYTextBindingAttributeName), at: range.location, effectiveRange: nil) != nil  {
                    return ;
                }
                
                let bindlingRange = NSMakeRange(range.location, range.length-1)
                let binding = YYTextBinding()
                binding.deleteConfirm = true ;
                text.yy_setTextBinding(binding, range: bindlingRange)
                text.yy_setColor(UIColor.init(red: 0, green: 132.0/255.0, blue: 1, alpha: 1), range: bindlingRange)
            }
        }
        return false;
    }
    
    
    
    
}
