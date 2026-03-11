"use client"

import { useEffect, useRef } from "react"
import { Bold, Italic, List, ListOrdered, LinkIcon } from "lucide-react"

interface WysiwygEditorProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  className?: string
}

export function WysiwygEditor({ value, onChange, placeholder, className = "" }: WysiwygEditorProps) {
  const editorRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (editorRef.current && editorRef.current.innerHTML !== value) {
      editorRef.current.innerHTML = value
    }
  }, [value])

  const handleInput = () => {
    if (editorRef.current) {
      onChange(editorRef.current.innerHTML)
    }
  }

  const execCommand = (command: string, value?: string) => {
    document.execCommand(command, false, value)
    editorRef.current?.focus()
  }

  return (
    <div className={`border border-border rounded-lg overflow-hidden ${className}`}>
      <div className="flex gap-1 p-2 border-b border-border bg-muted/50">
        <button type="button" onClick={() => execCommand("bold")} className="p-2 hover:bg-muted rounded" title="Gras">
          <Bold className="h-4 w-4" />
        </button>
        <button
          type="button"
          onClick={() => execCommand("italic")}
          className="p-2 hover:bg-muted rounded"
          title="Italique"
        >
          <Italic className="h-4 w-4" />
        </button>
        <button
          type="button"
          onClick={() => execCommand("insertUnorderedList")}
          className="p-2 hover:bg-muted rounded"
          title="Liste à puces"
        >
          <List className="h-4 w-4" />
        </button>
        <button
          type="button"
          onClick={() => execCommand("insertOrderedList")}
          className="p-2 hover:bg-muted rounded"
          title="Liste numérotée"
        >
          <ListOrdered className="h-4 w-4" />
        </button>
        <button
          type="button"
          onClick={() => {
            const url = prompt("Entrez l'URL:")
            if (url) execCommand("createLink", url)
          }}
          className="p-2 hover:bg-muted rounded"
          title="Insérer un lien"
        >
          <LinkIcon className="h-4 w-4" />
        </button>
      </div>
      <div
        ref={editorRef}
        contentEditable
        onInput={handleInput}
        className="min-h-[200px] p-4 focus:outline-none prose prose-sm max-w-none"
        data-placeholder={placeholder}
        suppressContentEditableWarning
      />
    </div>
  )
}
