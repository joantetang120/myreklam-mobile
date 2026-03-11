"use client"

import { useState, useRef } from "react"
import { Button } from "@/components/ui/button"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Textarea } from "@/components/ui/textarea"
import { Heart, MessageCircle, MoreVertical, User, Briefcase } from "lucide-react"
import { formatDateRelative } from "@/lib/utils"
import { config } from "@/lib/config"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { EmojiPicker } from "./emoji-picker"

interface CommentItemProps {
  comment: any
  onLike: (commentId: string, isLiked: boolean) => Promise<void>
  onReply: (commentId: string, replyText: string) => Promise<void>
  currentUserId: string
  depth?: number
}

export function CommentItem({ comment, onLike, onReply, currentUserId, depth = 0 }: CommentItemProps) {
  const [showReplyForm, setShowReplyForm] = useState(false)
  const [replyText, setReplyText] = useState("")
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [localLikesCount, setLocalLikesCount] = useState(comment.likesCount || 0)
  const [localIsLiked, setLocalIsLiked] = useState(comment.isLiked || false)
  const replyTextareaRef = useRef<HTMLTextAreaElement>(null)

  const getUserDisplayName = () => {
    if (comment.profiletype === "professionnel") {
      return comment.nomsociete || "Professionnel"
    }
    return comment.pseudo || "Utilisateur"
  }

  const getUserInitials = () => {
    const name = getUserDisplayName()
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2)
  }

  const handleLike = async () => {
    const newIsLiked = !localIsLiked
    const newCount = newIsLiked ? localLikesCount + 1 : Math.max(0, localLikesCount - 1)

    // Optimistic update
    setLocalIsLiked(newIsLiked)
    setLocalLikesCount(newCount)

    try {
      await onLike(comment.id, localIsLiked)
    } catch (error) {
      // Revert on error
      setLocalIsLiked(!newIsLiked)
      setLocalLikesCount(localLikesCount)
    }
  }

  const handleReplySubmit = async () => {
    if (!replyText.trim()) return

    setIsSubmitting(true)
    try {
      await onReply(comment.id, replyText)
      setReplyText("")
      setShowReplyForm(false)
    } catch (error) {
      console.error("Error submitting reply:", error)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleEmojiSelect = (emoji: string) => {
    const textarea = replyTextareaRef.current
    if (!textarea) return

    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const text = replyText
    const before = text.substring(0, start)
    const after = text.substring(end)

    setReplyText(before + emoji + after)

    // Set cursor position after emoji
    setTimeout(() => {
      textarea.focus()
      textarea.setSelectionRange(start + emoji.length, start + emoji.length)
    }, 0)
  }

  const isReply = depth > 0
  const maxDepth = 3

  return (
    <div className={`flex gap-3 ${isReply ? "ml-12" : ""}`}>
      {/* Avatar */}
      <Avatar className="w-10 h-10 flex-shrink-0">
        {comment.photoprofilurl ? (
          <AvatarImage src={`${config.API_URL}${comment.photoprofilurl}`} alt={getUserDisplayName()} />
        ) : null}
        <AvatarFallback className="bg-gradient-to-br from-green-400 to-emerald-600 text-white text-sm font-semibold">
          {getUserInitials()}
        </AvatarFallback>
      </Avatar>

      {/* Comment Content */}
      <div className="flex-1 min-w-0">
        <div className="bg-gray-50 rounded-2xl px-4 py-3">
          {/* User Info */}
          <div className="flex items-center gap-2 mb-2">
            <span className="font-semibold text-gray-900 text-sm">{getUserDisplayName()}</span>
            <Badge variant={comment.profiletype === "professionnel" ? "default" : "secondary"} className="text-xs h-5">
              {comment.profiletype === "professionnel" ? (
                <>
                  <Briefcase className="w-3 h-3 mr-1" />
                  Pro
                </>
              ) : (
                <>
                  <User className="w-3 h-3 mr-1" />
                  Particulier
                </>
              )}
            </Badge>
            <span className="text-xs text-gray-500">{formatDateRelative(comment.createdat)}</span>
          </div>

          {/* Comment Text */}
          <p className="text-gray-800 text-sm leading-relaxed whitespace-pre-wrap break-words">{comment.commentaire}</p>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-4 mt-2 px-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={handleLike}
            className={`h-8 px-3 text-xs font-medium ${
              localIsLiked
                ? "text-red-600 hover:text-red-700 hover:bg-red-50"
                : "text-gray-600 hover:text-gray-900 hover:bg-gray-100"
            }`}
          >
            <Heart className={`w-4 h-4 mr-1.5 ${localIsLiked ? "fill-red-600" : ""}`} />
            {localLikesCount > 0 ? (
              <span className={localIsLiked ? "text-red-600" : "text-gray-900"}>{localLikesCount}</span>
            ) : (
              "J'aime"
            )}
          </Button>

          {depth < maxDepth && (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setShowReplyForm(!showReplyForm)}
              className="h-8 px-3 text-xs font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-100"
            >
              <MessageCircle className="w-4 h-4 mr-1.5" />
              Répondre
            </Button>
          )}

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button
                variant="ghost"
                size="sm"
                className="h-8 w-8 p-0 text-gray-400 hover:text-gray-600 hover:bg-gray-100 ml-auto"
              >
                <MoreVertical className="w-4 h-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem className="text-sm">Signaler</DropdownMenuItem>
              {comment.userid === currentUserId && (
                <>
                  <DropdownMenuItem className="text-sm">Modifier</DropdownMenuItem>
                  <DropdownMenuItem className="text-sm text-red-600">Supprimer</DropdownMenuItem>
                </>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>

        {/* Reply Form */}
        {showReplyForm && (
          <div className="mt-3 flex gap-2">
            <Avatar className="w-8 h-8 flex-shrink-0">
              <AvatarFallback className="bg-gradient-to-br from-green-400 to-emerald-600 text-white text-xs">
                {currentUserId ? "ME" : "?"}
              </AvatarFallback>
            </Avatar>
            <div className="flex-1">
              <Textarea
                ref={replyTextareaRef}
                value={replyText}
                onChange={(e) => setReplyText(e.target.value)}
                placeholder="Écrivez votre réponse..."
                className="min-h-[80px] resize-none text-sm"
              />
              <div className="flex justify-between items-center mt-2">
                <EmojiPicker onEmojiSelect={handleEmojiSelect} />
                <div className="flex gap-2">
                  <Button
                    size="sm"
                    onClick={handleReplySubmit}
                    disabled={!replyText.trim() || isSubmitting}
                    className="bg-green-600 hover:bg-green-700"
                  >
                    {isSubmitting ? "Envoi..." : "Répondre"}
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => {
                      setShowReplyForm(false)
                      setReplyText("")
                    }}
                  >
                    Annuler
                  </Button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Nested Replies */}
        {comment.replies && comment.replies.length > 0 && (
          <div className="mt-4 space-y-4">
            {comment.replies.map((reply: any) => (
              <CommentItem
                key={reply.id}
                comment={reply}
                onLike={onLike}
                onReply={onReply}
                currentUserId={currentUserId}
                depth={depth + 1}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
