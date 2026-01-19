import SwiftUI

struct ContentView: View {
    @StateObject private var npmViewModel = PackageListViewModel(manager: .npm)
    @StateObject private var homebrewViewModel = PackageListViewModel(manager: .homebrew)
    @StateObject private var pipViewModel = PackageListViewModel(manager: .pip)

    var body: some View {
        TabView {
            PackageListView(viewModel: npmViewModel)
                .tabItem {
                    Label("npm", systemImage: PackageManager.npm.iconName)
                }
                .id(PackageManager.npm)

            PackageListView(viewModel: homebrewViewModel)
                .tabItem {
                    Label("Homebrew", systemImage: PackageManager.homebrew.iconName)
                }
                .id(PackageManager.homebrew)

            PackageListView(viewModel: pipViewModel)
                .tabItem {
                    Label("pip", systemImage: PackageManager.pip.iconName)
                }
                .id(PackageManager.pip)
        }
        .frame(minWidth: 700, idealWidth: 1000, minHeight: 500, idealHeight: 700)
    }
}
