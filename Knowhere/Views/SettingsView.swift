//
//  SettingsView.swift
//  Knowhere
//
//  App settings view
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var promptStore: PromptStore
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("globalHotkeyEnabled") private var globalHotkeyEnabled = true
    
    var body: some View {
        TabView {
            GeneralSettingsView(
                showInMenuBar: $showInMenuBar,
                globalHotkeyEnabled: $globalHotkeyEnabled
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            DataSettingsView()
            .tabItem {
                Label("Data", systemImage: "externaldrive")
            }
            
            AboutView()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 300)
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @Binding var showInMenuBar: Bool
    @Binding var globalHotkeyEnabled: Bool
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable global keyboard shortcut (⌥ Space)", isOn: $globalHotkeyEnabled)
                    .help("Show/hide the floating panel from anywhere")
            } header: {
                Text("Keyboard Shortcuts")
            }
            
            Section {
                Toggle("Launch at login", isOn: .constant(false))
                    .disabled(true)
                    .help("Coming soon")
            } header: {
                Text("Startup")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Data Settings
struct DataSettingsView: View {
    @EnvironmentObject var promptStore: PromptStore
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section {
                LabeledContent("Prompts") {
                    Text("\(promptStore.prompts.count)")
                }
                
                LabeledContent("Categories") {
                    Text("\(promptStore.categories.count)")
                }
            } header: {
                Text("Statistics")
            }
            
            Section {
                Button("Export Data...") {
                    exportData()
                }
                
                Button("Import Data...") {
                    importData()
                }
            } header: {
                Text("Backup")
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("Export Successful", isPresented: $showExportSuccess) {
            Button("OK") {}
        }
        .alert("Import Successful", isPresented: $showImportSuccess) {
            Button("OK") {}
        }
        .alert("Import Failed", isPresented: $showImportError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "knowhere_backup.json"
        
        if panel.runModal() == .OK, let url = panel.url {
            let data: [String: Any] = [
                "prompts": promptStore.prompts.map { prompt -> [String: Any] in
                    return [
                        "id": prompt.id.uuidString,
                        "title": prompt.title,
                        "content": prompt.content,
                        "categoryId": prompt.categoryId?.uuidString ?? "",
                        "isFavorite": prompt.isFavorite
                    ]
                },
                "categories": promptStore.categories.map { category -> [String: Any] in
                    return [
                        "id": category.id.uuidString,
                        "name": category.name,
                        "colorHex": category.colorHex,
                        "icon": category.icon
                    ]
                }
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) {
                try? jsonData.write(to: url)
                showExportSuccess = true
            }
        }
    }
    
    private func importData() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.urls.first {
            // Security: Check file size (max 10MB)
            let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = fileAttributes[.size] as? Int64, fileSize > maxFileSize {
                    errorMessage = "File too large. Maximum size is 10MB."
                    showImportError = true
                    return
                }
            } catch {
                errorMessage = "Cannot read file attributes"
                showImportError = true
                return
            }
            
            guard let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let promptsArray = json["prompts"] as? [[String: Any]],
                  let categoriesArray = json["categories"] as? [[String: Any]] else {
                errorMessage = "Invalid file format or corrupted data"
                showImportError = true
                return
            }

            // Import categories first (prompts reference them)
            var categoryMap: [String: UUID] = [:]
            for categoryDict in categoriesArray {
                // Schema validation: ensure all required fields exist and have correct types
                guard let idString = categoryDict["id"] as? String,
                      let name = categoryDict["name"] as? String,
                      let colorHex = categoryDict["colorHex"] as? String,
                      let icon = categoryDict["icon"] as? String,
                      let id = UUID(uuidString: idString) else {
                    continue
                }
                
                // Input sanitization: trim whitespace and validate lengths
                let sanitizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let sanitizedIcon = icon.trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard sanitizedName.count <= 100, sanitizedIcon.count <= 50 else {
                    continue // Skip invalid entries
                }

                let category = Category(id: id, name: sanitizedName, colorHex: colorHex, icon: sanitizedIcon)
                promptStore.addCategory(category)
                categoryMap[idString] = id
            }

            // Import prompts
            var promptCount = 0
            for promptDict in promptsArray {
                // Schema validation
                guard let idString = promptDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = promptDict["title"] as? String,
                      let content = promptDict["content"] as? String else {
                    continue
                }
                
                // Input sanitization
                let sanitizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                let sanitizedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Validate lengths (match PromptEditorView limits)
                guard sanitizedTitle.count <= 200, sanitizedContent.count <= 100_000 else {
                    continue
                }

                let categoryIdString = promptDict["categoryId"] as? String
                let categoryId = (categoryIdString?.isEmpty ?? true) ? nil : categoryMap[categoryIdString ?? ""]
                let isFavorite = promptDict["isFavorite"] as? Bool ?? false

                let prompt = Prompt(
                    id: id,
                    title: sanitizedTitle,
                    content: sanitizedContent,
                    categoryId: categoryId,
                    isFavorite: isFavorite
                )
                promptStore.addPrompt(prompt)
                promptCount += 1
            }

            if promptCount > 0 {
                showImportSuccess = true
            } else {
                errorMessage = "No valid prompts found in file"
                showImportError = true
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Knowhere")
                .font(.title)
                .fontWeight(.bold)
            
            Text("AI Prompt Manager")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            Spacer()
            
            Text("Made with ❤️ for productive AI users")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(PromptStore())
}
