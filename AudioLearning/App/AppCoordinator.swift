//
//  AppCoordinator.swift
//  AudioLearning
//
//  Created by Han Chen on 2019/9/11.
//  Copyright © 2019 cshan. All rights reserved.
//

import UIKit
import RxSwift

final class AppCoordinator: BaseCoordinator<Void> {

    private let window: UIWindow

    required init(window: UIWindow) {
        self.window = window
    }

    override func start() -> Observable<Void> {
        let episodeCoordinator = EpisodeCoordinator(window: window)
        return coordinate(to: episodeCoordinator)
    }
}
