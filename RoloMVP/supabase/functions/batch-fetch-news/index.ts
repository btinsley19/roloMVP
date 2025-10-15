import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NewsAPIArticle {
  source: { name: string }
  title: string
  description: string | null
  url: string
  publishedAt: string
  content: string | null
}

interface NewsAPIResponse {
  status: string
  totalResults: number
  articles: NewsAPIArticle[]
}

interface Contact {
  id: string
  user_id: string
  full_name: string
  company_name: string | null
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create admin Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const newsApiKey = Deno.env.get('NEWS_API_KEY')
    if (!newsApiKey) {
      throw new Error('NEWS_API_KEY not configured')
    }

    console.log('Starting batch news fetch for high-priority contacts...')

    // Get high-priority contacts (7-10) that need news refresh
    const twentyFourHoursAgo = new Date()
    twentyFourHoursAgo.setHours(twentyFourHoursAgo.getHours() - 24)

    // Fetch contacts with priority >= 7 and has company name
    const { data: contacts, error: contactsError } = await supabase
      .from('contacts')
      .select('id, user_id, full_name, company_name')
      .gte('relationship_priority', 7)
      .not('company_name', 'is', null)
      .neq('company_name', '')
      .limit(30) // Process 30 contacts to stay within API limits

    if (contactsError) {
      throw new Error(`Failed to fetch contacts: ${contactsError.message}`)
    }

    if (!contacts || contacts.length === 0) {
      console.log('No high-priority contacts found')
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No contacts to process',
          processed: 0,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      )
    }

    console.log(`Found ${contacts.length} high-priority contacts to process`)

    // Filter contacts that need refresh (no news or last fetch > 24h ago)
    const contactsNeedingRefresh: Contact[] = []

    for (const contact of contacts) {
      const { data: latestNews } = await supabase
        .from('contact_news')
        .select('fetched_at')
        .eq('contact_id', contact.id)
        .order('fetched_at', { ascending: false })
        .limit(1)
        .single()

      if (!latestNews || new Date(latestNews.fetched_at) < twentyFourHoursAgo) {
        contactsNeedingRefresh.push(contact as Contact)
      }
    }

    console.log(`${contactsNeedingRefresh.length} contacts need news refresh`)

    // Fetch news for each contact
    const results = []
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    const fromDate = thirtyDaysAgo.toISOString().split('T')[0]

    for (const contact of contactsNeedingRefresh) {
      try {
        const searchQuery = contact.company_name || contact.full_name

        console.log(`Fetching news for ${contact.full_name} (${searchQuery})...`)

        // Call NewsAPI
        const newsApiUrl = `https://newsapi.org/v2/everything?` +
          `q=${encodeURIComponent(searchQuery)}` +
          `&from=${fromDate}` +
          `&sortBy=relevancy` +
          `&language=en` +
          `&pageSize=5` +
          `&apiKey=${newsApiKey}`

        const newsResponse = await fetch(newsApiUrl)

        if (!newsResponse.ok) {
          console.error(`NewsAPI error for ${contact.full_name}: ${newsResponse.status}`)
          continue
        }

        const newsData: NewsAPIResponse = await newsResponse.json()

        // Save articles
        let savedCount = 0
        for (const article of newsData.articles) {
          if (!article.title || !article.url) continue

          // Check if article already exists
          const { data: existingNews } = await supabase
            .from('contact_news')
            .select('id')
            .eq('contact_id', contact.id)
            .eq('url', article.url)
            .single()

          if (existingNews) continue

          // Insert new article
          const newsEntry = {
            contact_id: contact.id,
            source: article.source.name || 'Unknown',
            title: article.title,
            url: article.url,
            summary: article.description || article.content?.substring(0, 300) || '',
            published_at: article.publishedAt,
            fetched_at: new Date().toISOString(),
            topics: [] as string[],
          }

          const { error: insertError } = await supabase
            .from('contact_news')
            .insert(newsEntry)

          if (!insertError) {
            savedCount++
          }
        }

        results.push({
          contact_id: contact.id,
          contact_name: contact.full_name,
          articles_found: newsData.totalResults,
          articles_saved: savedCount,
        })

        console.log(`Saved ${savedCount} articles for ${contact.full_name}`)

        // Add small delay to respect API rate limits
        await new Promise(resolve => setTimeout(resolve, 1000))

      } catch (error) {
        console.error(`Error processing ${contact.full_name}:`, error)
        results.push({
          contact_id: contact.id,
          contact_name: contact.full_name,
          error: error.message,
        })
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        processed: results.length,
        results,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error in batch-fetch-news:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

