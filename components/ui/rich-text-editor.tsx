"use client"

import React, { useMemo, useRef } from "react"
import dynamic from "next/dynamic"
import "react-quill-new/dist/quill.snow.css"

interface RichTextEditorProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  className?: string
}

const ReactQuill = dynamic(() => import("react-quill-new"), {
  ssr: false,
  loading: () => <div className="h-64 bg-gray-50 animate-pulse rounded-lg" />,
})

export function RichTextEditor({ value, onChange, placeholder, className = "" }: RichTextEditorProps) {
  const modules = useMemo(
    () => ({
      toolbar: [
        [{ header: [1, 2, 3, false] }],
        ["bold", "italic", "underline", "strike"],
        [{ color: [] }, { background: [] }],
        [{ list: "ordered" }, { list: "bullet" }],
        [{ indent: "-1" }, { indent: "+1" }],
        [{ align: [] }],
        ["blockquote", "code-block"],
        ["link", "image", "video"],
        ["clean"],
      ],
      clipboard: {
        matchVisual: false,
      },
    }),
    []
  )

  const formats = [
    "header",
    "bold",
    "italic",
    "underline",
    "strike",
    "color",
    "background",
    "list",
    "bullet",
    "indent",
    "align",
    "blockquote",
    "code-block",
    "link",
    "image",
    "video",
  ]

  return (
    <div className={`rich-text-editor-wrapper ${className}`}>
      <style jsx global>{`
        .rich-text-editor-wrapper .ql-container {
          min-height: 250px;
          font-size: 16px;
          border-bottom-left-radius: 0.75rem;
          border-bottom-right-radius: 0.75rem;
        }
        
        .rich-text-editor-wrapper .ql-toolbar {
          border-top-left-radius: 0.75rem;
          border-top-right-radius: 0.75rem;
          background: #f9fafb;
          border: 2px solid #e5e7eb;
        }
        
        .rich-text-editor-wrapper .ql-container {
          border: 2px solid #e5e7eb;
          border-top: none;
        }
        
        .rich-text-editor-wrapper .ql-editor {
          min-height: 250px;
        }
        
        .rich-text-editor-wrapper .ql-editor.ql-blank::before {
          color: #9ca3af;
          font-style: normal;
        }
        
        .rich-text-editor-wrapper:focus-within .ql-toolbar,
        .rich-text-editor-wrapper:focus-within .ql-container {
          border-color: #10b981;
        }
        
        .rich-text-editor-wrapper:focus-within {
          box-shadow: 0 0 0 4px rgba(16, 185, 129, 0.1);
          border-radius: 0.75rem;
        }
        
        .rich-text-editor-wrapper .ql-toolbar button {
          transition: all 0.2s;
        }
        
        .rich-text-editor-wrapper .ql-toolbar button:hover {
          background: #e5e7eb;
          border-radius: 0.375rem;
        }
        
        .rich-text-editor-wrapper .ql-toolbar button.ql-active {
          background: #10b981;
          color: white;
          border-radius: 0.375rem;
        }
        
        .rich-text-editor-wrapper .ql-stroke {
          stroke: #374151;
        }
        
        .rich-text-editor-wrapper .ql-fill {
          fill: #374151;
        }
        
        .rich-text-editor-wrapper .ql-toolbar button.ql-active .ql-stroke {
          stroke: white;
        }
        
        .rich-text-editor-wrapper .ql-toolbar button.ql-active .ql-fill {
          fill: white;
        }
      `}</style>
      <ReactQuill
        theme="snow"
        value={value}
        onChange={onChange}
        modules={modules}
        formats={formats}
        placeholder={placeholder}
      />
    </div>
  )
}
