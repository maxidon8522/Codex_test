//
//  OrderHistoryView.swift
//  FestivalCashier
//
//  Created by 村上マキシ on 2025/03/04.
//

import SwiftUI
import Firebase

struct OrderHistoryView: View {
    @State private var orders: [(Int, Int, [String])] = []
    
    var body: some View {
        List(orders, id: \.0) { order in
            VStack(alignment: .leading) {
                Text("注文番号: \(order.0)").font(.headline)
                Text("合計: \(order.1)円")
                Text("商品: \(order.2.joined(separator: ", "))")
            }
        }
        .onAppear(perform: fetchOrders)
    }
    
    func fetchOrders() {
        let db = Firestore.firestore()
        db.collection("orders").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching orders: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot {
                orders = snapshot.documents.map { doc in
                    let data = doc.data()
                    return (
                        data["orderNumber"] as? Int ?? 0,
                        data["totalAmount"] as? Int ?? 0,
                        data["items"] as? [String] ?? []
                    )
                }
            }
        }
    }
}

