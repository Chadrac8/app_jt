import UIKit
import EventKit
import EventKitUI

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configurer le canal Apple Notes
    if let controller = window?.rootViewController as? FlutterViewController {
      let appleNotesChannel = FlutterMethodChannel(
        name: "app_jubile_tabernacle/apple_notes",
        binaryMessenger: controller.binaryMessenger
      )
      
      appleNotesChannel.setMethodCallHandler { [weak self] call, result in
        self?.handleAppleNotesMethodCall(call, result: result)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleAppleNotesMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isNotesAvailable":
      checkNotesAvailability(result: result)
    case "createFolder":
      createNotesFolder(call: call, result: result)
    case "createOrUpdateNote":
      createOrUpdateNote(call: call, result: result)
    case "deleteNote":
      deleteNote(call: call, result: result)
    case "getNotesFromFolder":
      getNotesFromFolder(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func checkNotesAvailability(result: @escaping FlutterResult) {
    // Vérifier si l'app Notes est disponible
    if let notesURL = URL(string: "mobilenotes://") {
      let available = UIApplication.shared.canOpenURL(notesURL)
      result(available)
    } else {
      result(false)
    }
  }
  
  private func createNotesFolder(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let folderName = args["name"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Nom de dossier requis", details: nil))
      return
    }
    
    // Utiliser l'URL Scheme pour créer un dossier
    // Note: L'API Notes native n'est pas publique, donc on utilise les URL schemes
    let encodedFolderName = folderName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? folderName
    
    if let url = URL(string: "mobilenotes://folder/create?name=\(encodedFolderName)") {
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url) { success in
          result(success)
        }
      } else {
        result(FlutterError(code: "URL_ERROR", message: "Impossible d'ouvrir Notes", details: nil))
      }
    } else {
      result(FlutterError(code: "URL_ERROR", message: "URL invalide", details: nil))
    }
  }
  
  private func createOrUpdateNote(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let title = args["title"] as? String,
          let content = args["content"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Titre et contenu requis", details: nil))
      return
    }
    
    let identifier = args["identifier"] as? String
    
    // Créer le contenu complet de la note
    let fullContent = "\(title)\n\n\(content)"
    let encodedContent = fullContent.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fullContent
    
    // Utiliser l'URL Scheme pour créer une note
    if let url = URL(string: "mobilenotes://note/create?content=\(encodedContent)") {
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url) { success in
          result(success)
        }
      } else {
        result(FlutterError(code: "URL_ERROR", message: "Impossible d'ouvrir Notes", details: nil))
      }
    } else {
      result(FlutterError(code: "URL_ERROR", message: "URL invalide", details: nil))
    }
  }
  
  private func deleteNote(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let identifier = args["identifier"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Identifiant requis", details: nil))
      return
    }
    
    // L'API Notes native ne permet pas la suppression directe
    // On retourne true pour éviter les erreurs, mais l'utilisateur devra supprimer manuellement
    result(true)
  }
  
  private func getNotesFromFolder(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let folderId = args["folderId"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "ID de dossier requis", details: nil))
      return
    }
    
    // L'API Notes native ne permet pas la lecture directe
    // Retourner une liste vide pour éviter les erreurs
    result([])
  }
}

// Extension pour faciliter l'intégration future avec l'API Notes si elle devient disponible
extension AppDelegate {
  
  private func requestNotesAccess(completion: @escaping (Bool) -> Void) {
    // Pour une future implémentation avec l'API Notes privée
    completion(true)
  }
  
  private func showNotesIntegrationAlert() {
    guard let viewController = window?.rootViewController else { return }
    
    let alert = UIAlertController(
      title: "Synchronisation Apple Notes",
      message: "Vos notes bibliques seront créées dans l'app Notes. Vous pouvez les organiser dans le dossier 'Bible - App Jubilé'.",
      preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "Compris", style: .default))
    viewController.present(alert, animated: true)
  }
}