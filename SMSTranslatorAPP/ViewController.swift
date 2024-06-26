import UIKit
import Alamofire

class ViewController: UIViewController {

    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!

    // Your Twilio credentials
    let accountSID = "AC4abc64a715c56268b38e475b4ec92f35"
    let authToken = "50d53ca989d04add20c4c2417e01c2b1"
    let twilioPhoneNumber = "+17178648051"

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func sendSMS(_ sender: UIButton) {
        guard var phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty else {
            print("No phone number entered")
            return
        }
        phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        phoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        // Ensure the phone number starts with "+90"
        if !phoneNumber.hasPrefix("+90") {
            phoneNumber = "+90" + phoneNumber
        }

        guard let message = messageTextField.text, !message.isEmpty else {
            print("No message entered")
            return
        }

        translateMessage(message) { translatedMessage in
            self.sendSMSTwilio(message: translatedMessage, to: phoneNumber)
        }
    }

    func translateMessage(_ message: String, completion: @escaping (String) -> Void) {
        let apiKey = "AIzaSyDets_Xo7aKTl8QTk8xKLuketLTdfZjMVY"
        let url = "https://translation.googleapis.com/language/translate/v2"
        let parameters: Parameters = [
            "q": message,
            "source": "tr", // Assuming the input message is in Turkish (tr)
            "target": "en", // Translate to English
            "key": apiKey
        ]

        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any],
                   let data = json["data"] as? [String: Any],
                   let translations = data["translations"] as? [[String: Any]],
                   let translatedText = translations.first?["translatedText"] as? String {
                    completion(translatedText)
                }
            case .failure(let error):
                print("Error in translation: \(error)")
                completion(message) // Fallback to original message in case of failure
            }
        }
    }

    func sendSMSTwilio(message: String, to phoneNumber: String) {
        let parameters: [String: Any] = [
            "From": twilioPhoneNumber,
            "To": phoneNumber,
            "Body": message
        ]

        let url = "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Messages.json"

        AF.request(url, method: .post, parameters: parameters)
            .authenticate(username: accountSID, password: authToken)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Message sent successfully: \(value)")
                case .failure(let error):
                    print("Error sending message: \(error)")
                }
            }
    }
}
