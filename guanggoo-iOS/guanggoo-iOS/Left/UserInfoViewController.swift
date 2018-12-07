//
//  UserInfoViewController.swift
//  guanggoo-iOS
//
//  Created by tdx on 2017/12/25.
//  Copyright © 2017年 tdx. All rights reserved.
//

import UIKit
import SnapKit
import SDWebImage
import SwiftSoup
import MBProgressHUD

class UserInfoViewController: UIViewController ,UITableViewDelegate,UITableViewDataSource{

    //MARK: - property
    weak var vcDelegate:GuangGuVCDelegate?
    fileprivate var mURLString = "";
    
    fileprivate var _tableView: UITableView!;
    fileprivate var tableView: UITableView {
        get {
            guard _tableView == nil else {
                return _tableView;
            }
            
            _tableView = UITableView.init(frame: CGRect.zero, style: .plain);
            _tableView.delegate = self;
            _tableView.dataSource = self;
            _tableView.backgroundColor = UIColor.white;
            _tableView.allowsSelection = true;
            _tableView.separatorStyle = .none;
            
            return _tableView;
        }
    }
    
    fileprivate var userImageURL:String?;
    fileprivate var _userImageView: UIImageView!
    fileprivate var userImageView: UIImageView {
        get {
            guard _userImageView == nil else {
                return _userImageView;
            }
            _userImageView = UIImageView.init();
            return _userImageView;
        }
    }
    
    fileprivate var userNameText:String?
    fileprivate var userLinkText:String?
    fileprivate var _userNameLabel: UILabel!
    fileprivate var userNameLabel: UILabel {
        get {
            guard _userNameLabel == nil else {
                return _userNameLabel;
            }
            _userNameLabel = UILabel.init();
            _userNameLabel.backgroundColor = UIColor.white;
            _userNameLabel.font = UIFont.systemFont(ofSize: 14);
            _userNameLabel.textColor = UIColor.black;
            return _userNameLabel;
        }
    }
    
    fileprivate var numberString:String?
    fileprivate var _numberLabel: UILabel!
    fileprivate var numberLabel: UILabel {
        get {
            guard _numberLabel == nil else {
                return _numberLabel;
            }
            _numberLabel = UILabel.init();
            _numberLabel.backgroundColor = UIColor.white;
            _numberLabel.font = UIFont.systemFont(ofSize: 14);
            _numberLabel.textColor = UIColor.black;
            return _numberLabel;
        }
    }
    
    fileprivate var createTimeString:String?
    fileprivate var _createTimeLabel: UILabel!
    fileprivate var createTimeLabel: UILabel {
        get {
            guard _createTimeLabel == nil else {
                return _createTimeLabel;
            }
            _createTimeLabel = UILabel.init();
            _createTimeLabel.backgroundColor = UIColor.white;
            _createTimeLabel.font = UIFont.systemFont(ofSize: 14);
            _createTimeLabel.textColor = UIColor.black;
            return _createTimeLabel;
        }
    }
    
    //MARK: - function
    
