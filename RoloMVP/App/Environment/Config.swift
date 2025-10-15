//
//  Config.swift
//  RoloMVP
//
//  To wire this up:
//  1. Add Config.xcconfig to your project
//  2. In Project Settings → Info → Configurations, set Config as the configuration file
//  3. In Build Settings → User-Defined, add:
//     SUPABASE_URL = $(SUPABASE_URL)
//     SUPABASE_ANON_KEY = $(SUPABASE_ANON_KEY)
//  4. Add these keys to your Info.plist

import Foundation

enum Config {
    static var supabaseURL: String {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !urlString.isEmpty else {
            return "https://your-project.supabase.co"
        }
        return urlString
    }
    
    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else {
            return "your-anon-key-here"
        }
        return key
    }
}

