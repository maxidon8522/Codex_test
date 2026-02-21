
//
//  WordItem+Helper.swift
//  ToeicMaster
//
//  Created by 村上マキシ on 2025/11/29.
//
import Foundation
import CoreData

// MARK: - WordItem Extension (ロジック部分)
extension WordItem {
    
    // 忘却曲線アルゴリズム (SM-2 Modified)
    func updateProgress(isCorrect: Bool) {
        let now = Date()
        self.lastReviewDate = now
        
        if isCorrect {
            // 正解の場合
            if self.streak == 0 {
                self.interval = 1.0
            } else if self.streak == 1 {
                self.interval = 6.0
            } else {
                self.interval = self.interval * self.easeFactor
            }
            self.streak += 1
            if self.status == 0 { self.status = 1 } // 未学習 -> 学習中
            
            // 難易度係数の維持
        } else {
            // 不正解の場合
            self.streak = 0
            self.interval = 1.0 // 明日復習
            self.wrongCount += 1
            self.status = 1
            self.easeFactor = max(1.3, self.easeFactor - 0.2)
        }
        
        // 次回出題日の設定
        self.nextReviewDate = Calendar.current.date(byAdding: .day, value: Int(ceil(self.interval)), to: now)
    }
    
    // ダミー選択肢の取得
    static func fetchDummyOptions(for target: WordItem, context: NSManagedObjectContext) -> [WordItem] {
        // 文字数±30%, 単語数±1
        let charMin = Int16(Double(target.charCount) * 0.7)
        let charMax = Int16(Double(target.charCount) * 1.3)
        let wordMin = max(1, target.wordCount - 1)
        let wordMax = target.wordCount + 1
        
        let request: NSFetchRequest<WordItem> = WordItem.fetchRequest()
        request.predicate = NSPredicate(format: "id != %@ AND charCount >= %d AND charCount <= %d AND wordCount >= %d AND wordCount <= %d", target.id! as CVarArg, charMin, charMax, wordMin, wordMax)
        request.fetchLimit = 50
        
        do {
            let candidates = try context.fetch(request)
            return Array(candidates.shuffled().prefix(3))
        } catch {
            return []
        }
    }
}

// MARK: - CSV Import Logic
struct DataLoader {
    static func loadCSV(context: NSManagedObjectContext) {
        // データが既にある場合は何もしない
        let fetchRequest: NSFetchRequest<WordItem> = WordItem.fetchRequest()
        if (try? context.count(for: fetchRequest)) ?? 0 > 0 { return }
        
        // CSVファイル読み込み
        guard let path = Bundle.main.path(forResource: "toeic_word", ofType: "csv") else {
            print("csv not found")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path)
            let rows = content.components(separatedBy: "\n")
            
            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count >= 2 {
                    let newItem = WordItem(context: context)
                    newItem.id = UUID()
                    newItem.japanese = columns[0].trimmingCharacters(in: .newlines)
                    newItem.english = columns[1].trimmingCharacters(in: .newlines)
                    
                    // 文字数・単語数の計算
                    newItem.charCount = Int16(newItem.english?.count ?? 0)
                    newItem.wordCount = Int16(newItem.english?.split(separator: " ").count ?? 0)
                    
                    // 初期値設定
                    newItem.status = 0
                    newItem.easeFactor = 2.5
                    newItem.streak = 0
                    newItem.interval = 0
                    newItem.wrongCount = 0
                    newItem.nextReviewDate = Date.distantPast
                }
            }
            try context.save()
            print("CSV Import Completed!")
        } catch {
            print("CSV Error: \(error)")
        }
    }
}
