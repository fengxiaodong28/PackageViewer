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
        .alert("Update Result", isPresented: .constant(viewModel.updateAlert != nil), presenting: viewModel.updateAlert) { alert in
            Button("OK") {
                viewModel.updateAlert = nil
            }
        } message: { alert in
            if alert.success {
                Text("\(alert.packageName) has been updated successfully!")
                    .foregroundColor(.green)
            } else {
                Text("Failed to update \(alert.packageName): \(alert.error ?? "Unknown error")")
                    .foregroundColor(.red)
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
                ForEach(viewModel.filteredPackages) { package in
                    PackageTableRow(package: package, viewModel: viewModel)
                        .id("\(package.id)-\(package.latestVersion ?? "nil")")
                }
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

            Text("Operations")
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
                .frame(width: 210, alignment: .leading)
        }
    }
}

struct PackageTableRow: View {
    @ObservedObject var package: Package
    @ObservedObject var viewModel: PackageListViewModel

    var body: some View {
        HStack(spacing: 12) {
            Text(package.name)
                .font(.system(size: 13, design: .default))
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .help(package.name)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(displayVersion)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        await viewModel.checkLatestVersion(for: package)
                    }
                }) {
                    HStack(spacing: 4) {
                        if package.isCheckingUpdate {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 11, height: 11)
                        } else {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11))
                                .frame(width: 11, height: 11)
                        }
                        Text(package.isCheckingUpdate ? "Checking..." : (package.latestVersion != nil ? package.latestVersion! : "Check"))
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    .frame(width: 100)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(package.isCheckingUpdate)

                Button(action: {
                    Task {
                        await viewModel.updatePackage(package)
                    }
                }) {
                    HStack(spacing: 4) {
                        if package.isUpdating {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 11, height: 11)
                        } else {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 11))
                                .frame(width: 11, height: 11)
                        }
                        Text(package.isUpdating ? "Updating..." : "Update")
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    .frame(width: 90)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(package.isUpdating || package.latestVersion == nil || !package.hasUpdateAvailable)
            }
            .frame(width: 210, alignment: .leading)
        }
        .frame(minHeight: 28)
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private var displayVersion: String {
        package.version ?? "-"
    }
}
