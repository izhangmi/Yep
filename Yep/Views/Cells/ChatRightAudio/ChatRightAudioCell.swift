//
//  ChatRightAudioCell.swift
//  Yep
//
//  Created by NIX on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ChatRightAudioCell: ChatRightBaseCell {

    var audioPlayedDuration: Double = 0 {
        willSet {
            updateAudioInfoViews()
        }
    }

    var playing: Bool = false {
        willSet {
            if newValue != playing {
                if newValue {
                    playButton.setImage(UIImage(named: "icon_pause"), forState: .Normal)
                } else {
                    playButton.setImage(UIImage(named: "icon_play"), forState: .Normal)
                }
            }
        }
    }

    lazy var audioContainerView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var bubbleImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "right_tail_bubble"))
        imageView.tintColor = UIColor.rightBubbleTintColor()
        return imageView
    }()

    lazy var sampleView: SampleView = {
        let view = SampleView()
        view.sampleColor = UIColor.rightWaveColor()
        view.userInteractionEnabled = false
        return view
    }()

    lazy var audioDurationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .Center
        label.textColor = UIColor.whiteColor()
        return label
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_play"), forState: .Normal)

        button.userInteractionEnabled = false
        button.tintColor = UIColor.whiteColor()
        button.tintAdjustmentMode = .Normal

        return button
    }()

    typealias AudioBubbleTapAction = () -> Void
    var audioBubbleTapAction: AudioBubbleTapAction?

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(audioContainerView)
        audioContainerView.addSubview(bubbleImageView)
        audioContainerView.addSubview(playButton)
        audioContainerView.addSubview(sampleView)
        audioContainerView.addSubview(audioDurationLabel)

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        bubbleImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatRightAudioCell.tapMediaView))
        bubbleImageView.addGestureRecognizer(tap)

        prepareForMenuAction = { otherGesturesEnabled in
            tap.enabled = otherGesturesEnabled
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tapMediaView() {
        audioBubbleTapAction?()
    }

    func configureWithMessage(message: Message, audioPlayedDuration: Double, audioBubbleTapAction: AudioBubbleTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.message = message
        self.user = message.fromFriend

        self.audioBubbleTapAction = audioBubbleTapAction

        self.audioPlayedDuration = audioPlayedDuration

        YepDownloader.downloadAttachmentsOfMessage(message, reportProgress: { _, _ in })

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }

        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        UIView.performWithoutAnimation { [weak self] in
            self?.updateAudioInfoViews()
        }
    }

    func updateAudioInfoViews() {

        if let message = message {

            if let (audioDuration, audioSamples) = audioMetaOfMessage(message) {

                var simpleViewWidth = CGFloat(audioSamples.count) * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap()) - YepConfig.audioSampleGap() // 最后最后一个 gap 不要
                simpleViewWidth = max(YepConfig.minMessageSampleViewWidth, simpleViewWidth)
                let width = 60 + simpleViewWidth
                audioContainerView.frame = CGRect(x: CGRectGetMinX(avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: bounds.height)
                dotImageView.center = CGPoint(x: CGRectGetMinX(audioContainerView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(audioContainerView.frame))

                sampleView.samples = audioSamples

                audioDurationLabel.text = NSString(format: "%.1f\"", audioDuration) as String

                sampleView.progress = CGFloat(audioPlayedDuration / audioDuration)

            } else {
                sampleView.progress = 0

                let width = 60 + 15 * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap())
                audioContainerView.frame = CGRect(x: CGRectGetMinX(avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: bounds.height)
                dotImageView.center = CGPoint(x: CGRectGetMinX(audioContainerView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(audioContainerView.frame))

                println(dotImageView.frame)

                audioDurationLabel.text = ""
            }

            bubbleImageView.frame = audioContainerView.bounds
            playButton.frame = CGRect(x: 6, y: 5, width: 30, height: 30)
            sampleView.frame = CGRect(x: 41, y: 0, width: audioContainerView.bounds.width - 60, height: audioContainerView.bounds.height)
            audioDurationLabel.frame = sampleView.frame

            if let audioPlayer = YepAudioService.sharedManager.audioPlayer {
                if audioPlayer.playing {
                    if let playingMessage = YepAudioService.sharedManager.playingMessage {
                        if message.messageID == playingMessage.messageID {
                            playing = true

                            return
                        }
                    }
                }
            }

            if let audioPlayer = YepAudioService.sharedManager.audioPlayer {
                if audioPlayer.playing {
                    if let playingMessage = YepAudioService.sharedManager.playingMessage {
                        if message.messageID == playingMessage.messageID {
                            playing = true
                            
                            return
                        }
                    }
                }
            }
        }
        
        playing = false
    }
}

