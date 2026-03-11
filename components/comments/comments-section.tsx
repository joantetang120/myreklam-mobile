"use client"

import { useState, useEffect, useCallback, useRef } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { MessageCircle, Send } from "lucide-react"
import { CommentItem } from "./comment-item"
import { fetchCommentsByAnnouncementId, addReplyToComment, toggleLikeComment, fetchUserInfo } from "@/lib/api"
import axios from "axios"
import { config } from "@/lib/config"
import { toastSuccess, toastError } from "@/lib/utils/toast"
import { EmojiPicker } from "./emoji-picker"
import FeatureGuard from "@/components/subscription/feature-guard"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"

interface CommentsSectionProps {
  announcementId: string
}

export function CommentsSection({ announcementId }: CommentsSectionProps) {
  const [comments, setComments] = useState<any[]>([])
  const [newComment, setNewComment] = useState("")
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [currentUserInfo, setCurrentUserInfo] = useState<any>(null)
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") || "" : ""

  // Organize comments into tree structure
  const organizeComments = (commentsList: any[]) => {
    const commentMap = new Map()
    const rootComments: any[] = []

    // First pass: create map of all comments
    commentsList.forEach((comment) => {
      commentMap.set(comment.id, { ...comment, replies: [] })
    })

    // Second pass: organize into tree
    commentsList.forEach((comment) => {
      if (comment.parentid && commentMap.has(comment.parentid)) {
        commentMap.get(comment.parentid).replies.push(commentMap.get(comment.id))
      } else {
        rootComments.push(commentMap.get(comment.id))
      }
    })

    return rootComments
  }

  const fetchComments = useCallback(async () => {
    setIsLoading(true)
    try {
      const result = await fetchCommentsByAnnouncementId(announcementId)
      if (result.success) {
        const organizedComments = organizeComments(result.comments)
        setComments(organizedComments)
      }
    } catch (error) {
      console.error("Error fetching comments:", error)
    } finally {
      setIsLoading(false)
    }
  }, [announcementId])

  useEffect(() => {
    fetchComments()
  }, [fetchComments])

  useEffect(() => {
    if (userId) {
      const loadUserInfo = async () => {
        const result = await fetchUserInfo(userId)
        if (result.success) {
          setCurrentUserInfo(result.userInfo)
        }
      }
      loadUserInfo()
    }
  }, [userId])

  const handleSubmitComment = async () => {
    if (!newComment.trim()) return
    if (!userId) {
      toastError("Vous devez être connecté pour commenter")
      return
    }

    setIsSubmitting(true)
    try {
      const response = await axios.post(
        `${config.API_URL}/Commentaires.php`,
        {
          Method: "create",
          annonceid: announcementId,
          userid: userId,
          commentaire: newComment,
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )

      if (response.data.status === "success") {
        setNewComment("")
        await fetchComments()
        toastSuccess("Commentaire publié avec succès")
      } else {
        toastError("Erreur lors de la publication du commentaire")
      }
    } catch (error) {
      console.error("Error submitting comment:", error)
      toastError("Une erreur est survenue")
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleLikeComment = async (commentId: string, isLiked: boolean) => {
    if (!userId) {
      toastError("Vous devez être connecté pour aimer un commentaire")
      return
    }

    try {
      await toggleLikeComment(commentId, userId, isLiked)
      await fetchComments()
    } catch (error) {
      console.error("Error liking comment:", error)
      throw error
    }
  }

  const handleReplyToComment = async (commentId: string, replyText: string) => {
    if (!userId) {
      toastError("Vous devez être connecté pour répondre")
      return
    }

    try {
      const result = await addReplyToComment(commentId, userId, replyText, announcementId)
      if (result.success) {
        await fetchComments()
        toastSuccess("Réponse publiée avec succès")
      } else {
        toastError("Erreur lors de la publication de la réponse")
      }
    } catch (error) {
      console.error("Error replying to comment:", error)
      throw error
    }
  }

  const getCurrentUserInitials = () => {
    if (!currentUserInfo) return "?"
    const name =
      currentUserInfo.profiletype === "professionnel"
        ? currentUserInfo.nomsociete || "Pro"
        : currentUserInfo.pseudo || "User"
    return name
      .split(" ")
      .map((n: string) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2)
  }

  const totalComments = comments.reduce((count, comment) => {
    const countReplies = (c: any): number => {
      return 1 + (c.replies?.reduce((sum: number, reply: any) => sum + countReplies(reply), 0) || 0)
    }
    return count + countReplies(comment)
  }, 0)

  const handleEmojiSelect = (emoji: string) => {
    const textarea = textareaRef.current
    if (!textarea) return

    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const text = newComment
    const before = text.substring(0, start)
    const after = text.substring(end)

    setNewComment(before + emoji + after)

    // Set cursor position after emoji
    setTimeout(() => {
      textarea.focus()
      textarea.setSelectionRange(start + emoji.length, start + emoji.length)
    }, 0)
  }

  return (
    <Card className="p-6 border-0 shadow-lg">
      <h2 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
        <MessageCircle className="w-6 h-6 text-green-600" />
        Commentaires {totalComments > 0 && `(${totalComments})`}
      </h2>

      {/* New Comment Form */}
      {userId ? (
        <div className="mb-8">
          <div className="flex gap-3">
            <Avatar className="w-10 h-10 flex-shrink-0">
              {currentUserInfo?.photoprofilurl ? (
                <AvatarImage src={`${config.API_URL}${currentUserInfo.photoprofilurl}`} alt="Your avatar" />
              ) : null}
              <AvatarFallback className="bg-gradient-to-br from-green-400 to-emerald-600 text-white text-sm font-semibold">
                {getCurrentUserInitials()}
              </AvatarFallback>
            </Avatar>
            <div className="flex-1">
              <Textarea
                ref={textareaRef}
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
                placeholder="Partagez votre avis sur ce bon plan..."
                className="min-h-[100px] resize-none mb-3"
              />
              <div className="flex justify-between items-center">
                <EmojiPicker onEmojiSelect={handleEmojiSelect} />
                <FeatureGuard feature="comments">
                  <Button
                    onClick={handleSubmitComment}
                    disabled={!newComment.trim() || isSubmitting}
                    className="bg-green-600 hover:bg-green-700"
                  >
                    <Send className="w-4 h-4 mr-2" />
                    {isSubmitting ? "Publication..." : "Publier"}
                  </Button>
                </FeatureGuard>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="mb-8 p-4 bg-gray-50 rounded-lg text-center">
          <p className="text-gray-600">Vous devez être connecté pour laisser un commentaire</p>
        </div>
      )}

      {/* Comments List */}
      {isLoading ? (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="flex gap-3 animate-pulse">
              <div className="w-10 h-10 bg-gray-200 rounded-full flex-shrink-0" />
              <div className="flex-1 space-y-2">
                <div className="h-4 bg-gray-200 rounded w-1/4" />
                <div className="h-16 bg-gray-200 rounded" />
              </div>
            </div>
          ))}
        </div>
      ) : comments.length > 0 ? (
        <div className="space-y-6">
          {comments.map((comment) => (
            <CommentItem
              key={comment.id}
              comment={comment}
              onLike={handleLikeComment}
              onReply={handleReplyToComment}
              currentUserId={userId}
            />
          ))}
        </div>
      ) : (
        <div className="text-center py-12">
          <MessageCircle className="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500 font-medium">Aucun commentaire pour le moment</p>
          <p className="text-gray-400 text-sm mt-1">Soyez le premier à partager votre avis !</p>
        </div>
      )}
    </Card>
  )
}
