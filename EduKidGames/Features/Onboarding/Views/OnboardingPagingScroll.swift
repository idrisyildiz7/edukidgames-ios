import SwiftUI
import UIKit

/// Yatay sayfalı scroll + parallax için offset sağlar (iOS 16 uyumlu).
struct OnboardingPagingScroll<Content: View>: UIViewControllerRepresentable {
    let pageCount: Int
    @Binding var currentPage: Int
    let content: (_ page: Int, _ pageOffset: CGFloat) -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> OnboardingPagingViewController<Content> {
        let controller = OnboardingPagingViewController(
            pageCount: pageCount,
            currentPage: currentPage,
            content: content
        )
        controller.onPageChanged = { page, offset in
            context.coordinator.update(page: page, offset: offset)
        }
        context.coordinator.controller = controller
        return controller
    }

    func updateUIViewController(_ controller: OnboardingPagingViewController<Content>, context: Context) {
        context.coordinator.parent = self
        if controller.currentPage != currentPage {
            controller.scrollToPage(currentPage, animated: true)
        }
    }

    final class Coordinator {
        var parent: OnboardingPagingScroll
        weak var controller: OnboardingPagingViewController<Content>?

        init(parent: OnboardingPagingScroll) {
            self.parent = parent
        }

        func update(page: Int, offset: CGFloat) {
            if parent.currentPage != page {
                parent.currentPage = page
            }
            controller?.parallaxOffset = offset
        }
    }
}

final class OnboardingPagingViewController<Content: View>: UIViewController, UIScrollViewDelegate {
    let pageCount: Int
    let contentBuilder: (_ page: Int, _ pageOffset: CGFloat) -> Content
    var onPageChanged: ((Int, CGFloat) -> Void)?
    var parallaxOffset: CGFloat = 0 {
        didSet { hostingControllers.forEach { $0.view.setNeedsLayout() } }
    }

    private let scrollView = UIScrollView()
    private var hostingControllers: [UIHostingController<Content>] = []
    private(set) var currentPage = 0

    init(pageCount: Int, currentPage: Int, content: @escaping (_ page: Int, _ pageOffset: CGFloat) -> Content) {
        self.pageCount = pageCount
        self.currentPage = currentPage
        self.contentBuilder = content
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = true
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard view.bounds.width > 0 else { return }

        let size = view.bounds.size
        scrollView.contentSize = CGSize(width: size.width * CGFloat(pageCount), height: size.height)

        if hostingControllers.count != pageCount {
            hostingControllers.forEach {
                $0.willMove(toParent: nil)
                $0.view.removeFromSuperview()
                $0.removeFromParent()
            }
            hostingControllers.removeAll()

            for index in 0..<pageCount {
                let offset = pageOffset(for: index, scrollOffset: scrollView.contentOffset.x, pageWidth: size.width)
                let host = UIHostingController(rootView: contentBuilder(index, offset))
                host.view.backgroundColor = .clear
                addChild(host)
                scrollView.addSubview(host.view)
                host.didMove(toParent: self)
                hostingControllers.append(host)
            }
        }

        for (index, host) in hostingControllers.enumerated() {
            host.view.frame = CGRect(
                x: CGFloat(index) * size.width,
                y: 0,
                width: size.width,
                height: size.height
            )
            let offset = pageOffset(for: index, scrollOffset: scrollView.contentOffset.x, pageWidth: size.width)
            host.rootView = contentBuilder(index, offset)
        }

        if scrollView.contentOffset.x != CGFloat(currentPage) * size.width {
            scrollView.contentOffset.x = CGFloat(currentPage) * size.width
        }
    }

    func scrollToPage(_ page: Int, animated: Bool) {
        guard page >= 0, page < pageCount, view.bounds.width > 0 else { return }
        currentPage = page
        scrollView.setContentOffset(CGPoint(x: CGFloat(page) * view.bounds.width, y: 0), animated: animated)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = max(scrollView.bounds.width, 1)
        let progress = scrollView.contentOffset.x / pageWidth
        let page = Int(round(progress))
        let clamped = max(0, min(pageCount - 1, page))
        currentPage = clamped
        parallaxOffset = progress
        onPageChanged?(clamped, progress)

        for (index, host) in hostingControllers.enumerated() {
            let offset = pageOffset(for: index, scrollOffset: scrollView.contentOffset.x, pageWidth: pageWidth)
            host.rootView = contentBuilder(index, offset)
        }
    }

    private func pageOffset(for index: Int, scrollOffset: CGFloat, pageWidth: CGFloat) -> CGFloat {
        CGFloat(index) - (scrollOffset / pageWidth)
    }
}
