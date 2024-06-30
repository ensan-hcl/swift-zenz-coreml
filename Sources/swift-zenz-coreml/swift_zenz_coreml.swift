// The Swift Programming Language
// https://docs.swift.org/swift-book
import CoreML
import Tokenizers
import Foundation

// CoreML 모델 로드 함수
// Load the CoreML model
func loadModel() -> zenz_v1? {
    let config = MLModelConfiguration()
    return try? zenz_v1(configuration: config)
}

// Load the Tokenizer model
func loadTokenizer() async -> Tokenizer? {
    do {
        return try await AutoTokenizer.from(modelFolder: Bundle.module.resourceURL!)
    } catch {
        fatalError(error.localizedDescription)
    }
}


// 예측 수행 함수
// Perform prediction
func predict(text: String, model: zenz_v1, tokenizer: Tokenizer) -> [String] {
    // 텍스트를 토크나이저를 사용하여 인코딩
    // Encode the input text using the tokenizer
    let inputIDs = tokenizer.encode(text: text)
    print("inputIDs", text, inputIDs)

    // 입력을 위한 MLMultiArray 생성
    // Create MLMultiArray for input
    let inputArray = try? MLMultiArray(shape: [1, 16], dataType: .float32)
    for (index, token) in inputIDs.enumerated() {
        inputArray?[index] = NSNumber(value: token)
    }
    
    // Attention mask 생성
    // Create attention mask
    let attentionMask = try? MLMultiArray(shape: [1, 16], dataType: .float32)
    for i in 0..<inputIDs.count {
        attentionMask?[i] = 1
    }
    
    guard let inputArray, let attentionMask else { return [] }
    // 모델 입력 생성
    // Create model input
    let input = zenz_v1Input(input_ids: inputArray, attention_mask: attentionMask)
    
    // 예측 수행
    // Perform prediction
    let output = try! model.prediction(input: input)
    
    // 출력 logits 디코딩
    // Decode the output logits
    let logits = output.linear_0

    // logits에서 예측된 토큰 ID 추출
    // Extract predicted token IDs from logits
    var predictedTokenIDs = [[Int]]()
    for batchID in 0..<logits.shape[0].intValue {
        predictedTokenIDs.append([])
        for i in 0..<logits.shape[1].intValue {
            var logitValues = [Float]()
            // get argMax
            let maxId = (0..<6000).max {
                logits[[batchID, i, $0] as [NSNumber]].floatValue > logits[[0, i, $1] as [NSNumber]].floatValue
            } ?? 0
            predictedTokenIDs[batchID].append(maxId)
        }
    }

    // 예측된 토큰 ID를 다시 텍스트로 디코딩
    // Decode the predicted token IDs back to text
    print(predictedTokenIDs)
    let predictedTexts = predictedTokenIDs.map { tokenizer.decode(tokens: $0) }
    
    // 결과 출력
    // Print the result
    return predictedTexts
}

func main() async {

    let model = loadModel()
    guard let model else { fatalError("model not found") }
    let tokenizer = await loadTokenizer()
    guard let tokenizer else { fatalError("tokenizer not found") }
    let predictedSentence = predict(text: "\u{EE00}ニホンゴ\u{EE01}", model: model, tokenizer: tokenizer)
    print(predictedSentence)
}
