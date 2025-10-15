import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('=== fetch-contact-news started ===')
    
    // Get authorization header
    const authHeader = req.headers.get('Authorization')
    const apikeyHeader = req.headers.get('apikey')
    
    console.log('Headers:', {
      hasAuth: !!authHeader,
      hasApikey: !!apikeyHeader,
      authStart: authHeader?.substring(0, 20)
    })
    
    if (!authHeader) {
      console.error('Missing authorization header')
      throw new Error('Missing authorization header')
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const newsApiKey = Deno.env.get('NEWS_API_KEY')
    
    console.log('Environment:', {
      hasUrl: !!supabaseUrl,
      hasKey: !!supabaseKey,
      hasNewsKey: !!newsApiKey
    })
    
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    })

    // Verify user is authenticated
    console.log('Calling auth.getUser()...')
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser()
    
    if (userError) {
      console.error('Auth error:', userError)
      throw new Error(`Auth failed: ${userError.message}`)
    }
    
    if (!user) {
      console.error('No user returned')
      throw new Error('No authenticated user')
    }
    
    console.log(`✓ User authenticated: ${user.id}`)

    // Parse request body
    const { contactId } = await req.json()
    if (!contactId) {
      throw new Error('contactId is required')
    }

    console.log(`Fetching news for contact: ${contactId}`)

    // Fetch contact details
    const { data: contact, error: contactError } = await supabase
      .from('contacts')
      .select('id, full_name, company_name, user_id')
      .eq('id', contactId)
      .eq('user_id', user.id)
      .single()

    if (contactError || !contact) {
      throw new Error('Contact not found or access denied')
    }

    // Build search query - prioritize company name
    let searchQuery = ''
    if (contact.company_name && contact.company_name.trim() !== '') {
      searchQuery = contact.company_name.trim()
    } else {
      // Fallback to contact name if no company
      searchQuery = contact.full_name.trim()
    }

    console.log(`Searching news for: "${searchQuery}"`)

    // Check NewsAPI key again (should have been checked earlier)
    if (!newsApiKey) {
      throw new Error('NEWS_API_KEY not configured')
    }

    // Calculate date 30 days ago
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    const fromDate = thirtyDaysAgo.toISOString().split('T')[0]

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
      const errorText = await newsResponse.text()
      console.error('NewsAPI error:', errorText)
      throw new Error(`NewsAPI request failed: ${newsResponse.status}`)
    }

    const newsData: NewsAPIResponse = await newsResponse.json()
    
    console.log(`Found ${newsData.totalResults} articles, processing top ${newsData.articles.length}`)

    // Process and save articles
    const savedArticles = []
    
    for (const article of newsData.articles) {
      // Skip articles with missing required fields
      if (!article.title || !article.url) {
        continue
      }

      // Prepare news entry
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

      // Check if article already exists (by URL)
      const { data: existingNews } = await supabase
        .from('contact_news')
        .select('id')
        .eq('contact_id', contact.id)
        .eq('url', article.url)
        .single()

      if (existingNews) {
        console.log(`Article already exists: ${article.title}`)
        savedArticles.push(existingNews)
        continue
      }

      // Insert new article
      const { data: savedNews, error: insertError } = await supabase
        .from('contact_news')
        .insert(newsEntry)
        .select()
        .single()

      if (insertError) {
        console.error('Error saving article:', insertError)
        continue
      }

      savedArticles.push(savedNews)
      console.log(`Saved article: ${article.title}`)
    }

    console.log(`✓ Success: Saved ${savedArticles.length} articles for ${contact.full_name}`)
    
    return new Response(
      JSON.stringify({
        success: true,
        contact: {
          id: contact.id,
          name: contact.full_name,
        },
        articlesFound: newsData.totalResults,
        articlesSaved: savedArticles.length,
        articles: savedArticles,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error in fetch-contact-news:', error)
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

