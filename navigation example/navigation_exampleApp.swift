import SwiftUI

// MARK: APP
@main
struct NavigationApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: NAVIGATION
// TAB
enum Tab: Hashable {
    case main
    case second
}

// NAVIGATION TRANSITION
enum NavigationDirection {
    case leftDirection  // For "back" navigation
    case rightDirection // For "forward" navigation

    // Smooth transitions between screens
    var transition: AnyTransition {

        switch self {

        case .leftDirection:
            return .asymmetric(
                insertion: .move(edge: .leading)
                           .combined(with: .opacity),

                removal: .move(edge: .trailing)
                         .combined(with: .opacity)
            )
        case .rightDirection:
            return .asymmetric(

                insertion: .move(edge: .trailing)
                           .combined(with: .opacity),

                removal: .move(edge: .leading)
                         .combined(with: .opacity)
            )
        }
    }
} // NAVIGATION DIRECTION

// NAVIGATION ROUTER
final class NavigationRouter: ObservableObject {
    // SCREENS
    enum Screen: Equatable {
        case start
        case itemSelection
        case itemDetails(String)
        case tabView(item: String)
        case about
    }

    // MARK: ROUTER PROPERTIES
    @Published private(set) var currentScreen: Screen = .start

    @Published var selectedTab: Tab = .main

    @Published private(set) var selectedItem: String? = nil

    // Navigation stack state for each tab
    @Published var mainTabPath: [MainTabDestination] = []
    @Published var secondTabPath: [SecondTabDestination] = []

    // Current transition to be applied
    @Published private(set) var currentTransition: AnyTransition = .asymmetric(

        insertion: .move(edge: .trailing)
                   .combined(with: .opacity),

        removal: .move(edge: .leading)
                 .combined(with: .opacity)

    )

    static let shared = NavigationRouter()
    private init() {}


    // MARK: ROUTER MAIN NAVIGAION METHOD
    func navigate(to screen: Screen,
                  with direction: NavigationDirection = .rightDirection
    ) {

        DispatchQueue.main.async {

            self.currentTransition = direction.transition

            withAnimation(transitionAnimation) {

                self.currentScreen = screen

                if case .tabView(let item) = screen {
                    self.selectedItem = item
                }
            }
        }
    }
    // Helper method to clear navigation stack
    func clearMainPath() {
        mainTabPath.removeAll()
    }

} // NAVIGATIONROUTER


// MARK: APP ENTRY POINT
// ROOTVIEW
// Root view that orchestrates navigation flow in the application
struct RootView: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {

        NavigationView {

            ZStack {
                switch router.currentScreen {

                case .start:
                    StartScreen()
                        .transition(router.currentTransition)

                case .itemSelection:
                    ItemSelectionScreen()
                        .transition(router.currentTransition)

                case .itemDetails(let item):
                    DetailsScreen(item: item)
                        .transition(router.currentTransition)

                case .tabView(let item):
                    TabBarView(item: item)
                        .transition(router.currentTransition)

                case .about:
                    AboutScreen()
                        .transition(router.currentTransition)
                }
            }
            .animation(transitionAnimation,
                       value: router.currentScreen)
        }

    }
} // ROOTVIEW


// MARK: SCREENS
// START SCREEN
struct StartScreen: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {

        VStack(spacing: 20) {

            // CONTINUE
            // Continue button is shown only if some item was previously selected
            if let _ = router.selectedItem {

                Button("Continue") {

                    if let item = router.selectedItem {
                        // Router in action - navigating to tab view with selected item
                        router.navigate(to: .tabView(item: item))
                    }
                }
            }

            //some other UI components
            // NEW ITEM
            Button("New Item") {
                router.navigate(to: .itemSelection)
            }

            // ABOUT
            Button("About") {
                router.navigate(to: .about)
            }
        }
        .buttonStyle(.borderedProminent)
        .padding()
    }
} // START SCREEN

