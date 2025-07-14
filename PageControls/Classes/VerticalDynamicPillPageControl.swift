import UIKit

@IBDesignable
open class VerticalDynamicPillPageControl: UIView {

    // MARK: - Configuration
    @IBInspectable open var pillSize: CGSize = CGSize(width: 2.5, height: 4) {
        didSet { updateLayout() }
    }

    @IBInspectable open var activePillSize: CGSize = CGSize(width: 2.5, height: 5) {
        didSet { updateLayout() }
    }

    @IBInspectable open var spacing: CGFloat = 1 {
        didSet { updateLayout() }
    }

    @IBInspectable open var activeColor: UIColor = .white {
        didSet { activeDotLayer.backgroundColor = activeColor.cgColor }
    }

    @IBInspectable open var inactiveColor: UIColor = UIColor.white.withAlphaComponent(0.3) {
        didSet { dotLayers.forEach { $0.backgroundColor = inactiveColor.cgColor } }
    }

    @IBInspectable open var numberOfPages: Int = 0 {
        didSet {
            guard numberOfPages >= 0 else {
                numberOfPages = 0
                return
            }
            recreateDots()
        }
    }

    private var _currentPage: Int = 0
    open var currentPage: Int {
        get { return _currentPage }
        set {
            let newPage = max(0, min(newValue, numberOfPages - 1))
            guard _currentPage != newPage else { return }
            _currentPage = newPage
            updateCurrentPage()
        }
    }

    open var progress: CGFloat = 0 {
        didSet {
            let newProgress = max(0, min(progress, CGFloat(numberOfPages - 1)))
            guard abs(newProgress - oldValue) > 0.001 else { return }
            progress = newProgress
            updateProgress()
        }
    }

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var dotLayers: [CALayer] = []
    private let activeDotLayer = CALayer()
    private var animator: UIViewPropertyAnimator?

    // Spring animation for vertical movement
    private let springAnimation: CASpringAnimation = {
        let animation = CASpringAnimation(keyPath: "position.y")
        animation.damping = 15
        animation.stiffness = 100
        animation.mass = 0.5
        animation.initialVelocity = 0
        animation.duration = 0.5
        return animation
    }()

    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        scrollView.isUserInteractionEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        activeDotLayer.backgroundColor = activeColor.cgColor
        activeDotLayer.cornerRadius = activePillSize.width/2
        contentView.layer.addSublayer(activeDotLayer)
    }

    // MARK: - Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    private func updateLayout() {
        scrollView.frame = bounds
        let contentHeight = CGFloat(numberOfPages) * (pillSize.height + spacing) - spacing
        contentView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: contentHeight)
        scrollView.contentSize = contentView.bounds.size

        updateDotFrames()
        updateCurrentPage(animated: false)
    }

    // MARK: - Dots Management
    private func recreateDots() {
        dotLayers.forEach { $0.removeFromSuperlayer() }
        dotLayers = []

        for _ in 0..<numberOfPages {
            let layer = CALayer()
            layer.backgroundColor = inactiveColor.cgColor
            layer.cornerRadius = pillSize.width/2
            contentView.layer.insertSublayer(layer, below: activeDotLayer)
            dotLayers.append(layer)
        }

        setNeedsLayout()
    }

    private func updateDotFrames() {
        for (index, layer) in dotLayers.enumerated() {
            layer.frame = CGRect(
                x: bounds.midX - pillSize.width/2,
                y: CGFloat(index) * (pillSize.height + spacing),
                width: pillSize.width,
                height: pillSize.height
            )
        }
    }

    // MARK: - Page Updates
    private func updateCurrentPage(animated: Bool = true) {
        guard numberOfPages > 0 else { return }

        let targetFrame = frameForActiveDot(at: currentPage)
        let targetOffset = targetFrame.midY - bounds.height/2

        if animated {
            // Spring animation for active dot
            springAnimation.fromValue = activeDotLayer.position.y
            springAnimation.toValue = targetFrame.midY
            activeDotLayer.add(springAnimation, forKey: "springAnimation")
            activeDotLayer.frame = targetFrame

            // Scroll animation with bounce
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
                    self.scrollView.contentOffset.y = max(0, min(targetOffset, self.scrollView.contentSize.height - self.bounds.height))
                }
            )
        } else {
            activeDotLayer.frame = targetFrame
            scrollView.contentOffset.y = max(0, min(targetOffset, scrollView.contentSize.height - bounds.height))
        }
    }

    private func updateProgress() {
        let page = Int(round(progress))
        if currentPage != page {
            currentPage = page
        }

        let progressOffset = progress - CGFloat(page)
        guard abs(progressOffset) > 0.001 else { return }

        let currentFrame = frameForActiveDot(at: page)
        let nextFrame = frameForActiveDot(at: min(page + 1, numberOfPages - 1))

        let interpolatedFrame = CGRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y + (nextFrame.origin.y - currentFrame.origin.y) * progressOffset,
            width: currentFrame.width,
            height: currentFrame.height + (nextFrame.height - currentFrame.height) * progressOffset
        )

        let targetOffset = interpolatedFrame.midY - bounds.height/2

        // Smooth animation for progress
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                self.activeDotLayer.frame = interpolatedFrame
                self.scrollView.contentOffset.y = max(0, min(targetOffset, self.scrollView.contentSize.height - self.bounds.height))
            }
        )
    }

    private func frameForActiveDot(at index: Int) -> CGRect {
        let dotFrame = CGRect(
            x: bounds.midX - pillSize.width/2,
            y: CGFloat(index) * (pillSize.height + spacing),
            width: pillSize.width,
            height: pillSize.height
        )

        return CGRect(
            x: dotFrame.midX - activePillSize.width/2,
            y: dotFrame.midY - activePillSize.height/2,
            width: activePillSize.width,
            height: activePillSize.height
        )
    }

    private func setCurrentPage(_ page: Int, animated: Bool) {
        currentPage = page
        progress = CGFloat(page)
    }

    private func setProgress(_ value: CGFloat, animated: Bool) {
        progress = value
        if !animated {
            updateProgress()
        }
    }
}
