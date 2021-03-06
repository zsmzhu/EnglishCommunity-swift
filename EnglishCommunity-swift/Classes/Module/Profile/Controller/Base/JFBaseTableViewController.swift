//
//  JFBaseTableViewController.swift
//  BaoKanIOS
//
//  Created by zhoujianfeng on 16/5/5.
//  Copyright © 2016年 六阿哥. All rights reserved.
//

import UIKit

class JFBaseTableViewController: UITableViewController {

    /// 组模型数组
    var groupModels: [JFProfileCellGroupModel]?
    
    let profileIdentifier = "profileCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sectionHeaderHeight = 0.01
        tableView.separatorStyle = .none
        tableView.register(JFProfileCell.classForCoder(), forCellReuseIdentifier: profileIdentifier)
    }
    
}

// MARK: - Table view data source
extension JFBaseTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return groupModels?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupModels![section].cells?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: profileIdentifier) as! JFProfileCell
        let groupModel = groupModels![indexPath.section]
        let cellModel = groupModel.cells![indexPath.row]
        cell.cellModel = cellModel
        // 不是每组最后一个cell就显示分割线
        cell.showLineView = !(indexPath.row == groupModel.cells!.count - 1)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.01 : 10
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return groupModels![section].headerTitle
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return groupModels![section].footerTitle
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cellModel = groupModels![indexPath.section].cells![indexPath.row]
        
        // 如果有可执行代码就执行
        if cellModel.operation != nil {
            cellModel.operation!()
            return
        }
        
        // 如果是箭头类型就跳转控制器
        if cellModel.isKind(of: JFProfileCellArrowModel.classForCoder()) {
            let cellArrow = cellModel as! JFProfileCellArrowModel
            
            /// 目标控制器类
            let destinationVcClass = cellArrow.destinationVc as! UIViewController.Type
            
            let destinationVc = destinationVcClass.init()
            destinationVc.title = cellArrow.title
            navigationController?.pushViewController(destinationVc, animated: true)
        }
        
    }

}