// ITEM SELECTION SCREEN
struct ItemSelectionScreen: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        VStack(spacing: 20) {

            // ONE
            Button("Item One") {
                router.navigate(to: .itemDetails("Item One"))
            }

            // ITEM TWO
            Button("Item Two") {
                router.navigate(to: .itemDetails("Item Two"))
            }
        }
        .buttonStyle(.borderedProminent)
        .navigationTitle("Select Item")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {

                Button("Back") {
                    router.navigate(to: .start,
                                    with: .leftDirection)
                }
            }
        }
    }
} // ITEM SELECTION SCREEN


// DETAIL SCREEN
struct DetailsScreen: View {
    @StateObject private var router = NavigationRouter.shared
    let item: String
    
    var body: some View {
        VStack(spacing: 20) {

            Text("Details for \(item)")
                .font(.title)
            
            Button("Continue") {
                router.navigate(to: .tabView(item: item))
            }
        }
        .buttonStyle(.borderedProminent)
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {

                Button("Back") {
                    router.navigate(to: .itemSelection,
                                    with: .leftDirection)
                }
            }
        }
    }
} // DETAIL SCREEN

// ABOUT SCREEN
struct AboutScreen: View {
    @StateObject private var router = NavigationRouter.shared

    var body: some View {
        VStack {
            Text("About Screen")
                .font(.title)
        }
        .navigationTitle("About")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {

                Button("Back") {
                    router.navigate(to: .start,
                                    with: .leftDirection)
                }
            }
        }
    }
} // ABOUT SCREEN


// MARK: TAB BAR
// MAIN TAB DESTINATION
enum MainTabDestination: Hashable {
    case detail(String)
    case settings
    case profile
}

// SECOND TAB DESTINATION
enum SecondTabDestination: Hashable {
    case detail(String)
}

// TAB BAR VIEW
struct TabBarView: View {
    @StateObject private var router = NavigationRouter.shared
    let item: String
    
    var body: some View {
        TabView(selection: $router.selectedTab) {

            // MAIN TAB
            NavigationStack {
                MainTab(item: item)
            }
            .tabItem {
                Label("Main", systemImage: "house")
            }
            .tag(Tab.main)

            // SECOND TAB
            NavigationStack {
                SecondTab()
            }
            .tabItem {
                Label("Second", systemImage: "star")
            }
            .tag(Tab.second)
        }
    }
} // TAB BAR VIEW


// MAIN TAB
struct MainTab: View {

    @StateObject private var router = NavigationRouter.shared

    let item: String
    
    var body: some View {

        // Using NavigationStack for native push/pop navigation within the tab
        NavigationStack(path: $router.mainTabPath) {

            List {

                // PROFILE
                NavigationLink(
                    "Profile",
                    value: MainTabDestination.profile
                )

                // SETTINGS
                NavigationLink(
                    "Settings",
                    value: MainTabDestination.settings
                )

                // DETAILS
                ForEach(1...3, id: \.self) { index in
                    NavigationLink(

                        "Detail \(index)",
                        value: MainTabDestination.detail("Item \(index)")
                    )
                }
            }
            .navigationTitle(item)
            // Custom back navigation to start screen
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {

                    Button("Back") {
                        router.navigate(to: .start,
                                        with: .leftDirection)
                    }
                }
            }
            .navigationDestination(for: MainTabDestination.self) { destination in
             // Type-safe destination handling

                switch destination {

                // DETAIL VIEW
                case .detail(let item):
                    Text("Detail View: \(item)")

                // SETTINGS VIEW
                case .settings:
                    Text("Settings View")

                // PROFILE VIEW
                case .profile:
                    Text("Profile View")
                }
            }
        }
    }
} // MAIN TAB


// SECOND TAB
struct SecondTab: View {
    var body: some View {
        Text("Second Tab Content")
            .navigationTitle("Second Tab")
    }
} // SECOND TAB


// ANIMATION
private var transitionAnimation: Animation {
    .easeInOut(duration: 0.3)
}

