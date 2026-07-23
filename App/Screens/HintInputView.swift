import SwiftUI
import KanjiCore

/// S08-B ヒント入力。枠を選ぶと吹き出しの入力フィールドが出て、
/// 入力した言葉が漢字だけ1文字パネル化され、タップで選択中の枠に入る。
struct HintInputView: View {
    @Environment(GameSession.self) private var session
    @State private var texts: [String] = []
    @State private var errorMessage: String?
    @State private var selected: Int?
    @State private var wordInput = ""
    @State private var rowWidth: CGFloat = 0
    @State private var bump: Int?
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var fieldFocused: Bool

    private static let maxWord = 10
    private let boxGap: CGFloat = 10

    var body: some View {
        let engine = session.engine
        let count = engine.config.charsPerPlayer
        let name = engine.currentHintGiver?.name ?? ""

        ChalkScreen(progress: session.progressLine, title: "ヒントを書く") {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil.line").font(.system(size: 13)).foregroundStyle(Theme.chalkFaded)
                                Text(name).font(Theme.font(15)).foregroundStyle(Theme.chalk)
                            }
                            .padding(.vertical, 6).padding(.horizontal, 12)
                            .background(Capsule().strokeBorder(Theme.chalkFaded, lineWidth: 1.5))
                            Spacer()
                            if let topic = engine.topic {
                                Text(difficultyLabel(topic.difficulty))
                                    .font(Theme.font(13)).foregroundStyle(Theme.primaryDark)
                                    .padding(.vertical, 4).padding(.horizontal, 12)
                                    .background(Capsule().fill(Theme.primaryLight))
                            }
                        }
                        if let topic = engine.topic {
                            VStack(spacing: 2) {
                                Text("お題").font(Theme.font(13)).foregroundStyle(Theme.chalkFaded)
                                Text(topic.text)
                                    .font(Theme.font(40)).foregroundStyle(Theme.chalk)
                                    .lineLimit(1).minimumScaleFactor(0.5)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        // 入力枠：常に1段・文字数で自動縮小
                        let size = boxSize(count)
                        HStack(spacing: boxGap) {
                            ForEach(0..<count, id: \.self) { i in
                                boxView(i, size: size).id("box\(i)")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(GeometryReader { g in
                            Color.clear
                                .onAppear { rowWidth = g.size.width }
                                .onChange(of: g.size.width) { _, w in rowWidth = w }
                        })
                        // 吹き出しはフロー内。挟まるとルールが下へ押し出される
                        if let sel = selected {
                            inputBubble(sel: sel, count: count)
                                .transition(.scale(scale: 0.95, anchor: .top).combined(with: .opacity))
                        }
                        if let errorMessage {
                            Text(errorMessage).font(Theme.font(13)).foregroundStyle(Theme.chalkWarn)
                        }
                        rulesBox(count: count)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    // キーボードに隠れないよう下に余白（吹き出しまでスクロールできる）
                    .padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 12 : 16)
                }
                .scrollDismissesKeyboard(.never)
                .onChange(of: selected) { _, sel in
                    guard let sel else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("box\(sel)", anchor: UnitPoint(x: 0.5, y: 0.16))
                        }
                    }
                }
            }
        } actions: {
            ChalkButton(title: "決定して次の人へ渡す",
                        enabled: texts.count == count && texts.allSatisfy { $0.count == 1 }) {
                submit()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            if let f = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                keyboardHeight = f.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .onAppear { reset(count: count) }
        .onChange(of: session.engine.currentHintGiver?.id) { reset(count: count) }
    }

    // MARK: - パーツ

    private func boxView(_ i: Int, size: CGFloat) -> some View {
        let active = selected == i
        return Button {
            selectBox(i)
        } label: {
            Text(i < texts.count ? texts[i] : "")
                .font(Theme.font(size * 0.52))
                .foregroundStyle(Theme.ink)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(active ? Theme.primaryLight : Theme.card)
                        .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(active ? Theme.primary : Theme.tileBorder, lineWidth: active ? 3 : 2)
                )
        }
        .buttonStyle(.pressable)
        .scaleEffect(bump == i ? 1.15 : (active ? 1.06 : 1))
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: bump)
        .animation(.easeOut(duration: 0.1), value: active)
    }

    private func inputBubble(sel: Int, count: Int) -> some View {
        VStack(spacing: 0) {
            BubbleTail()
                .fill(Theme.card)
                .frame(width: 22, height: 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, max(0, tailX(sel, count: count) - 11))
                .animation(.easeOut(duration: 0.18), value: selected)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text("入力した文字から漢字を選択できます。")
                        .font(Theme.font(13)).foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Button { closeBubble() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22)).foregroundStyle(Theme.inkDisabled)
                    }
                }
                TextField("言葉を入力（例：満員電車）", text: $wordInput)
                    .font(Theme.font(17)).foregroundStyle(Theme.ink)
                    .focused($fieldFocused)
                    .padding(.horizontal, 12).frame(height: 46)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.tileDeletedBg))
                    .onChange(of: wordInput) { _, v in
                        if v.count > Self.maxWord { wordInput = String(v.prefix(Self.maxWord)) }
                    }
                let kanji = Array(wordInput).filter { HintRules.isKanji($0) }
                if !kanji.isEmpty {
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(Array(kanji.enumerated()), id: \.offset) { _, ch in
                            // すでに別の枠で使っている漢字は使えない（同一人物の重複禁止）
                            let used = texts.enumerated().contains { $0.offset != sel && $0.element == String(ch) }
                            Button { pick(ch, into: sel) } label: {
                                Text(String(ch))
                                    .font(Theme.font(26)).foregroundStyle(used ? Theme.inkDisabled : Theme.ink)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(used ? Theme.tileDeletedBg : Theme.card)
                                            .overlay(RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(used ? Theme.inkDisabled.opacity(0.4) : Theme.tileBorder, lineWidth: 1.5))
                                    )
                            }
                            .buttonStyle(.pressable)
                            .disabled(used)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card).shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 3))
        }
    }

    private func rulesBox(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 13)).foregroundStyle(Theme.primaryDark)
                Text("ほかの人と被った漢字は消えてしまう！")
                    .font(Theme.font(15)).foregroundStyle(Theme.primaryDark)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("ルール")
                    .font(Theme.font(12)).foregroundStyle(Theme.inkSecondary)
                Text("・お題に含まれる漢字は使わない\n・お題を和訳しただけの漢字も使わない\n・漢字を組み合わせて熟語を作らない")
                    .font(Theme.font(12)).foregroundStyle(Theme.inkSecondary).lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.primaryLight)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.primary, lineWidth: 2))
        )
    }

    // MARK: - 寸法計算

    private func boxSize(_ count: Int) -> CGFloat {
        guard rowWidth > 0 else { return 72 }
        let raw = (rowWidth - CGFloat(count - 1) * boxGap) / CGFloat(count)
        return min(88, raw)
    }

    /// 選択枠の中心x（枠列＝吹き出しの左端 からの距離）
    private func tailX(_ sel: Int, count: Int) -> CGFloat {
        let size = boxSize(count)
        let total = CGFloat(count) * size + CGFloat(count - 1) * boxGap
        let startX = max(0, (rowWidth - total) / 2)
        return startX + CGFloat(sel) * (size + boxGap) + size / 2
    }

    // MARK: - 操作

    private func selectBox(_ i: Int) {
        withAnimation(.easeOut(duration: 0.16)) { selected = i }
        fieldFocused = true
    }

    private func closeBubble() {
        fieldFocused = false
        withAnimation(.easeOut(duration: 0.16)) { selected = nil }
    }

    private func pick(_ ch: Character, into index: Int) {
        guard index < texts.count else { return }
        texts[index] = String(ch)   // 選んだ字は選択中の枠だけに入れる
        wordInput = ""              // 反映したら入力欄は空に
        bump = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if bump == index { bump = nil }
        }
        closeBubble()               // 反映したら一旦閉じる
    }

    private func reset(count: Int) {
        texts = Array(repeating: "", count: count)
        errorMessage = nil
        selected = nil
        wordInput = ""
        bump = nil
    }

    private func submit() {
        guard texts.allSatisfy({ $0.count == 1 }) else {
            errorMessage = "すべての枠に 漢字を1文字ずつ入れてください"
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

    private func difficultyLabel(_ d: Difficulty) -> String {
        switch d {
        case .easy: "やさしい"
        case .normal: "ふつう"
        case .hard: "むずかしい"
        }
    }
}

/// 吹き出しの上向きしっぽ
private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
