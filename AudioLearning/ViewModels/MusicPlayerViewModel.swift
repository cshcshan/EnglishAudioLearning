//
//  MusicPlayerViewModel.swift
//  AudioLearning
//
//  Created by Han Chen on 2019/9/12.
//  Copyright © 2019 cshan. All rights reserved.
//

import RxSwift
import RxCocoa

class MusicPlayerViewModel {
    
    // Inputs
    private(set) var tappedPlayPause: AnyObserver<Void>
    private(set) var settingNewAudio: AnyObserver<URL>
    private(set) var forward10Seconds: AnyObserver<Void>!
    private(set) var rewind10Seconds: AnyObserver<Void>!
    private(set) var speedUp: AnyObserver<Float>!
    private(set) var speedDown: AnyObserver<Float>!
    private(set) var changeSpeed: AnyObserver<Float>! // will call 'change speed' when playing music 
    private(set) var changeAudioPosition: AnyObserver<Float>!
    
    // Outputs
    private(set) var readyToPlay: Driver<Void>!
    private(set) var isPlaying: Driver<Bool>!
    private(set) var speedRate: Driver<Float>!
    private(set) var currentTime: Driver<String>!
    private(set) var totalTime: Driver<String>!
    private(set) var currentSeconds: Driver<Float>!
    private(set) var totalSeconds: Driver<Float>!
    private(set) var loadingBufferRate: Driver<Float>!
    
    private let disposeBag = DisposeBag()
    private var url: URL!
    private var player: HCAudioPlayerProtocol
    
    init(player: HCAudioPlayerProtocol) {
        self.player = player
        
        // Inputs
        
        let settingNewAudioSubject = PublishSubject<URL>()
        settingNewAudio = settingNewAudioSubject.asObserver()
        let tappedPlayPauseSubject = PublishSubject<Void>()
        tappedPlayPause = tappedPlayPauseSubject.asObserver()
        isPlaying = Observable.of(tappedPlayPauseSubject.asObservable().map({ $0 as AnyObject }),
                                  settingNewAudioSubject.asObservable().map({ $0 as AnyObject }),
                                  player.status.map({ $0 as AnyObject }))
            .merge()
            .scan(false, accumulator: { [weak self] (aggregateValue, newValue) -> Bool in
                guard let `self` = self else { return false }
                if let status = newValue as? HCAudioPlayer.Status {
                    if status == .finish {
                        return false
                    } else {
                        return aggregateValue
                    }
                } else if let url = newValue as? URL {
                    guard self.url != url else {
                        // if self.url == url, then isPlaying will not be affected
                        return aggregateValue
                    }
                    self.setAudio(url: url)
                    return false
                } else {
                    if self.url == nil {
                        return false
                    } else {
                        self.playMusic(!aggregateValue)
                        return !aggregateValue
                    }
                }
            })
            .startWith(false)
            .asDriver(onErrorJustReturn: false)
        
        let forward10SecondsSubject = PublishSubject<Void>()
        forward10Seconds = forward10SecondsSubject.asObserver()
        forward10SecondsSubject
            .subscribe(onNext: { [weak self] (_) in
                guard let player = self?.player else { return }
                player.forward.onNext(10)
            })
            .disposed(by: disposeBag)
        let rewind10SecondsSubject = PublishSubject<Void>()
        rewind10Seconds = rewind10SecondsSubject.asObserver()
        rewind10SecondsSubject
            .subscribe(onNext: { [weak self] (_) in
                guard let player = self?.player else { return }
                player.rewind.onNext(10)
            })
            .disposed(by: disposeBag)
        
        speedUp = player.speedUp
        speedDown = player.speedDown
        
        let changeSpeedSubject = PublishSubject<Float>()
        changeSpeed = changeSpeedSubject.asObserver()
        Observable.combineLatest(isPlaying.asObservable(),
                                 changeSpeedSubject.asObservable())
            .debug("combine isPlaying and changeSpeedSubject")
            .subscribe(onNext: { [weak self] (isPlaying, speedRate) in
                guard isPlaying else { return }
                guard let player = self?.player else { return }
                player.changeSpeed.onNext(speedRate)
            })
            .disposed(by: disposeBag)
        
        let changeAudioPositionSubject = PublishSubject<Float>()
        changeAudioPosition = changeAudioPositionSubject.asObserver()
        changeAudioPositionSubject
            .subscribe(onNext: { [weak self] (position) in
                guard let player = self?.player else { return }
                player.changeAudioPosition.onNext(position)
            })
            .disposed(by: disposeBag)
        
        // Outputs
        
        let readyToPlaySubject = PublishSubject<Void>()
        readyToPlay = readyToPlaySubject.asDriver(onErrorJustReturn: ())
        player.status
            .subscribe(onNext: { (status) in
                if status == .readyToPlay {
                    readyToPlaySubject.onNext(())
                }
            })
            .disposed(by: disposeBag)
        speedRate = player.speedRate
            .asDriver(onErrorJustReturn: 0)
        
        currentTime = player.currentSeconds
            .map({ [weak self] (seconds) -> String in
                guard let `self` = self else { return "" }
                return self.convertTime(seconds: seconds)
            })
            .asDriver(onErrorJustReturn: "")
        totalTime = player.totalSeconds
            .map({ [weak self] (seconds) -> String in
                guard let `self` = self else { return "" }
                return self.convertTime(seconds: seconds)
            })
            .asDriver(onErrorJustReturn: "")
        currentSeconds = player.currentSeconds
            .map({ Float($0) })
            .asDriver(onErrorJustReturn: 0)
        totalSeconds = player.totalSeconds
            .map({ Float($0) })
            .asDriver(onErrorJustReturn: 0)
        
        loadingBufferRate = player.loadingBufferPercent
            .map({ Float($0 / 100) })
            .asDriver(onErrorJustReturn: 0)
    }
    
    private func setAudio(url: URL) {
        player.newAudio.onNext(url)
        self.url = url
    }
    
    private func playMusic(_ isPlay: Bool) {
        if isPlay {
            player.play.onNext(())
        } else {
            player.pause.onNext(())
        }
    }
    
    private func convertTime(seconds: Double) -> String {
        let minute = Int(seconds / 60)
        let second = Int(seconds.truncatingRemainder(dividingBy: 60))
        let minuteStr = String(format: "%02d", minute)
        let secondStr = String(format: "%02d", second)
        return "\(minuteStr):\(secondStr)"
    }
}
