import SwiftUI

struct ContentView: View {
    @State private var videoFile: URL?
    @State private var subtitleFile: URL?
    @State private var mergeStatus: String?
    @State private var selectedLanguage: String = "fra"
    
    let subtitleLanguages = ["eng": "Anglais", "fra": "Français", "spa": "Espagnol"] // Liste des langues disponibles
    
    var body: some View {
        VStack {
            // Zone pour la vidéo
            VStack {
                Text("Déposez une vidéo ici")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .background(Color.gray.opacity(0.3))
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        return handleDrop(providers: providers, isVideo: true)
                    }
                    .padding()
                
                if let videoFile = videoFile {
                    Text("Vidéo : \(videoFile.lastPathComponent)")
                        .foregroundColor(.green)
                        .padding(.top, 5)
                } else {
                    Text("Aucune vidéo sélectionnée")
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
            }
            
            // Zone pour les sous-titres
            VStack {
                Text("Déposez un fichier de sous-titres ici")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .background(Color.gray.opacity(0.3))
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        return handleDrop(providers: providers, isVideo: false)
                    }
                    .padding()
                
                if let subtitleFile = subtitleFile {
                    Text("Sous-titre : \(subtitleFile.lastPathComponent)")
                        .foregroundColor(.green)
                        .padding(.top, 5)
                } else {
                    Text("Aucun sous-titre sélectionné")
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
            }
            
            // Sélecteur de langue
            VStack {
                Text("Choisissez la langue des sous-titres")
                    .font(.headline)
                    .padding()
                
                Picker("Langue", selection: $selectedLanguage) {
                    ForEach(subtitleLanguages.keys.sorted(), id: \.self) { code in
                        Text(subtitleLanguages[code] ?? "Inconnue").tag(code)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
            }
            
            // Bouton de fusion
            if videoFile != nil && subtitleFile != nil {
                Button("Fusionner") {
                    mergeFiles(videoFile: videoFile!, subtitleFile: subtitleFile!)
                }
                .padding()
            }
            
            // Affichage de l'état de fusion
            if let mergeStatus = mergeStatus {
                Text(mergeStatus)
                    .padding()
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private func handleDrop(providers: [NSItemProvider], isVideo: Bool) -> Bool {
        if let provider = providers.first {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                DispatchQueue.main.async {
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        if isVideo {
                            videoFile = url
                        } else {
                            subtitleFile = url
                        }
                    }
                }
            }
            return true
        }
        return false
    }
    
    private func mergeFiles(videoFile: URL, subtitleFile: URL) {
        // Préparer les chemins de fichiers pour la commande mkvmerge
        let videoFilePath = videoFile.path
        let subtitleFilePath = subtitleFile.path
        let outputFilePath = videoFile.deletingPathExtension().appendingPathExtension("merged.mkv").path
        
        // Construire la commande mkvmerge avec la langue sélectionnée
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/mkvmerge") // ou le chemin correct
        process.arguments = [
            "-o", outputFilePath,
            "--language", "0:\(selectedLanguage)", // Langue de la vidéo
            videoFilePath,
            "--language", "0:\(selectedLanguage)", // Langue des sous-titres
            subtitleFilePath
        ]
        
        // Lancer la commande
        do {
            try process.run()
            process.waitUntilExit()
            mergeStatus = "Fichier fusionné : \(outputFilePath)"
        } catch {
            mergeStatus = "Erreur lors de la fusion : \(error.localizedDescription)"
        }
        
        // Réinitialiser toutes les variables après la fusion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.videoFile = nil
            self.subtitleFile = nil
            self.mergeStatus = nil
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
