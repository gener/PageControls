//
//  ViewController.swift
//  PageControls
//
//  Created by Kyle Zaragoza on 8/5/16.
//  Copyright © 2016 Kyle Zaragoza. All rights reserved.
//

import UIKit
import PageControls

class ViewController: UIViewController {

    @IBOutlet weak var snakePageControl: SnakePageControl!
    @IBOutlet weak var filledPageControl: FilledPageControl!
    @IBOutlet weak var pillPageControl: PillPageControl!
    @IBOutlet weak var scrollingPageControl: ScrollingPageControl!
    @IBOutlet weak var dynamicPillPageControl: VerticalDynamicPillPageControl!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update scroll view content size.
        let contentSize = CGSize(width: scrollView.bounds.width * 5,
                                 height: scrollView.bounds.height)
        scrollView.contentSize = contentSize
    }
}


// MARK: - Scroll View Delegate

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x / scrollView.bounds.width
        let progressInPage = scrollView.contentOffset.x - (page * scrollView.bounds.width)
        let progress = CGFloat(page) + progressInPage
        snakePageControl.progress = progress
        filledPageControl.progress = progress
        pillPageControl.progress = progress
        scrollingPageControl.progress = progress
        dynamicPillPageControl.progress = progress
    }
}
