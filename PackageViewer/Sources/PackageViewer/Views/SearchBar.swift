import SwiftUI

struct SearchBar: View {
    @ObservedObject var viewModel: PackageListViewModel
    let packageCount: Int

    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search packages...", text: $searchText)
                .textFieldStyle(.plain)
                .onChange(of: searchText) { _, newValue in
                    // Cancel previous search task and start new one
                    searchTask?.cancel()
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        if !Task.isCancelled {
                            viewModel.search(newValue)
                        }
                    }
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    searchText = ""
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Show package count
            if packageCount > 0 {
                Text("\(packageCount) packages")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.controlAccentColor).opacity(0.1))
                    .cornerRadius(4)
            }

            // Refresh button
            Button(action: {
                viewModel.refresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Refresh package list")
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            searchText = viewModel.searchQuery
        }
    }
}
