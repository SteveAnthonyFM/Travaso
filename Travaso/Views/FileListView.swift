import SwiftUI

/// The main list of files, or a drop prompt when empty.
struct FileListView: View {
    let queue: ConversionQueue
    let settings: ConversionSettings
    let isDropTargeted: Bool
    @State private var selection = Set<FileItem.ID>()

    var body: some View {
        Group {
            if queue.items.isEmpty {
                emptyState
            } else {
                List(selection: $selection) {
                    ForEach(Array(queue.items.enumerated()), id: \.element.id) { index, item in
                        FileRowView(item: item, settings: settings)
                            .listRowBackground(index.isMultiple(of: 2) ? Theme.background : Theme.rowAlternate)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onDeleteCommand { removeSelection() }
                .contextMenu(forSelectionType: FileItem.ID.self) { ids in
                    Button("Show in Finder") { queue.revealInFinder(ids) }
                        .disabled(!queue.items.contains { ids.contains($0.id) && $0.status == .done })
                    Divider()
                    Button("Remove") { queue.remove(ids) }
                    Button("Remove All") { queue.clear() }.disabled(queue.isRunning)
                } primaryAction: { ids in
                    queue.revealInFinder(ids)   // double-click a converted file
                }
            }
        }
        .background(Theme.background)
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.dropHighlight, lineWidth: 2)
                    .padding(6)
            }
        }
    }

    private var emptyState: some View {
        Button(action: queue.showOpenPanel) {
            VStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 34, weight: .light))
                Text("Drop audio files or folders here")
                    .font(Theme.titleFont)
                Text("or click to choose")
                    .font(Theme.detailFont)
            }
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.divider, style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                    .padding(16)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func removeSelection() {
        queue.remove(selection)
        selection.removeAll()
    }
}
