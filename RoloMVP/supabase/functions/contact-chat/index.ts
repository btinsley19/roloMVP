// Supabase Edge Function: contact-chat
// Handles AI chat for a specific contact

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ContactContext {
  contact: {
    name: string
    position: string | null
    company_name: string | null
    linkedin_url: string | null
    relationship_summary: string | null
    relationship_priority: number
    last_interaction_at: string | null
  }
  tags: Array<{ name: string; priority: number }>
  notes_recent: Array<{ id: string; date: string; is_meeting: boolean; text: string }>
  reminders: Array<{ id: string; due_at: string | null; text: string }>
  news_recent: Array<{ id: string; date: string; title: string; url: string }>
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get auth token
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Get user
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    // Parse request body
    const { contact_id, message } = await req.json()
    if (!contact_id || !message) {
      throw new Error('Missing contact_id or message')
    }

    // Verify user owns this contact
    const { data: contact, error: contactError } = await supabaseClient
      .from('contacts')
      .select('id, full_name, position, company_name, linkedin_url, relationship_summary, relationship_priority, last_interaction_at')
      .eq('id', contact_id)
      .eq('user_id', user.id)
      .single()

    if (contactError || !contact) {
      throw new Error('Contact not found or unauthorized')
    }

    // Fetch context: tags
    const { data: tags } = await supabaseClient
      .from('contact_tags')
      .select('tag_id, priority, tags(name)')
      .eq('contact_id', contact_id)
      .order('priority', { ascending: false })
      .limit(5)

    // Fetch context: recent notes
    const { data: notes } = await supabaseClient
      .from('contact_notes')
      .select('id, content, is_meeting, occurred_at, created_at')
      .eq('contact_id', contact_id)
      .order('occurred_at', { ascending: false, nullsFirst: false })
      .limit(5)

    // Fetch context: upcoming reminders
    const { data: reminders } = await supabaseClient
      .from('contact_reminders')
      .select('id, body, due_at')
      .eq('contact_id', contact_id)
      .order('due_at', { ascending: true, nullsFirst: false })
      .limit(3)

    // Fetch context: recent news
    const { data: news } = await supabaseClient
      .from('contact_news')
      .select('id, title, url, published_at')
      .eq('contact_id', contact_id)
      .order('published_at', { ascending: false })
      .limit(3)

    // Build compact context
    const context: ContactContext = {
      contact: {
        name: contact.full_name,
        position: contact.position,
        company_name: contact.company_name,
        linkedin_url: contact.linkedin_url,
        relationship_summary: contact.relationship_summary,
        relationship_priority: contact.relationship_priority,
        last_interaction_at: contact.last_interaction_at,
      },
      tags: (tags || []).map((ct: any) => ({
        name: ct.tags?.name || '',
        priority: ct.priority,
      })),
      notes_recent: (notes || []).map((n: any) => ({
        id: n.id,
        date: n.occurred_at || n.created_at,
        is_meeting: n.is_meeting,
        text: truncateText(n.content, 200),
      })),
      reminders: (reminders || []).map((r: any) => ({
        id: r.id,
        due_at: r.due_at,
        text: truncateText(r.body, 150),
      })),
      news_recent: (news || []).map((n: any) => ({
        id: n.id,
        date: n.published_at,
        title: n.title,
        url: n.url,
      })),
    }

    // Save user message to DB
    await supabaseClient
      .from('contact_chat_messages')
      .insert({
        contact_id,
        user_id: user.id,
        role: 'user',
        content: message,
      })

    // Call OpenAI
    const systemPrompt = `You are an AI copilot inside a CRM contact page.
Only discuss THIS contact. Be concise, specific, and action-oriented.
Use ONLY the provided context; do not invent facts.
If information is missing, say so and propose a concrete next step (e.g., add a note, set a reminder).
Prefer short drafts, bullet points, and suggested follow-ups over long narratives.`

    const openAIResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        temperature: 0.3,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'assistant', content: `Context for ${contact.full_name}:\n${JSON.stringify(context, null, 2)}` },
          { role: 'user', content: message },
        ],
      }),
    })

    if (!openAIResponse.ok) {
      const errorText = await openAIResponse.text()
      throw new Error(`OpenAI API error: ${errorText}`)
    }

    const openAIData = await openAIResponse.json()
    const assistantReply = openAIData.choices[0]?.message?.content || 'Sorry, I could not generate a response.'

    // Save assistant message to DB
    await supabaseClient
      .from('contact_chat_messages')
      .insert({
        contact_id,
        user_id: user.id,
        role: 'assistant',
        content: assistantReply,
        context_snapshot: context,
      })

    return new Response(
      JSON.stringify({ assistant_message: assistantReply }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

function truncateText(text: string, maxLength: number): string {
  if (!text || text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}

