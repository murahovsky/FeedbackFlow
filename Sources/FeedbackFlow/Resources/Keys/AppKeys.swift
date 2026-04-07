import Foundation

enum L10nKey {
    
    enum FeedbackDetail {
        static let description = "feedback_detail.description"
        static let comments = "feedback_detail.comments"
        static let commentsEmpty = "feedback_detail.comments.empty"
        static let addCommentPlaceholder = "feedback_detail.add_comment.placeholder"
        static let authorYou = "feedback_detail.author.you"
        static let authorUser = "feedback_detail.author.user"
        static let votesOne = "feedback_detail.votes.one"
        static let votesOther = "feedback_detail.votes.other"
    }
    
    enum FeedbackList {
        static let filterAll = "feedback_list.filter.all"
        static let emptyFiltered = "feedback_list.empty.filtered"
        static let emptyTitle = "feedback_list.empty.title"
        static let emptySubtitle = "feedback_list.empty.subtitle"

        static let statusPending = "feedback_list.status.pending"
        static let statusInReview = "feedback_list.status.in_review"
        static let statusPlanned = "feedback_list.status.planned"
        static let statusInProgress = "feedback_list.status.in_progress"
        static let statusCompleted = "feedback_list.status.completed"
        static let statusHidden = "feedback_list.status.hidden"
    }
    
    enum SubmitFeedback {
        static let submitFeedbackThankYou = "submit_feedback.thank_you"
        static let submitFeedbackSuccessMessage = "submit_feedback.success_message"
        
        static let submitFeedbackTitleLabel = "submit_feedback.field.title"
        static let submitFeedbackTitlePlaceholder = "submit_feedback.field.title.placeholder"
        
        static let submitFeedbackDescriptionLabel = "submit_feedback.field.description"
        
        static let submitFeedbackEmailLabel = "submit_feedback.field.email"
        static let submitFeedbackEmailPlaceholder = "submit_feedback.field.email.placeholder"
        static let submitFeedbackEmailHint = "submit_feedback.field.email.hint"
        
        static let submitFeedbackNavigationTitle = "submit_feedback.navigation_title"
    }

    enum Common {
        static let commonCancel = "common.cancel"
        static let commonDone = "common.done"
        static let commonSubmit = "common.submit"
    }
}

enum AppImageKey {
    enum SF {
        static let checkmarkFill = "checkmark.circle.fill"
        static let lightbulb = "lightbulb"
        static let plus = "plus"
        static let chevronUp = "chevron.up"
        static let calendar = "calendar"
        static let handThumbsup = "hand.thumbsup"
        static let arrowCircleUp = "arrow.up.circle.fill"
    }
}
