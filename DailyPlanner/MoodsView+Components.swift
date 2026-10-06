import SwiftUI

struct MoodRecordsCardView: View {
    let records: [MoodRecord]
    @Binding var showRecordsList: Bool
    
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let inkMuted = Color(.tertiaryLabel)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Mood Records")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer()
                Button(action: { showRecordsList = true }) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(inkSecondary)
                }
            }
            .padding(.bottom, 14)
 
            if records.isEmpty {
                Text("No mood entries logged for this period")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(inkMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                VStack(spacing: 10) {
                    ForEach(records) { record in
                        moodRecordRow(record)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.cardSurface))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
    
    private func moodRecordRow(_ record: MoodRecord) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text("\(record.day)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                Text(record.weekday)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(inkSecondary)
            }
            .frame(width: 44)
 
            HStack(spacing: 12) {
                ZStack {
                    Image(record.mood.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
 
                VStack(alignment: .center, spacing: 2) {
                    Text(record.mood.rawValue)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(record.mood.color)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.tertiarySystemFill)))
        }
    }
}
