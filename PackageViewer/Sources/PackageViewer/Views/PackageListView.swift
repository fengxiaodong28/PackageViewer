import SwiftUI

struct PackageListView: View {
    @ObservedObject var viewModel: PackageListViewModel

    init(viewModel: PackageListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Always show search bar
            SearchBar(viewModel: viewModel, packageCount: viewModel.packageCount)
                .padding()

            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else if viewModel.filteredPackages.isEmpty {
                    if viewModel.searchQuery.isEmpty {
                        emptyPackagesView
                    } else {
                        noResultsView
                    }
                } else {
                    packagesTable
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadPackages()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading packages...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: PackageError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            if error.isRetryable {
                Button("Retry") {
                    viewModel.retry()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyPackagesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No packages found")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        EmptyStateView(
            message: "No packages match \"\(viewModel.searchQuery)\"",
            icon: "magnifyingglass"
        )
    }

    private var packagesTable: some View {
        VStack(spacing: 0) {
            tableHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor))

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredPackages) { package in
                        PackageTableRow(package: package)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var tableHeader: some View {
        HStack(spacing: 12) {
            Text("Package")
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Version")
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
        }
    }
}

struct PackageTableRow: View {
    let package: Package

    var body: some View {
        HStack(spacing: 12) {
            Text(package.name)
                .font(.system(size: 13, design: .default))
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(displayVersion)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private var displayVersion: String {
        package.version ?? "-"
    }
}
