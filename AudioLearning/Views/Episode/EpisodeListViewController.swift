//
//  EpisodeListViewController.swift
//  AudioLearning
//
//  Created by Han Chen on 2019/9/3.
//  Copyright © 2019 cshan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class EpisodeListViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    
    var viewModel: EpisodeListViewModel!
    var selectedCell: EpisodeCell?
    
    private var showEmptyView: ((UITableView) -> Void) = { tableView in
        tableView.showEmptyView(Appearance.backgroundColor,
                                title: ("No episodes of 6 Minute English", Appearance.textColor),
                                message: ("Wait to download episode list from server.", Appearance.textColor.withAlphaComponent(0.6)))
    }
    private var hideEmptyView: ((UITableView) -> Void) = { tableView in
        tableView.hideEmptyView(nil, separatorStyle: .singleLine)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatePlayingButton()
    }
        
    override func setupNotification() {
        super.setupNotification()
        NotificationCenter.default.rx
            .notification(.isPlaying)
            .take(until: self.rx.deallocated)
            .subscribe(onNext: { [weak self] (notification) in
                guard let self = self else { return }
                guard let userInfo = notification.userInfo else { return }
                guard let isPlaying = userInfo["isPlaying"] as? Bool else { return }
                self.showPlayingButton(self.viewModel, to: self.tableView, isShow: isPlaying)
            })
            .disposed(by: disposeBag)
    }
    
    override func setupUIColor() {
        super.setupUIColor()
        view.backgroundColor = Appearance.backgroundColor
        tableView.backgroundColor = Appearance.secondaryBgColor
        tableView.separatorColor = tableView.backgroundColor
        if tableView.backgroundView != nil { showEmptyView(tableView) }
        refreshControl.tintColor = Appearance.textColor
    }
    
    private func setupUI() {
        tableView.contentInsetAdjustmentBehavior = .never
        setupNavigationBar()
        // refreshControl
        if !isUITesting {
            refreshControl.sendActions(for: .valueChanged)
            tableView.contentOffset = CGPoint(x: 0, y: -refreshControl.frame.height) // for changing refreshControl's tintColor
            tableView.insertSubview(refreshControl, at: 0)
        }
        // tableView
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 165
        tableView.separatorStyle = .none
        showEmptyView(tableView)
        // themeButton
        showThemeButton(viewModel, to: tableView)
    }
    
    private func setupNavigationBar() {
        let image = UIImage(named: "dictionary-filled")
        let vocabularyItem = UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
        vocabularyItem.accessibilityIdentifier = "VocabularyButton"
        vocabularyItem.rx.tap
            .bind(to: viewModel.tapVocabulary)
            .disposed(by: disposeBag)
        navigationItem.rightBarButtonItems = [vocabularyItem]
        navigationItem.title = "6 Minute English"
    }

    private func setupBindings() {
        // ViewModel's output to the ViewController
        viewModel.episodes
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak self] (episodes) in
                guard let self = self else { return }
                if episodes.count == 0 {
                    self.showEmptyView(self.tableView)
                } else {
                    self.hideEmptyView(self.tableView)
                }
                self.refreshControl.endRefreshing()
            })
            .bind(to: tableView.rx.items(cellIdentifier: "EpisodeCell", cellType: EpisodeCell.self),
                  curriedArgument: { [weak self] (row, model, cell) in
                    guard let self = self else { return }
                    cell.accessibilityIdentifier = "EpisodeCell_\(row)"
                    cell.selectionStyle = .none
                    self.viewModel.setCellViewModel
                        .take(1)
                        .subscribe(onNext: { (episodeCellViewModel) in
                            cell.viewModel = episodeCellViewModel
                            cell.viewModel?.inputs.load.onNext(model)
                        })
                        .disposed(by: self.disposeBag)
                    self.viewModel.getCellViewModel.onNext(row)
            })
            .disposed(by: disposeBag)
        
        if !isUITesting {
            viewModel.refreshing
                .bind(to: refreshControl.rx.isRefreshing)
                .disposed(by: disposeBag)
        }
        
        viewModel.alert
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (alert) in
                guard let self = self else { return }
                self.showConfirmAlert(title: alert.title,
                                      message: alert.message,
                                      confirmHandler: nil,
                                      completionHandler: nil)
            })
            .disposed(by: disposeBag)
        
        if !isUITesting {
            refreshControl.rx
                .controlEvent(.valueChanged)
                .bind(to: viewModel.reload)
                .disposed(by: disposeBag)
        }
        
        viewModel.getSelectEpisodeCell
            .subscribe(onNext: { [weak self] (indexPath) in
                guard let self = self else { return }
                self.selectedCell = self.tableView.cellForRow(at: indexPath) as? EpisodeCell
            })
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelSelected(EpisodeModel.self)
            .bind(to: viewModel.selectEpisode)
            .disposed(by: disposeBag)
        
        tableView.rx
            .itemSelected
            .bind(to: viewModel.selectIndexPath)
            .disposed(by: disposeBag)
        
        // ViewController's UI actions to ViewModel
        viewModel.initalLoad.onNext(())
    }
}
