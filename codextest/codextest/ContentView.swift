//
//  ContentView.swift
//  codextest
//
//  Created by 村上マキシ on 2025/09/23.
//

import SwiftUI

struct ContentView: View {
    private enum Hand: String, CaseIterable, Identifiable {
        case rock = "Rock"
        case paper = "Paper"
        case scissors = "Scissors"

        var id: String { rawValue }

        var emoji: String {
            switch self {
            case .rock:
                return "✊"
            case .paper:
                return "🖐️"
            case .scissors:
                return "✌️"
            }
        }

        func roundResult(against opponent: Hand) -> GameResult {
            if self == opponent { return .draw }

            switch (self, opponent) {
            case (.rock, .scissors), (.paper, .rock), (.scissors, .paper):
                return .win
            default:
                return .lose
            }
        }
    }

    private enum GameResult: String {
        case win = "You Win!"
        case lose = "You Lose"
        case draw = "It's a Draw"

        var color: Color {
            switch self {
            case .win:
                return .green
            case .lose:
                return .red
            case .draw:
                return .blue
            }
        }
    }

    @State private var playerHand: Hand?
    @State private var opponentHand: Hand?
    @State private var result: GameResult?
    @State private var playerScore = 0
    @State private var opponentScore = 0
    @State private var roundsPlayed = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("Rock • Paper • Scissors")
                .font(.largeTitle.weight(.bold))

            scoreBoard

            if let playerHand, let opponentHand {
                VStack(spacing: 12) {
                    Text("You chose: \(playerHand.emoji) \(playerHand.rawValue)")
                    Text("CPU chose: \(opponentHand.emoji) \(opponentHand.rawValue)")
                }
                .font(.headline)
            } else {
                Text("Choose your hand to start the game")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            if let result {
                Text(result.rawValue)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(result.color)
                    .padding(.top, 8)
            }

            Spacer(minLength: 16)

            HStack(spacing: 16) {
                ForEach(Hand.allCases) { hand in
                    Button {
                        play(hand)
                    } label: {
                        VStack(spacing: 4) {
                            Text(hand.emoji)
                                .font(.system(size: 32))
                            Text(hand.rawValue)
                        }
                        .font(.title3.weight(.medium))
                        .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            if roundsPlayed > 0 {
                Button("Reset Game", action: reset)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .animation(.default, value: result)
        .animation(.default, value: roundsPlayed)
    }

    private var scoreBoard: some View {
        HStack(spacing: 24) {
            VStack {
                Text("You")
                    .font(.headline)
                Text("\(playerScore)")
                    .font(.system(size: 42, weight: .bold))
            }

            VStack {
                Text("Rounds")
                    .font(.headline)
                Text("\(roundsPlayed)")
                    .font(.system(size: 24, weight: .medium))
            }

            VStack {
                Text("CPU")
                    .font(.headline)
                Text("\(opponentScore)")
                    .font(.system(size: 42, weight: .bold))
            }
        }
    }

    private func play(_ selection: Hand) {
        let cpu = Hand.allCases.randomElement() ?? .rock
        let newResult = selection.roundResult(against: cpu)

        playerHand = selection
        opponentHand = cpu
        result = newResult
        roundsPlayed += 1

        switch newResult {
        case .win:
            playerScore += 1
        case .lose:
            opponentScore += 1
        case .draw:
            break
        }
    }

    private func reset() {
        playerHand = nil
        opponentHand = nil
        result = nil
        playerScore = 0
        opponentScore = 0
        roundsPlayed = 0
    }
}

#Preview {
    ContentView()
}
