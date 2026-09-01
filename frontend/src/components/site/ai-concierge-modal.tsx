'use client'

import React, { useState } from 'react'
import { Sparkles, X, Send, Bot, User, ChevronRight } from 'lucide-react'
import { aiApi } from '@/lib/api'

interface Message {
  sender: 'ai' | 'user'
  text: string
  suggestions?: string[]
}

export function AIConciergeModal() {
  const [isOpen, setIsOpen] = useState(false)
  const [inputMsg, setInputMsg] = useState('')
  const [loading, setLoading] = useState(false)
  const [messages, setMessages] = useState<Message[]>([
    {
      sender: 'ai',
      text: 'Merhaba! Ben Sobo AI Asistanınız. 🧘‍♀️ Sobo Society derslerimiz (Barre, Reformer, Functional), canlı program veya paketlerimiz hakkında size nasıl yardımcı olabilirim?',
      suggestions: ['Barre nedir?', 'Yarınki dersler', 'Stüdyo nerede?', 'Paket fiyatları'],
    },
  ])

  const handleSend = async (textToSend?: string) => {
    const query = (textToSend || inputMsg).trim()
    if (!query || loading) return

    const newMessages: Message[] = [...messages, { sender: 'user', text: query }]
    setMessages(newMessages)
    if (!textToSend) setInputMsg('')
    setLoading(true)

    try {
      const res = await aiApi.chat({ mesaj: query })
      setMessages([
        ...newMessages,
        {
          sender: 'ai',
          text: res.yanit,
          suggestions: res.oneri_sorular,
        },
      ])
    } catch (err) {
      setMessages([
        ...newMessages,
        {
          sender: 'ai',
          text: 'Üzgünüm, şu an bağlantıda bir aksaklık oldu. Lütfen tekrar deneyin veya WhatsApp hattımızdan bize ulaşın (+90 531 603 30 80).',
        },
      ])
    } finally {
      setLoading(false)
    }
  }

  return (
    <>
      {/* Floating Action Trigger Button */}
      <button
        onClick={() => setIsOpen(true)}
        className="fixed bottom-6 right-6 z-50 inline-flex items-center gap-2.5 bg-espresso hover:bg-espresso-dark text-white px-5 py-3.5 rounded-full shadow-sobo-lg border border-line/40 transition-all hover:scale-105 cursor-pointer"
      >
        <Sparkles className="w-4 h-4 text-sand animate-pulse" />
        <span className="font-serif text-sm tracking-wide font-medium">Sobo AI Asistan</span>
      </button>

      {/* AI Drawer Modal */}
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-end sm:justify-end p-0 sm:p-6 bg-black/40 backdrop-blur-xs">
          <div className="w-full sm:w-[420px] h-[85vh] sm:h-[600px] bg-ivory border border-line rounded-t-sheet sm:rounded-sheet shadow-sobo-lg flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-250">
            {/* Header */}
            <div className="p-4 bg-sand-light border-b border-line flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-full bg-espresso text-ivory flex items-center justify-center font-serif text-sm font-bold shadow-xs">
                  S
                </div>
                <div>
                  <h3 className="font-serif text-base font-medium text-ink">Sobo AI Asistan</h3>
                  <p className="text-[10px] text-secondary">Barre, Pilates & Stüdyo Rehberi</p>
                </div>
              </div>
              <button
                onClick={() => setIsOpen(false)}
                className="p-2 text-secondary hover:text-ink hover:bg-sand rounded-full transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Chat History */}
            <div className="flex-1 p-4 overflow-y-auto space-y-4 text-xs">
              {messages.map((m, i) => (
                <div
                  key={i}
                  className={`flex flex-col ${m.sender === 'user' ? 'items-end' : 'items-start'}`}
                >
                  <div
                    className={`max-w-[85%] p-3.5 rounded-card leading-relaxed ${
                      m.sender === 'user'
                        ? 'bg-espresso text-white rounded-br-none shadow-xs'
                        : 'bg-white border border-line text-ink rounded-bl-none shadow-xs'
                    }`}
                  >
                    <p className="whitespace-pre-line">{m.text}</p>
                  </div>

                  {/* Suggestion Chips */}
                  {m.suggestions && m.suggestions.length > 0 && (
                    <div className="flex flex-wrap gap-1.5 mt-2.5">
                      {m.suggestions.map((chip, idx) => (
                        <button
                          key={idx}
                          onClick={() => handleSend(chip)}
                          className="px-3 py-1.5 bg-sand-light hover:bg-sand text-secondary hover:text-ink border border-line rounded-full text-[11px] transition-colors flex items-center gap-1 cursor-pointer"
                        >
                          <span>{chip}</span>
                          <ChevronRight className="w-3 h-3 text-mocha" />
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              ))}
              {loading && (
                <div className="flex items-center gap-2 text-secondary text-xs p-2">
                  <Bot className="w-4 h-4 text-mocha animate-spin" />
                  <span>Sobo AI düşünüyor...</span>
                </div>
              )}
            </div>

            {/* Footer Input */}
            <div className="p-3 bg-sand-light/60 border-t border-line">
              <form
                onSubmit={(e) => {
                  e.preventDefault()
                  handleSend()
                }}
                className="flex items-center gap-2"
              >
                <input
                  type="text"
                  placeholder="Bir soru sorun (örn: Barre nedir?)..."
                  value={inputMsg}
                  onChange={(e) => setInputMsg(e.target.value)}
                  className="flex-1 px-4 py-2.5 bg-ivory border border-line rounded-input text-xs text-ink focus:outline-none focus:border-espresso"
                />
                <button
                  type="submit"
                  disabled={loading || !inputMsg.trim()}
                  className="p-2.5 bg-espresso text-white rounded-input hover:bg-espresso-dark disabled:opacity-50 transition-colors cursor-pointer"
                >
                  <Send className="w-4 h-4" />
                </button>
              </form>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
