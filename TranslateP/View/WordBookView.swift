//
//  WordBookView.swift
//  TranslateP
//
//  Created by TranslateP on 2024/11/04.
//

import SwiftUI
import AppKit

struct WordGroup: Identifiable {
    let id: String
    let date: String
    let entries: [WordEntry]
}

struct WordBookView: View {
    @StateObject private var viewModel = WordBookViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack {
                List(viewModel.languages, id: \.self, selection: $viewModel.selectedLanguage) { language in
                    Text(language)
                }
                
                // 底部路径显示和设置
                HStack {
                    Text(viewModel.currentPathDisplay)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(viewModel.folderURL.path)
                    
                    Spacer()
                    
                    Button(action: {
                        NSWorkspace.shared.open(viewModel.folderURL)
                    }) {
                        Image(systemName: "folder")
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .help("在 Finder 中打开")
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 200)
            .navigationTitle("语言")
        } detail: {
            if let _ = viewModel.selectedLanguage {
                WordListView(viewModel: viewModel)
            } else {
                Text("请选择一种语言")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            viewModel.loadLanguages()
        }
        .onDisappear {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
    }
}

struct WordListView: View {
    @ObservedObject var viewModel: WordBookViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.groupedEntries) { group in
                Section(header: Text(group.date)) {
                    ForEach(group.entries) { entry in
                        WordRowView(entry: entry, viewModel: viewModel)
                    }
                }
            }
        }
        .listStyle(.inset)
    }
}

struct WordRowView: View {
    let entry: WordEntry
    @ObservedObject var viewModel: WordBookViewModel
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.source)
                        .font(.headline)
                    
                    if let phonetic = entry.phonetic, !phonetic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(phonetic)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        viewModel.speak(entry.source)
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("朗读原文")
                }
                
                Text(entry.target)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: {
                viewModel.delete(entry)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("删除")
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

class WordBookViewModel: ObservableObject {
    @Published var languages: [String] = []
    @Published var selectedLanguage: String? {
        didSet {
            if let language = selectedLanguage {
                loadEntries(for: language)
            }
        }
    }
    @Published var groupedEntries: [WordGroup] = []
    
    var folderURL: URL {
        Translate.wordBookFolderURL()
    }
    
    var currentPathDisplay: String {
        folderURL.path
    }
    
    private let speechManager = SpeechManager()
    
    init() {
        NotificationCenter.default.addObserver(forName: Translate.wordBookDidUpdate, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.loadLanguages()
        }
    }
    
    func loadLanguages() {
        var newLanguages = WordBookManager.shared.getAvailableLanguages(from: folderURL)
        let preferredOrder = ["English", "中文"]
        newLanguages.sort { a, b in
            let ia = preferredOrder.firstIndex(of: a) ?? preferredOrder.count
            let ib = preferredOrder.firstIndex(of: b) ?? preferredOrder.count
            if ia != ib { return ia < ib }
            return a.localizedStandardCompare(b) == .orderedAscending
        }
        
        // 只有当语言列表发生变化时才更新，避免不必要的刷新
        if newLanguages != languages {
            languages = newLanguages
        }
        
        if selectedLanguage == nil {
            selectedLanguage = languages.first
        } else if let selected = selectedLanguage {
            // Reload entries if already selected
            loadEntries(for: selected)
        }
    }
    
    func loadEntries(for language: String) {
        let entries = WordBookManager.shared.load(from: folderURL, targetLanguage: language)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let grouped = Dictionary(grouping: entries, by: { dateFormatter.string(from: $0.date) })
        // Sort dates descending (newest first)
        let sortedDates = grouped.keys.sorted().reversed()
        
        groupedEntries = sortedDates.map { date in
            WordGroup(id: date, date: date, entries: grouped[date] ?? [])
        }
    }
    
    func delete(_ entry: WordEntry) {
        guard let language = selectedLanguage else { return }
        
        WordBookManager.shared.delete(entry: entry, from: folderURL, targetLanguage: language)
        loadEntries(for: language)
    }
    
    func speak(_ text: String) {
        // If target is English, source was Chinese (zh-CN)
        // If target is Chinese ("中文"), source was English (en-US)
        let languageCode = (selectedLanguage == "English") ? "zh-CN" : "en-US"
        speechManager.speakText(text, language: languageCode)
    }
}
