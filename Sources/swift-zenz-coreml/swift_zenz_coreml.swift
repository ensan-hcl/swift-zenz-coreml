// The Swift Programming Language
// https://docs.swift.org/swift-book
import CoreML
import Foundation

func main() {
    // カスタムクラスの定義
    class ModelInput: MLFeatureProvider {
        var inputIds: MLMultiArray
        var attentionMask: MLMultiArray

        init(inputIds: MLMultiArray, attentionMask: MLMultiArray) {
            self.inputIds = inputIds
            self.attentionMask = attentionMask
        }

        var featureNames: Set<String> {
            return ["input_ids", "attention_mask"]
        }

        func featureValue(for featureName: String) -> MLFeatureValue? {
            if featureName == "input_ids" {
                return MLFeatureValue(multiArray: inputIds)
            }
            if featureName == "attention_mask" {
                return MLFeatureValue(multiArray: attentionMask)
            }
            return nil
        }
    }

    guard let modelURL = Bundle.module.url(forResource: "Resources/zenz_v1", withExtension: "mlpackage") else {
        fatalError("Model file not found")
    }

    do {
        let compiledModelURL = try MLModel.compileModel(at: modelURL)
        let model = try MLModel(contentsOf: compiledModelURL)

        // 入力データの準備
        let sequenceLength = 16 // モデルが期待するシーケンス長

        let inputIds: [NSNumber] = Array(repeating: 0, count: sequenceLength) // 例: トークナイザーでエンコードされた入力ID
        let attentionMask: [NSNumber] = Array(repeating: 1, count: sequenceLength) // 例: 対応するアテンションマスク

        let input = try MLMultiArray(shape: [1, sequenceLength as NSNumber], dataType: .int32)
        let mask = try MLMultiArray(shape: [1, sequenceLength as NSNumber], dataType: .int32)
        for (index, value) in inputIds.enumerated() {
            input[index] = value
        }

        for (index, value) in attentionMask.enumerated() {
            mask[index] = value
        }

        // カスタムクラスのインスタンス作成
        let modelInput = ModelInput(inputIds: input, attentionMask: mask)

        // モデルの予測
        let prediction = try model.prediction(from: modelInput)
        print(prediction)
        for key in prediction.featureNames {
            print(key, prediction.featureValue(for: key))
        }

    } catch {
        print("Error loading model: \(error)")
    }

}
