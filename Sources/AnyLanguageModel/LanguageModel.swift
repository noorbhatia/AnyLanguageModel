import Foundation

public protocol LanguageModel: Sendable {
    associatedtype UnavailableReason

    /// The type of custom generation options this model accepts.
    ///
    /// Models can define their own custom options types with extended properties
    /// by setting this to a custom type conforming to ``CustomGenerationOptions``.
    /// The default is `Never`, indicating no custom options are supported.
    associatedtype CustomGenerationOptions: AnyLanguageModel.CustomGenerationOptions = Never

    var availability: Availability<UnavailableReason> { get }

    func prewarm(
        for session: LanguageModelSession,
        promptPrefix: Prompt?
    )

    func respond<Content>(
        within session: LanguageModelSession,
        to prompt: Prompt,
        generating type: Content.Type,
        includeSchemaInPrompt: Bool,
        options: GenerationOptions
    ) async throws -> LanguageModelSession.Response<Content> where Content: Generable

    func streamResponse<Content>(
        within session: LanguageModelSession,
        to prompt: Prompt,
        generating type: Content.Type,
        includeSchemaInPrompt: Bool,
        options: GenerationOptions
    ) -> sending LanguageModelSession.ResponseStream<Content> where Content: Generable

    func logFeedbackAttachment(
        within session: LanguageModelSession,
        sentiment: LanguageModelFeedback.Sentiment?,
        issues: [LanguageModelFeedback.Issue],
        desiredOutput: Transcript.Entry?
    ) -> Data

    func kvCacheTokens(for session: LanguageModelSession) async -> Int?

    /// Release any model-scoped memory held by the model (weights, KV caches, GPU buffer pools)
    /// to relieve memory pressure before a memory-intensive operation such as transcript
    /// compaction. The model is expected to lazy-reload anything it needs on the next call.
    ///
    /// Backends without a resident footprint (cloud, FoundationModels) inherit the default no-op.
    /// MLX overrides this to drop weights and all per-session KV caches via `removeFromCache()`.
    func purgeForCompaction() async
}

// MARK: - Default Implementation

extension LanguageModel {
    public var isAvailable: Bool {
        if case .available = availability {
            return true
        } else {
            return false
        }
    }

    public func prewarm(
        for session: LanguageModelSession,
        promptPrefix: Prompt? = nil
    ) {
        return
    }

    public func logFeedbackAttachment(
        within session: LanguageModelSession,
        sentiment: LanguageModelFeedback.Sentiment? = nil,
        issues: [LanguageModelFeedback.Issue] = [],
        desiredOutput: Transcript.Entry? = nil
    ) -> Data {
        return Data()
    }

    public func kvCacheTokens(for session: LanguageModelSession) async -> Int? {
        nil
    }

    public func purgeForCompaction() async {
        return
    }
}

extension LanguageModel where UnavailableReason == Never {
    public var availability: Availability<UnavailableReason> {
        return .available
    }
}
