//
//  ViewController.swift
//  Notice
//
//  Copyright (c) 2023 oasis444. All right reserved.
//

import UIKit
import FirebaseRemoteConfig
import FirebaseAnalytics

class ViewController: UIViewController {

    var remoteConfig: RemoteConfig?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        remoteConfig = RemoteConfig.remoteConfig()
        
        let setting = RemoteConfigSettings()
        setting.minimumFetchInterval = 0
        remoteConfig?.configSettings = setting
        remoteConfig?.setDefaults(fromPlist: "RemoteConfigDefaults")
    }

    override func viewWillAppear(_ animated: Bool) {
        getNotice()
    }
}

extension ViewController {
    private func getNotice() {
        guard let remoteConfig = remoteConfig else { return }
        remoteConfig.fetch { status, error in
            if status == .success {
                print("Config fetched!")
                remoteConfig.activate { changed, error in
                    guard error == nil else {
                        print("Error: \(String(describing: error?.localizedDescription))")
                        return
                    }
                    // 현재는 공지사항을 항상 보기 위해 조건 설정을 안함
//                    if changed {
//                        // 변경사항 생길 시 공지 보여주기
//                    }
                    if self.isNoticeHidden(remoteConfig) == false {
                        DispatchQueue.main.async {
                            let noticeVC = NoticeVC(nibName: "NoticeVC", bundle: nil)
                            noticeVC.modalPresentationStyle = .custom
                            noticeVC.modalTransitionStyle = .crossDissolve
                            
                            let title = (remoteConfig["title"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                            let detail = (remoteConfig["detail"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                            let date = (remoteConfig["date"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                            
                            noticeVC.noticeContents = (title: title, detail: detail, date: date)
                            self.present(noticeVC, animated: true)
                        }
                    } else {
                        self.getPromotionMessage()
                    }
                }
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
        }
    }
    
    private func isNoticeHidden(_ remoteConfig: RemoteConfig) -> Bool {
        return remoteConfig["isHidden"].boolValue
    }
}

// A/B Test
extension ViewController {
    private func getPromotionMessage() {
        guard let remoteConfig = remoteConfig else { return }
        remoteConfig.fetch { status, error in
            if status == .success {
                print("Config fetched!")
//                remoteConfig.activate(completion: nil)
                remoteConfig.activate { changed, error in
                    guard error == nil else {
                        print("Error: \(String(describing: error?.localizedDescription))")
                        return
                    }
                    let message = remoteConfig["message"].stringValue ?? ""
                    DispatchQueue.main.async {
                        self.showEventAlert(message: message)
                    }
                }
            } else {
                guard let error = error else { return }
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

extension ViewController {
    private func showEventAlert(message: String) {
        let alert = UIAlertController(title: "깜짝 이벤트", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            // Google Analytics
            Analytics.logEvent("promotion_alert", parameters: nil)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
}
