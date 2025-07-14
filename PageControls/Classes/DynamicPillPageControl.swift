import UIKit

@IBDesignable
open class DynamicPillPageControl: UIView {

    // MARK: - Configuration
    @IBInspectable open var pillSize: CGSize = CGSize(width: 4, height: 2.5) {
        didSet { updateLayout() }
    }

    @IBInspectable open var activePillSize: CGSize = CGSize(width: 5, height: 2.5) {
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

    // Добавим пружинную анимацию
    private let springAnimation: CASpringAnimation = {
        let animation = CASpringAnimation(keyPath: "position.x")
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
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        activeDotLayer.backgroundColor = activeColor.cgColor
        activeDotLayer.cornerRadius = activePillSize.height/2
        contentView.layer.addSublayer(activeDotLayer)
    }

    // MARK: - Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    private func updateLayout() {
        scrollView.frame = bounds
        let contentWidth = CGFloat(numberOfPages) * (pillSize.width + spacing) - spacing
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: bounds.height)
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
            layer.cornerRadius = pillSize.height/2
            contentView.layer.insertSublayer(layer, below: activeDotLayer)
            dotLayers.append(layer)
        }

        setNeedsLayout()
    }

    private func updateDotFrames() {
        for (index, layer) in dotLayers.enumerated() {
            layer.frame = CGRect(
                x: CGFloat(index) * (pillSize.width + spacing),
                y: bounds.midY - pillSize.height/2,
                width: pillSize.width,
                height: pillSize.height
            )
        }
    }

    // MARK: - Page Updates
    private func updateCurrentPage(animated: Bool = true) {
        guard numberOfPages > 0 else { return }

        let targetFrame = frameForActiveDot(at: currentPage)
        let targetOffset = targetFrame.midX - bounds.width/2

        if animated {
            // Пружинная анимация для активной точки
            springAnimation.fromValue = activeDotLayer.position.x
            springAnimation.toValue = targetFrame.midX
            activeDotLayer.add(springAnimation, forKey: "springAnimation")
            activeDotLayer.frame = targetFrame

            // Анимация скролла с легким "перелетом"
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
                    self.scrollView.contentOffset.x = max(0, min(targetOffset, self.scrollView.contentSize.width - self.bounds.width))
                }
            )
        } else {
            activeDotLayer.frame = targetFrame
            scrollView.contentOffset.x = max(0, min(targetOffset, scrollView.contentSize.width - bounds.width))
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
            x: currentFrame.origin.x + (nextFrame.origin.x - currentFrame.origin.x) * progressOffset,
            y: currentFrame.origin.y,
            width: currentFrame.width + (nextFrame.width - currentFrame.width) * progressOffset,
            height: currentFrame.height
        )

        let targetOffset = interpolatedFrame.midX - bounds.width/2

        // Более плавная анимация для progress
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                self.activeDotLayer.frame = interpolatedFrame
                self.scrollView.contentOffset.x = max(0, min(targetOffset, self.scrollView.contentSize.width - self.bounds.width))
            }
        )
    }

    private func frameForActiveDot(at index: Int) -> CGRect {
        let dotFrame = CGRect(
            x: CGFloat(index) * (pillSize.width + spacing),
            y: bounds.midY - activePillSize.height/2,
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
