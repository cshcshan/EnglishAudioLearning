//
//  VocabularyDetailViewController.swift
//  AudioLearning
//
//  Created by Han Chen on 2019/9/24.
//  Copyright © 2019 cshan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class VocabularyDetailViewController: BaseViewController, StoryboardGettable {
    
    @IBOutlet weak var wordTextField: UITextField!
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var viewModel: VocabularyDetailViewModel!
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        
    }
    
    private func setupBindings() {
        viewModel.word
            .bind(to: wordTextField.rx.text)
            .disposed(by: disposeBag)
        viewModel.note
            .bind(to: noteTextView.rx.text)
            .disposed(by: disposeBag)
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                let model = VocabularySaveModel(episode: nil,
                                                word: self.wordTextField.text,
                                                note: self.noteTextView.text)
                self.viewModel.save.onNext(model)
            })
            .disposed(by: disposeBag)
        cancelButton.rx.tap
            .bind(to: viewModel.cancel)
            .disposed(by: disposeBag)
    }
}