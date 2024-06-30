// The Swift Programming Language
// https://docs.swift.org/swift-book
import CoreML
import Foundation

// Tokenizer 구조체 정의
// Define the Tokenizer struct
struct Tokenizer {
    let vocab: [String: Int]
    let reverseVocab: [Int: String]
    let config: [String: Any]

    // 초기화
    // Initializer
    init(vocabFile: String, configFile: String) {
        // 번들에서 파일 URL 가져오기
        // Get the file URLs from the bundle
        let vocabURL = Bundle.main.url(forResource: vocabFile, withExtension: "json")
        let configURL = Bundle.main.url(forResource: configFile, withExtension: "json")
        
        guard let vocabURL, let configURL else {
            self.vocab = [:]
            self.reverseVocab = [:]
            self.config = [:]
            return
        }
        
        // 파일 데이터를 가져오기
        // Get the file data
        let vocabData = try? Data(contentsOf: vocabURL)
        let configData = try? Data(contentsOf: configURL)
        
        guard let vocabData, let configData else {
            self.vocab = [:]
            self.reverseVocab = [:]
            self.config = [:]
            return
        }
        
        // JSON 디코딩
        // Decode the JSON
        self.vocab = (try? JSONDecoder().decode([String: Int].self, from: vocabData)) ?? [:]
        self.reverseVocab = Dictionary(uniqueKeysWithValues: vocab.map { ($1, $0) })
        self.config = (try? JSONSerialization.jsonObject(with: configData, options: [])) as? [String: Any] ?? [:]
    }
    
    // 텍스트를 토큰화
    // Encode the text
    func encode(_ text: String) -> [Int] {
        // 간단한 토크나이저 구현
        // Simple tokenizer implementation
        return text.split(separator: " ").compactMap { vocab[String($0)] }
    }
    
    // 토큰을 텍스트로 디코딩
    // Decode the tokens
    func decode(_ tokens: [Int]) -> String {
        // 역 vocab 사전 사용
        // Use the reverse vocab dictionary
        return tokens.compactMap { reverseVocab[$0] }.joined(separator: " ")
    }
}

// CoreML 모델 로드 함수
// Load the CoreML model
func loadModel() -> zenz_v1? {
    let config = MLModelConfiguration()
    return try? zenz_v1(configuration: config)
}

// 예측 수행 함수
// Perform prediction
func predict(text: String, model: zenz_v1, tokenizer: Tokenizer) -> [String] {
    // 텍스트를 토크나이저를 사용하여 인코딩
    // Encode the input text using the tokenizer
    let inputIDs = tokenizer.encode(text)
    
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
    let output = try? model.prediction(input: input)
    
    // 출력 logits 디코딩
    // Decode the output logits
    let logits = output?.linear_0
    
    guard let logits else { return [] }

    // logits에서 예측된 토큰 ID 추출
    // Extract predicted token IDs from logits
    var predictedTokenIDs = [[Int]]()
    for i in 0..<logits.shape[1].intValue {
        var logitValues = [Float]()
        for j in 0..<logits.shape[2].intValue {
            logitValues.append(logits[[0, i, j] as [NSNumber]].floatValue)
        }
        predictedTokenIDs.append(logitValues.indices.sorted(by: { logitValues[$0] > logitValues[$1] }))
    }
    
    // 예측된 토큰 ID를 다시 텍스트로 디코딩
    // Decode the predicted token IDs back to text
    let predictedTexts = predictedTokenIDs.map { tokenizer.decode(Array($0.prefix(5))) }
    
    // 결과 출력
    // Print the result
    return predictedTexts
}

func main() {
    let model = loadModel()
    
    guard let model else { fatalError("model not found") }
    let tokenizer = Tokenizer(vocabFile: "vocab", configFile: "tokenizer_config")
    let predictedSentence = predict(text: "Example sentence", model: model, tokenizer: tokenizer)
    
    print(predictedSentence)
}
