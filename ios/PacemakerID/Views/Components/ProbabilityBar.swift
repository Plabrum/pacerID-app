import SwiftUI

/// Visual bar chart showing classification confidence
struct ProbabilityBar: View {
    let classification: Classification
    let isTopResult: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(classification.label)
                    .font(isTopResult ? .headline : .subheadline)
                    .fontWeight(isTopResult ? .semibold : .regular)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Spacer()

                Text(classification.confidencePercentage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isTopResult ? .primary : .secondary)
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(
                            width: geometry.size.width * classification.confidence,
                            height: 8
                        )
                        .animation(.easeOut(duration: 0.5), value: classification.confidence)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(classification.label), \(classification.confidencePercentage) confidence")
    }

    private var barColor: Color {
        switch classification.confidence {
        case 0.7...:
            isTopResult ? .green : .blue
        case 0.5 ..< 0.7:
            .orange
        default:
            .gray
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ProbabilityBar(
            classification: Classification(label: "Medtronic Azure XT DR", confidence: 0.87),
            isTopResult: true
        )

        ProbabilityBar(
            classification: Classification(label: "Boston Scientific Accolade MRI", confidence: 0.08),
            isTopResult: false
        )

        ProbabilityBar(
            classification: Classification(label: "Abbott Ellipse VR", confidence: 0.03),
            isTopResult: false
        )
    }
    .padding()
}
