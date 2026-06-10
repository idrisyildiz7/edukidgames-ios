import Foundation

extension ServiceError {
    var messageText: String {
        switch self {
        case .customError(let message):
            return message
        case .dataProcessingError:
            return "Veri işlenirken bir hata oluştu."
        case .informationalMeta(_, let message):
            return message
        case .httpStatus(let code):
            return "İstek başarısız (HTTP \(code))"
        }
    }
}
