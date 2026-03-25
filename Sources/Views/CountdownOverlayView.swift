import SwiftUI

struct CountdownOverlayView: View {
    let seconds: Int
    @Binding var isPresented: Bool
    @State private var currentCount: Int

    @AppStorage("countdownSoundEnabled") private var soundEnabled = true

    init(seconds: Int = 3, isPresented: Binding<Bool>) {
        self.seconds = seconds
        self._isPresented = isPresented
        self._currentCount = State(initialValue: seconds)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("\(currentCount)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)

                Text("Recording starting...")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {
        if soundEnabled {
            NSSound.beep()
        }

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if currentCount > 1 {
                currentCount -= 1
                if soundEnabled {
                    NSSound.beep()
                }
            } else {
                timer.invalidate()
                if soundEnabled {
                    NSSound.beep()
                }
                flashAndDismiss()
            }
        }
    }

    private func flashAndDismiss() {
        // Flash effect
        withAnimation(.easeIn(duration: 0.05)) {
            // Flash white briefly
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPresented = false
        }
    }
}
