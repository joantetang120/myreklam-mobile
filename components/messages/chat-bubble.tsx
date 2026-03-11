"use client"

import type React from "react"

import Image from "next/image"
import { CheckCheck, Check } from "lucide-react"
import { config } from "@/lib/config"
import type { Attachments } from "@/lib/stores/message-store"

interface ChatBubbleProps {
  isSender: boolean
  isNotRead: boolean
  message: string
  time: string
  senderName: string
  senderImage?: string
  showState: boolean
  attachments?: Attachments[]
}

const ChatBubble: React.FC<ChatBubbleProps> = ({
  isSender,
  isNotRead,
  message,
  time,
  showState,
  senderName,
  senderImage,
  attachments,
}) => {
  const limiterTexte = (texte: string, limite = 20): string => {
    if (texte.length > limite) {
      return texte.substring(0, limite) + "..."
    }
    return texte
  }

  return (
    <div
      className={`flex ${isSender ? "justify-end" : "justify-start"} mb-4 animate-in fade-in slide-in-from-bottom duration-300`}
    >
      <div className={`flex gap-3 max-w-[70%] ${isSender ? "flex-row-reverse" : "flex-row"}`}>
        {!isSender && (
          <div className="flex-shrink-0">
            <div className="w-8 h-8 rounded-full overflow-hidden ring-2 ring-border">
              <Image
                alt={senderName}
                src={senderImage ? config.API_URL + senderImage : "/placeholder-user.jpg"}
                width={32}
                height={32}
                className="w-full h-full object-cover"
              />
            </div>
          </div>
        )}

        <div className={`flex flex-col ${isSender ? "items-end" : "items-start"}`}>
          {message && (
            <div
              className={`relative group ${
                isSender ? "bg-primary text-primary-foreground" : "bg-muted"
              } rounded-2xl px-4 py-2.5 shadow-sm hover:shadow-md transition-all duration-200`}
            >
              <p className="text-sm whitespace-pre-wrap break-words">{message}</p>
              <div
                className={`absolute ${isSender ? "-left-2" : "-right-2"} top-3 w-0 h-0 border-8 ${
                  isSender
                    ? "border-l-transparent border-r-primary border-t-transparent border-b-transparent"
                    : "border-r-transparent border-l-muted border-t-transparent border-b-transparent"
                }`}
              />
            </div>
          )}

          {attachments && attachments.length > 0 && (
            <div className={`flex flex-wrap gap-2 mt-2 ${isSender ? "justify-end" : "justify-start"}`}>
              {attachments.map((attachment, index) => (
                <a
                  key={index}
                  href={config.API_URL_SIMPLE + attachment.file_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group"
                >
                  {attachment.file_type.includes("image") ? (
                    <div className="relative overflow-hidden rounded-2xl border border-border hover:border-primary transition-colors">
                      <Image
                        src={config.API_URL_SIMPLE + attachment.file_url || "/placeholder.svg"}
                        alt="Attachment"
                        width={200}
                        height={200}
                        className="w-32 h-32 object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                    </div>
                  ) : (
                    <div className="w-32 h-32 flex flex-col items-center justify-center bg-muted rounded-2xl border border-border hover:border-primary transition-all group-hover:shadow-md">
                      <svg
                        className="w-8 h-8 text-muted-foreground mb-2"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                        />
                      </svg>
                      <p className="text-xs font-semibold uppercase text-center px-2">
                        {attachment.file_type?.split("/")[1] || "File"}
                      </p>
                      {attachment.file_name && (
                        <p className="text-xs text-muted-foreground text-center px-2 mt-1">
                          {limiterTexte(attachment.file_name, 10)}
                        </p>
                      )}
                    </div>
                  )}
                </a>
              ))}
            </div>
          )}

          <div className={`flex items-center gap-2 mt-1 ${isSender ? "flex-row-reverse" : "flex-row"}`}>
            <span className="text-xs text-muted-foreground">{time}</span>
            {showState && isSender && (
              <div className="flex items-center">
                {isNotRead ? (
                  <Check className="w-3 h-3 text-muted-foreground" />
                ) : (
                  <CheckCheck className="w-3 h-3 text-primary" />
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default ChatBubble
