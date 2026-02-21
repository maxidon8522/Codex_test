//
//  ContentView.swift
//  FestivalCashier
//
//  Created by 村上マキシ on 2025/03/04.
//

import SwiftUI
import Firebase

struct ContentView: View {
    @State private var orderNumber = 1
    @State private var totalAmount = 0
    
    let items = [
        ("お好み焼き", 100),
        ("サーターアンダギー", 100),
        ("きゅうり", 50)
    ]
    
    @State private var cart: [(String, Int)] = []
    
    var body: some View {
        VStack {
            Text("祭りのレジ")
                .font(.largeTitle)
                .padding()
            
            List {
                ForEach(items, id: \.0) { item in
                    Button(action: {
                        cart.append(item)
                        totalAmount += item.1
                    }) {
                        HStack {
                            Text(item.0)
                            Spacer()
                            Text("\(item.1)円")
                        }
                    }
                }
            }
            .frame(height: 200)
            
            Text("合計: \(totalAmount)円")
                .font(.title)
                .padding()
            
            Button("会計する") {
                processOrder()
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Text("注文番号: \(orderNumber)")
                .font(.title)
                .padding()
        }
    }
    
    func processOrder() {
        let db = Firestore.firestore()
        let orderData: [String: Any] = [
            "orderNumber": orderNumber,
            "totalAmount": totalAmount,
            "items": cart.map { $0.0 }
        ]
        
        db.collection("orders").addDocument(data: orderData) { error in
            if let error = error {
                print("Error adding order: \(error.localizedDescription)")
            } else {
                orderNumber += 1
                totalAmount = 0
                cart.removeAll()
            }
        }
    }
}
