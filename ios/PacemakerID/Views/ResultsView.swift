import SwiftUI

struct ResultsView: View {
    @StateObject var viewModel: ResultsViewModel
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                // Top result highlight
                if let topResult = viewModel.topResult {
                    topResultCard(topResult)
                }

                // All results
                allResultsSection
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    onDismiss()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Device Identification")
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                Image(systemName: confidenceIcon)
                    .foregroundColor(confidenceColor)

                Text("Confidence: \(viewModel.confidenceLevel)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Top Result Card

    private func topResultCard(_ result: Classification) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Likely Match")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Text(result.label)
                .font(.title3)
                .fontWeight(.semibold)

            HStack {
                Text(result.confidencePercentage)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(confidenceColor)

                Text("confidence")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Most likely match: \(result.label) with \(result.confidencePercentage) confidence")
    }

    // MARK: - All Results Section

    private var allResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Results")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(Array(viewModel.classifications.enumerated()), id: \.element.id) { index, classification in
                    ProbabilityBar(
                        classification: classification,
                        isTopResult: index == 0
                    )

                    if index < viewModel.classifications.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var confidenceIcon: String {
        switch viewModel.confidenceLevel {
        case "Very High":
            "checkmark.circle.fill"
        case "High":
            "checkmark.circle"
        case "Moderate":
            "exclamationmark.circle"
        default:
            "questionmark.circle"
        }
    }

    private var confidenceColor: Color {
        switch viewModel.confidenceLevel {
        case "Very High", "High":
            .green
        case "Moderate":
            .orange
        default:
            .red
        }
    }
}

#Preview {
    NavigationStack {
        ResultsView(
            viewModel: ResultsViewModel(classifications: Classification.exampleResults),
            onDismiss: {}
        )
    }
}
