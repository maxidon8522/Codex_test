//
//  ContentView.swift
//  NFCTEST
//
//  Created by 村上マキシ on 2024/05/30.
//

import SwiftUI
import CoreNFC

struct ContentView: View {
    @State private var isShowingNFCAlert = false
    @State private var detectedMessage: String = ""
    @State private var alertMessage: String = ""
    @State private var nfcSession: NFCNDEFReaderSession?

    var body: some View {
        VStack {
            Button(action: {
                startNFCSession()
            }) {
                Text("NFCタグを読み取る")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if !detectedMessage.isEmpty {
                Text("読み取ったデータ: \(detectedMessage)")
                    .padding()
            }
        }
        .alert(isPresented: $isShowingNFCAlert) {
            Alert(title: Text("NFCセッションエラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func startNFCSession() {
        guard NFCNDEFReaderSession.readingAvailable else {
            alertMessage = "このデバイスではNFCがサポートされていません。"
            isShowingNFCAlert = true
            return
        }
        
        nfcSession = NFCNDEFReaderSession(delegate: NFCSessionDelegate(detectedMessage: $detectedMessage, alertMessage: $alertMessage, isShowingNFCAlert: $isShowingNFCAlert), queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "アイテムの近くにiPhoneを持ってきてください。"
        nfcSession?.begin()
    }
}

class NFCSessionDelegate: NSObject, NFCNDEFReaderSessionDelegate {
    @Binding var detectedMessage: String
    @Binding var alertMessage: String
    @Binding var isShowingNFCAlert: Bool
    
    init(detectedMessage: Binding<String>, alertMessage: Binding<String>, isShowingNFCAlert: Binding<Bool>) {
        self._detectedMessage = detectedMessage
        self._alertMessage = alertMessage
        self._isShowingNFCAlert = isShowingNFCAlert
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.alertMessage = "NFCセッションエラー: \(error.localizedDescription)"
            self.isShowingNFCAlert = true
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                if let string = String(data: record.payload, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.detectedMessage = string
                    }
                }
            }
        }
    }
}
