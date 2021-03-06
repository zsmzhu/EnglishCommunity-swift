//
//  JFTweetViewController.swift
//  EnglishCommunity-swift
//
//  Created by zhoujianfeng on 16/8/4.
//  Copyright © 2016年 zhoujianfeng. All rights reserved.
//

import UIKit
import YYWebImage
import AudioToolbox

class JFTweetViewController: UIViewController {

    var lastSelectedIndex = 0
    
    /// 当前页码
    var page: Int = 0
    
    /// 动弹模型数组
    var tweets = [JFTweet]()
    
    /// 动弹列表cell重用标识
    let tweetIdentifier = "tweetIdentifier"
    
    /// 加载类型 / 最新new 最热hot 我的me
    var type = "hot"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController?.delegate = self
        
        prepareUI()
        tableView.mj_header = setupHeaderRefresh(self, action: #selector(pullDownRefresh))
        tableView.mj_footer = setupFooterRefresh(self, action: #selector(pullUpMoreData))
        tableView.mj_header.beginRefreshing()
        
        // 监听点击图片的通知
        NotificationCenter.default.addObserver(self, selector: #selector(JFTweetViewController.selectedPicture(_:)), name: NSNotification.Name(rawValue: JFPictureViewCellSelectedPictureNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: JFPictureViewCellSelectedPictureNotification), object: nil)
    }
    
    /**
     准备UI
     */
    fileprivate func prepareUI() {
        
        prepareNavigationBar()
        view.backgroundColor = COLOR_ALL_BG
        view.addSubview(tableView)
    }
    
    /**
     准备导航栏
     */
    fileprivate func prepareNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem.rightItem("MainTagSubIcon", highlightedImage: "MainTagSubIcon", target: self, action: #selector(didTappedRightBarButton(_:)))
    }
    
    /**
     点击了右边按钮
     */
    @objc fileprivate func didTappedRightBarButton(_ barButtonItem: UIBarButtonItem) {
        navigationController?.pushViewController(UIViewController(), animated: true)
    }
    
    /**
     下拉刷新
     */
    @objc fileprivate func pullDownRefresh() {
        page = 1
        updateData(type, page: page, method: 0)
    }
    
    /**
     上拉加载更多
     */
    @objc fileprivate func pullUpMoreData() {
        page += 1
        updateData(type, page: page, method: 1)
    }
    
    /**
     更新数据
     */
    fileprivate func updateData(_ type: String, page: Int, method: Int) {
        
        JFTweet.loadTrendsList(type, page: page) { (tweets) in
            
            self.tableView.mj_header.endRefreshing()
            self.tableView.mj_footer.endRefreshing()
            
            guard let tweets = tweets else {
                self.tableView.mj_footer.endRefreshingWithNoMoreData()
                return
            }
            
            if method == 0 {
                self.tweets = tweets
                
                // 异步播放刷新音效
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.75, execute: {
                    var soundID: SystemSoundID = 0
                    let path = Bundle.main.path(forResource: "refresh", ofType: "wav")!
                    let baseURL = URL(fileURLWithPath: path)
                    AudioServicesCreateSystemSoundID(baseURL as CFURL, &soundID)
                    AudioServicesPlaySystemSound(soundID)
                })
            } else {
                self.tweets += tweets
            }
            
            self.tableView.reloadData()
        }
    }

    /// 内容区域
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 60), style: UITableViewStyle.plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = COLOR_ALL_CELL_NORMAL
        tableView.register(JFTweetListCell.classForCoder(), forCellReuseIdentifier: self.tweetIdentifier)
        return tableView
    }()
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension JFTweetViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let tweet = tweets[indexPath.row]
        if Int(tweet.rowHeight) == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: tweetIdentifier) as! JFTweetListCell
            let height = cell.getRowHeight(tweet)
            tweet.rowHeight = height
        }
        return tweet.rowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tweetIdentifier) as! JFTweetListCell
        cell.tweet = tweets[indexPath.row]
        cell.tweetListCellDelegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let detailVc = JFTweetDetailViewController()
        detailVc.tweet = tweets[indexPath.row]
        navigationController?.pushViewController(detailVc, animated: true)
    }
    
}

// MARK: - JFTweetsListCellDelegate - JFPictureViewCellSelectedPictureNotification
extension JFTweetViewController: JFTweetListCellDelegate {
    
    /**
     点击了 头像
     */
    func tweetListCell(_ cell: JFTweetListCell, didTappedAvatarButton button: UIButton) {
        
        guard let author = cell.tweet?.author else {
            return
        }
        
        let otherUser = JFOtherUserViewController()
        otherUser.userId = author.id
        navigationController?.pushViewController(otherUser, animated: true)
    }
    
    /**
     点击了 赞按钮
     */
    func tweetListCell(_ cell: JFTweetListCell, didTappedLikeButton button: UIButton) {
        
        // 未登录
        if !JFAccountModel.isLogin() {
            present(JFNavigationController(rootViewController: JFLoginViewController(nibName: "JFLoginViewController", bundle: nil)), animated: true, completion: nil)
            return
        }
        
        // 已经登录
        JFNetworkTools.shareNetworkTool.addOrCancelLikeRecord("tweet", sourceID: cell.tweet!.id) { (success, result, error) in
            
            guard let result = result, result["status"] == "success" else {
                print(success, error)
                return
            }
            
            if result["result"]["type"].stringValue == "add" {
                // 赞
                cell.tweet!.likeCount += 1
                cell.tweet!.liked = 1
            } else {
                // 取消赞
                cell.tweet!.likeCount -= 1
                cell.tweet!.liked = 0
            }
            
            self.tableView.reloadData()
        }
    }
    
    /**
     点击了 超链接
     */
    func tweetListCell(_ cell: JFTweetListCell, didTappedSuperLink url: String) {
        print(cell.tweet?.id, url)
    }
    
    /**
     点击了 @昵称
     */
    func tweetListCell(_ cell: JFTweetListCell, didTappedAtUser nickname: String, sequence: Int) {
        
        guard let atUsers = cell.tweet?.atUsers else {
            return
        }
        
        for atUser in atUsers {
            if atUser.nickname == nickname && atUser.sequence == sequence {
                let otherUser = JFOtherUserViewController()
                otherUser.userId = atUser.id
                navigationController?.pushViewController(otherUser, animated: true)
            }
        }
        
    }
    
    // MARK: - 做转场动画
    /**
     选择了动弹配图
     */
    func selectedPicture(_ notification: Notification) {
        guard let models = notification.userInfo?[JFPictureViewCellSelectedPictureModelKey] as? [JFPhotoBrowserModel] else {
            return
        }
        guard let index = notification.userInfo?[JFPictureViewCellSelectedPictureIndexKey] as? Int else {
            return
        }
        
        let photoBrowserVC = JFPhotoBrowserViewController(models: models, selectedIndex: index)
        photoBrowserVC.transitioningDelegate = photoBrowserVC
        photoBrowserVC.modalPresentationStyle = UIModalPresentationStyle.custom
        present(photoBrowserVC, animated: true, completion: nil)
    }
}

// MARK: - UITabBarDelegate
extension JFTweetViewController: UITabBarControllerDelegate {
    
    internal func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        lastSelectedIndex = tabBarController.selectedIndex
        return true
    }
    
    internal func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        if tabBarController.selectedIndex == lastSelectedIndex {
            tableView.mj_header.beginRefreshing()
        }
    }
}
