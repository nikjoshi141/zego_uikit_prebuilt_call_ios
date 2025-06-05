//
//  ZegoStartCallInvitationButton.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/12.
//

import UIKit
import ZegoUIKit
import ZegoPluginAdapter

@objc public protocol ZegoSendCallInvitationButtonDelegate: AnyObject{
    func onPressed(_ errorCode: Int, errorMessage: String?, errorInvitees: [ZegoCallUser]?)
}

@objc public protocol ZegoInvitationButtonHandler: AnyObject {
    func didSendCallInvite(with data: Dictionary<String, AnyObject>?, type: Int)
    func handleInviteError(reason: String)
}

extension ZegoSendCallInvitationButtonDelegate {
//    func onPressed(_ errorCode: Int, errorMessage: String?, errorInvitees: [ZegoCallUser?]?){ }
}

@objc public class ZegoSendCallInvitationButton: UIButton {
    
    @objc public var icon: UIImage? {
        didSet {
            guard let icon = icon else {
                return
            }
            self.setImage(icon, for: .normal)
        }
    }
    @objc public var text: String? {
        didSet {
            self.setTitle(text, for: .normal)
        }
    }
    @objc public var invitees: [String] = []
    @objc public var data: String?
    // 加入RTC 房间的ID，不是 zim 的callID
    @objc public var callID: String?
    @objc public var timeout: UInt32 = 60
    @objc public var type: Int = 0
    @objc public weak var delegate: ZegoSendCallInvitationButtonDelegate?
    @objc public weak var zegoButtonHandler: ZegoInvitationButtonHandler?
    
    @objc public var customData: String?
    
    @objc public var resourceID: String?
    @objc public var callData: String?

    @objc public init(_ type: Int) {
        super.init(frame: CGRect.zero)
        if type == 0 {
            self.setImage(ZegoUIKitCallIconSetType.user_phone_icon.load(), for: .normal)
        } else {
            self.setImage(ZegoUIKitCallIconSetType.user_video_icon.load(), for: .normal)
        }
        self.type = type
        self.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        self.isVideoCall = type == 1 ? true : false
    }
        
    @objc public var isVideoCall: Bool = false {
        didSet {
            self.type = isVideoCall ? 1 : 0
        }
    }
    
    @objc public var inviteeList: [ZegoUIKitUser] = [] {
        didSet {
            self.invitees.removeAll()
            for user in inviteeList {
                if let userID = user.userID {
                    self.invitees.append(userID)
                }
            }
        }
    }
    
    var callInvitationConfig: ZegoUIKitPrebuiltCallInvitationConfig?

    @objc required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc func buttonClick() {
        
        guard let resourceID = self.resourceID,
              let callData = self.callData, !callData.isEmpty
        else {
            print("\nError: Aborting call. Invalid call data")
            zegoButtonHandler?.handleInviteError(reason: "Unable to make a call. Please try again.")
            return
        }
      
        let inviteArr:[ZegoPluginCallUser] = inviteeList.map { model in
            ZegoPluginCallUser(userID: model.userID ?? "", userName:model.userName ?? "", avatar: "")
        }
        
        guard !inviteArr.isEmpty
        else { print("\nDebug: Invalid invitees list"); zegoButtonHandler?.handleInviteError(reason: "Invalid call. There are no invitees present."); return }
        
        ZegoUIKitPrebuiltCallInvitationService.shared.callID = self.callID;
        ZegoUIKitPrebuiltCallInvitationService.shared.sendInvitation(inviteArr, invitationType: isVideoCall ? .videoCall : .voiceCall, timeout: 60, customerData: callData, notificationConfig: ZegoSignalingPluginNotificationConfig(resourceID: resourceID, title: "", message: "")) { [weak self] data in
            guard let self = self else { return }
            zegoButtonHandler?.didSendCallInvite(with: data, type: isVideoCall ? ZegoPluginCallType.videoCall.rawValue : ZegoPluginCallType.voiceCall.rawValue)
        }
    }
    
}