    required init(urlString : String) {
        super.init(nibName: nil, bundle: nil);
        
        self.mURLString = urlString;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let yourBackImage = UIImage(named: "ic_back")?.withRenderingMode(.alwaysOriginal)
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        
        self.view.addSubview(self.tableView);
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(self.view);
            if #available(iOS 11, *) {
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottomMargin);
            } else {
                make.bottom.equalTo(self.view);
            }
        }
        
        self.view.backgroundColor = GuangGuColor.sharedInstance.getColor(node: "Default", name: "BackColor");
        self.navigationController?.navigationBar.barTintColor = GuangGuColor.sharedInstance.getColor(node: "TOPBAR", name: "BackColor");
        self.navigationController?.navigationBar.isTranslucent = false;
        if let color = GuangGuColor.sharedInstance.getColor(node: "TOPBAR", name: "TxtColor") {
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): color];
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        if self.userNameText == nil {
            MBProgressHUD.showAdded(to: self.view, animated: true);
            DispatchQueue.global(qos: .background).async {
                self.loadData(urlString: self.mURLString);
                DispatchQueue.main.async {
                    if let count = self.userNameText?.count,count > 0 {
                        self.userNameLabel.text = self.userNameText;
                        self.title = self.userNameText;
                    }
                    if let count = self.userImageURL?.count,count > 0 {
                        self.userImageView.sd_setImage(with: URL.init(string: self.userImageURL!), completed: nil);
                    }
                    if let count = self.numberString?.count,count > 0 {
                        self.numberLabel.text = self.numberString;
                    }
                    if let count = self.createTimeString?.count,count > 0 {
                        self.createTimeLabel.text = self.createTimeString;
                    }
                    self.tableView.reloadData();
                    MBProgressHUD.hide(for: self.view, animated: true);
                }
            }
        }
    }
    
    func loadData(urlString:String) -> Void {
        guard let myURL = URL(string: urlString) else {
            print("Error: \(urlString) doesn't seem to be a valid URL");
            return
        }
        do {
            let myHTMLString = try String(contentsOf: myURL, encoding: .utf8)
            
            do{
                let doc: Document = try SwiftSoup.parse(myHTMLString);
                //页数
                let profileElements = try doc.getElementsByClass("profile");
                for object in profileElements {
                    let userNameElement = try object.getElementsByClass("username");
                    let userNameText = try userNameElement.text();
                    self.userNameText = userNameText;
                    
                    let uiHeaderElements = try object.getElementsByClass("ui-header");
                    let imageText = try uiHeaderElements.select("a").select("img").attr("src");
                    self.userImageURL = imageText;
                    
                    let userLinkElement = try uiHeaderElements.select("a");
                    let userLinkText = try userLinkElement.attr("href");
                    self.userLinkText = userLinkText;
                    
                    let numberElement = try object.getElementsByClass("number");
                    let numberText = try numberElement.text();
                    self.numberString = numberText;
                    
                    let sinceElement = try object.getElementsByClass("since");
                    let sinceText = try sinceElement.text();
                    self.createTimeString = sinceText;
                }
            }catch Exception.Error(let type, let message)
            {
                print("Type:\(type) Error:\(message)");
            }catch{
                print("error");
            }
            
        } catch let error {
            print("Error: \(error)");
        }
    }
    
    //MARK: - UITableView Delegate DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = self.userNameText?.count,count > 0 {
            if GuangGuAccount.shareInstance.user?.userName == self.userNameText {
                return 4;
            }
            else {
                return 3;
            }
        }
        return 0;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 110;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44;
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView.init();
        view.addSubview(self.userImageView);
        self.userImageView.snp.makeConstraints { (make) in
            make.left.equalTo(view).offset(20);
            make.top.equalTo(view).offset(15);
            make.bottom.equalTo(view).offset(-15);
            make.width.equalTo(self.userImageView.snp.height);
        }
        view.addSubview(self.userNameLabel);
        self.userNameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.userImageView.snp.right).offset(10);
            make.top.equalTo(self.userImageView);
            make.height.equalTo(26);
            make.width.equalTo(200);
        }
        view.addSubview(self.numberLabel);
        self.numberLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.userImageView.snp.right).offset(10);
            make.top.equalTo(self.userNameLabel.snp.bottom);
            make.height.equalTo(26);
            make.width.equalTo(200);
        }
        view.addSubview(self.createTimeLabel);
        self.createTimeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.userImageView.snp.right).offset(10);
            make.top.equalTo(self.numberLabel.snp.bottom);
            make.height.equalTo(26);
            make.width.equalTo(200);
        }
        return view;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "LEFTVIEWCELL" + String(indexPath.row);
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier);
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: identifier);
            switch indexPath.row {
            case 0:
                if let userName = self.userNameText {
                    cell!.textLabel?.text = userName + "的主题";
                }
                else {
                    cell!.textLabel?.text = "他的主题";
                }
                cell!.textLabel?.textColor = UIColor.black;
                cell!.textLabel?.font = UIFont.systemFont(ofSize: 16);
                cell!.accessoryType = .disclosureIndicator;
                break;
            case 1:
                if let userName = self.userNameText {
                    cell!.textLabel?.text = userName + "的回复";
                }
                else {
                    cell!.textLabel?.text = "他的回复";
                }
                cell!.textLabel?.textColor = UIColor.black;
                cell!.textLabel?.font = UIFont.systemFont(ofSize: 16);
                cell!.accessoryType = .disclosureIndicator;
                break;
            case 2:
                if let userName = self.userNameText {
                    cell!.textLabel?.text = userName + "的收藏";
                }
                else {
                    cell!.textLabel?.text = "他的收藏";
                }
                cell!.textLabel?.textColor = UIColor.black;
                cell!.textLabel?.font = UIFont.systemFont(ofSize: 16);
                cell!.accessoryType = .disclosureIndicator;
                break;
            case 3:
                if let userName = self.userNameText {
                    cell!.textLabel?.text = userName + "的黑名单";
                }
                cell!.textLabel?.textColor = UIColor.black;
                cell!.textLabel?.font = UIFont.systemFont(ofSize: 16);
                cell!.accessoryType = .disclosureIndicator;
                break;
            default:
                break;
            }
        }
        cell!.backgroundColor = UIColor.clear;
        cell!.selectionStyle = .none;
        return cell!;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            if var userLink = self.userLinkText,let userName = self.userNameText {
                if userLink[userLink.startIndex] == "/" {
                    userLink.removeFirst();
                }
                if let delegate = self.vcDelegate {
                    let msg = NSMutableDictionary.init();
                    msg["MSGTYPE"] = "CenterViewController";
                    let vc = CenterViewController.init(urlString: GUANGGUSITE + userLink + "/topics");
                    vc.title = userName + "的主题";
                    msg["PARAM1"] = vc;
                    delegate.OnPushVC(msg: msg);
                }
            }
            break;
        case 1:
            if var userLink = self.userLinkText,let userName = self.userNameText {
                if userLink[userLink.startIndex] == "/" {
                    userLink.removeFirst();
                }
                if let delegate = self.vcDelegate {
                    let msg = NSMutableDictionary.init();
                    msg["MSGTYPE"] = "CenterViewController";
                    let vc = UserCommentViewController.init(urlString: GUANGGUSITE + userLink + "/replies");
                    vc.title = userName + "的回复";
                    vc.vcDelegate = self.vcDelegate;
                    msg["PARAM1"] = vc;
                    delegate.OnPushVC(msg: msg);
                }
            }
            break;
        case 2:
            if var userLink = self.userLinkText,let userName = self.userNameText {
                if userLink[userLink.startIndex] == "/" {
                    userLink.removeFirst();
                }
                if let delegate = self.vcDelegate {
                    let msg = NSMutableDictionary.init();
                    msg["MSGTYPE"] = "CenterViewController";
                    let vc = CenterViewController.init(urlString: GUANGGUSITE + userLink + "/favorites");
                    vc.needRefreshInAppear = true;
                    vc.title = userName + "的收藏";
                    msg["PARAM1"] = vc;
                    delegate.OnPushVC(msg: msg);
                }
            }
            break;
        case 3:
            if let delegate = self.vcDelegate {
                let msg = NSMutableDictionary.init();
                msg["MSGTYPE"] = "PushViewController";
                let vc = BlacklistViewController.init(nibName: nil, bundle: nil);
                vc.title = "黑名单";
                msg["PARAM1"] = vc;
                delegate.OnPushVC(msg: msg);
            }
            break;
        default:
            break;
        }
    }

}
