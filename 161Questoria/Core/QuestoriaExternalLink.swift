import Foundation

enum QuestoriaExternalLink {
    case privacyPolicy
    case termsOfUse

    var url: URL? {
        switch self {
        case .privacyPolicy:
            URL(string: "https://questoria161.site/privacy/156")
        case .termsOfUse:
            URL(string: "https://questoria161.site/terms/156")
        }
    }
}
