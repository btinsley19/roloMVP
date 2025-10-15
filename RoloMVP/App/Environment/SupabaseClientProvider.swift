//
//  SupabaseClientProvider.swift
//  RoloMVP
//

import Foundation
import Supabase

class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }
}

