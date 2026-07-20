import SwiftUI
import KanjiCore

/// S08-B ヒント入力（1文字ずつ独立した入力枠）
struct HintInputView: View {
    @Environment(GameSession.self) private var session
    @State private var texts: [String] = []
    @State private var errorMessage: String?
    @FocusState private var focusedIndex: Int?

    var body: some View {
        let engine = session.engine
        let count = engine.config.charsPerPlayer
        let name = engine.currentHintGiver?.name ?? ""

        ChalkScreen(progress: session.progressLine, title: "ヒントを書く") {
            VStack(spacing: 16) {
                Text("\(name)さんの ヒントを入力（漢字\(count)文字）")
                    .font(Theme.font(17))
                    .foregroundStyle(Theme.chalk)
                // 文字数が多いときは枠を小さくして折り返す（最大5文字対応）
                let box: CGFloat = count <= 3 ? 96 : 72
                let columns = [GridItem(.adaptive(minimum: box), spacing: 12, alignment: .center)]
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<count, id: \.self) { i in
                        VStack(spacing: 6) {
                            TextField("", text: binding(for: i))
                                .font(Theme.font(box * 0.5))
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center)
                                .frame(width: box, height: box)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Theme.card)
                                        .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 3)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(focusedIndex == i ? Theme.ink.opacity(0.7) : Theme.tileBorder, lineWidth: 2)
                                )
                                .focused($focusedIndex, equals: i)
                            Text("\(i + 1)文字目")
                                .font(Theme.font(12))
                                .foregroundStyle(Theme.chalkFaded)
                        }
                    }
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkWarn)
                } else {
                    Text("ひらがな・カタカナ・英数字は使えません")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkFaded)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("ヒントのルール")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.primaryDark)
                    Text("・お題に含まれる漢字は使えません\n・\(count)文字で実在する言葉を作らないでください\n・ほかの人と被った文字は消されます")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.primaryDark)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.primaryLight))
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .frame(maxHeight: .infinity, alignment: .top)
        } actions: {
            ChalkButton(title: "決定して次の人へ渡す", enabled: texts.count == count && texts.allSatisfy { !$0.isEmpty }) {
                submit()
            }
        }
        .onAppear { reset(count: count) }
        .onChange(of: session.engine.currentHintGiver?.id) { reset(count: count) }
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { index < texts.count ? texts[index] : "" },
            set: { newValue in
                guard index < texts.count else { return }
                // IME変換中の未確定文字列を壊さないよう素通しし、確定内容は submit 時に検証する
                texts[index] = newValue
            }
        )
    }

    private func reset(count: Int) {
        texts = Array(repeating: "", count: count)
        errorMessage = nil
        focusedIndex = 0
    }

    private func submit() {
        guard texts.allSatisfy({ $0.count == 1 }) else {
            errorMessage = "1つの枠には 漢字1文字だけ入れてください"
            return
        }
        let chars = texts.compactMap(\.first)
        var error: HintValidationError?
        session.update { error = $0.submitHint(chars: chars) }
        if let error {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: HintValidationError) -> String {
        switch error {
        case .notKanji: "漢字だけが使えます"
        case .duplicateOwnChar: "同じ漢字は2回使えません"
        case .wrongLength: "\(session.engine.config.charsPerPlayer)文字入力してください"
        }
    }
}
