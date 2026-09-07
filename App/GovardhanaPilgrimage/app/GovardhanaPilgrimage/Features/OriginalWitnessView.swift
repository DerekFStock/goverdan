import PDFKit
import SwiftUI

struct OriginalWitnessView: View {
    let mapping: OriginalWitnessMapping
    let fileURL: URL?

    var body: some View {
        Group {
            if let fileURL {
                VStack(spacing: 0) {
                    HStack {
                        if let label = mapping.printedPageLabel {
                            Text("Printed page \(label)")
                        }
                        Spacer()
                        Text("PDF page index \(mapping.pdfPageIndex)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.bar)
                    PDFWitnessView(fileURL: fileURL, pageIndex: mapping.pdfPageIndex)
                }
            } else {
                ContentUnavailableView("Witness unavailable", systemImage: "doc.badge.exclamationmark")
            }
        }
        .navigationTitle(mapping.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("witness.reader")
    }
}

private struct PDFWitnessView: UIViewRepresentable {
    let fileURL: URL
    let pageIndex: Int

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.accessibilityIdentifier = "witness.pdf-view"
        configure(view)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        configure(view)
    }

    private func configure(_ view: PDFView) {
        guard view.document == nil,
              let document = PDFDocument(url: fileURL),
              let page = document.page(at: pageIndex) else { return }
        view.document = document
        view.go(to: page)
        view.accessibilityValue = String(pageIndex)
    }
}
