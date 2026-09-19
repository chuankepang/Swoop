import Foundation

struct TranslationProvider {
    let id: String
    let title: String
    let subtitle: String
    let aliases: [String]
    let keywords: [String]
    let sourceLanguage: String
    let targetLanguage: String
    let urlTemplate: String
    let placeholder: String
    let mark: BrandMark
}

enum TranslationCatalog {
    static let all: [TranslationProvider] = [
        TranslationProvider(
            id: "zh2en",
            title: "Translate ZH → EN",
            subtitle: "Baidu Translate",
            aliases: ["zh2en", "zhen", "中英", "中译英", "翻译英文", "translate english", "fyen"],
            keywords: ["translate", "fanyi", "baidu"],
            sourceLanguage: "zh",
            targetLanguage: "en",
            urlTemplate: "https://fanyi.baidu.com/#zh/en/{key}",
            placeholder: "Translate Chinese to English...",
            mark: .baiduZhEn
        ),
        TranslationProvider(
            id: "en2zh",
            title: "Translate EN → ZH",
            subtitle: "Baidu Translate",
            aliases: ["en2zh", "enzh", "英中", "英译中", "翻译中文", "translate chinese", "fyzh"],
            keywords: ["translate", "fanyi", "baidu"],
            sourceLanguage: "en",
            targetLanguage: "zh",
            urlTemplate: "https://fanyi.baidu.com/#en/zh/{key}",
            placeholder: "Translate English to Chinese...",
            mark: .baiduEnZh
        ),
    ]
}
