import UIKit

class TicketDetailViewController: UIViewController {
    @IBOutlet var image: UIImageView!
    @IBOutlet var raffleName: UILabel!
    @IBOutlet var raffleEndTime: UILabel!
    @IBOutlet var customerName: UITextField!
    @IBOutlet var customerMobile: UITextField!
    @IBOutlet var customerEmail: UITextField!
    @IBOutlet var customerID: UITextField!
    @IBOutlet var ticketsBought: UITextView!
    @IBOutlet var updateTicketSwitch: UISwitch!
    
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "RaffleDatabase")
    var customerTicketNumber : [String] = []
    var ticket : Ticket?
    var isUpdateSwitchOn : Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        let raffle : Raffle = database.selectRaffleBy(ID: (ticket?.raffleId)!)!
        // Do any additional setup after loading the view.
        if let displayTicket = ticket {
            if !raffle.image.isEmpty {
                image.image =  UIImage(data: Data.init(base64Encoded: raffle.image, options: .init(rawValue: 0))!)
            }
            raffleName.text = raffle.name
            raffleEndTime.text = raffle.end
            customerName.text = displayTicket.customerName
            customerEmail.text = displayTicket.customerEmail
            customerMobile.text = String(displayTicket.customerPhone)
            customerID.text = displayTicket.customerIdentity
            ticketsBought.text = getCustomerAllTicketNumber()
        }
        
        customerTicketNumber = (ticketsBought.text?.components(separatedBy: " | "))!
    }
    
    @IBAction func updateTicketSwitch(_ sender: UISwitch) {
        
        
        if sender.isOn {
            if customerTicketNumber.count == 1 {
                let alert = UIAlertController(title: "Error!", message: "You have no other tickets to update", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                updateTicketSwitch.setOn(false, animated: true)
            } else {
                isUpdateSwitchOn = true
            }
        } else {
            isUpdateSwitchOn = false
        }
        
        
    }
    
    func updateCustomerInfoOnTicket(){
        var updatedTicket: Ticket = self.ticket!
        updatedTicket.customerName = customerName.text!
        updatedTicket.customerEmail = customerEmail.text!
        //updatedTicket.customerPhone = Int32(customerMobile!.text!)!
        updatedTicket.customerPhone = customerMobile.text!
        updatedTicket.customerIdentity = customerID.text!
        
        if isUpdateSwitchOn { //update multiple ticket
            for ticketNumber in customerTicketNumber {
            database.updateCustomerInfoBy(ticketNumber: ticketNumber, ticket: updatedTicket)
            }
        } else { // update single ticket
            database.updateCustomerInfoBy(ticketNumber: updatedTicket.ticketNumber, ticket: updatedTicket)
        }
    }
    func isCustomerInfoChanged() -> Bool {
        return Bool(
            self.ticket!.customerName != customerName.text! ||
            self.ticket!.customerEmail != customerEmail.text! ||
            //self.ticket!.customerPhone != Int32(customerMobile!.text!)! ||
            self.ticket!.customerPhone != customerMobile.text! ||
            self.ticket!.customerIdentity != customerID.text!
        )
        
        
    }
    
    func getCustomerAllTicketNumber() -> String {
        let tickets = database.selectAllTicketByBuyerAndRaffle(Name: (ticket?.customerName)!, ID: (self.ticket?.raffleId)!)
        
        var allTicketNumbers : String = ""
        
        for ticket in tickets! {
            allTicketNumbers += ticket.ticketNumber + " | "
        }
        
        return  String(allTicketNumbers.dropLast(3))
        
    }
    
    // Check if user input valid mobile number
    private func isValidPhone(phone: String) -> Bool {
        let phoneRegEx = "^04([0-9]{2})(\\s|-)*([0-9]{3})(\\s|-)*([0-9]{3})$"
        
        let result = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        return result.evaluate(with: phone)
    }
    
    // Check if user input valid email address
    private func isValidEmail(email: String) -> Bool {
        let emailRegEx = "^.+?@.+?\\..+$"
        
        let result = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return result.evaluate(with: email)
    }
    
    func validationInputs()->Bool{
        if !(customerName.text?.isEmpty)! && !(customerEmail.text?.isEmpty)! && !(customerID.text?.isEmpty)! && !(customerMobile.text?.isEmpty)! {
            
            var errorMsg:String = ""
            if isValidPhone(phone: customerMobile.text!) && isValidEmail(email:customerEmail.text!) {
            
                return true
            }else{
                if !isValidPhone(phone: customerMobile.text!) {
                    errorMsg += "Please input valid mobile number. "
                }
                if !isValidEmail(email:customerEmail.text!){
                    errorMsg += "Please input valid email."
                }
                let alert = UIAlertController(title:nil,message: errorMsg, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return false
            }

            
        }else{
            let alert = UIAlertController(title:nil,message: "Please fill in all fields!", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return false
        }
        

    
    }
    
    @IBAction func saveBtnTapped(_ sender: UIButton) {

        if self.isCustomerInfoChanged() {
            if self.validationInputs() {
                let alert = UIAlertController(title: "Updating Ticket Info", message: "You are updating customer information of ticket(s). Are you sure?", preferredStyle: UIAlertController.Style.alert)
                // add the actions (buttons)
                alert.addAction(UIAlertAction(title: "Update", style: UIAlertAction.Style.default, handler: { action in
                    
                    /*
                     Please call the function that updates ticket information function here
                     */
                    self.updateCustomerInfoOnTicket()
                    //unwind to Tickets List
                    self.performSegue(withIdentifier: "unwindToTicketsListFromSaveBtn", sender: self)
                   
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
                // show the alert
                self.present(alert, animated: true, completion: nil)
                
            }else{
                
            }
         }else{
            let alert = UIAlertController(title: "Error!", message: "Nothing changed! Nothing to update!", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func shareBtnTapped(_ sender: UIBarButtonItem) {
        
        var shareString: String = ""
        let displayedTicket = ticket
        
        shareString = "Customer: " + displayedTicket!.customerName + ", " + displayedTicket!.ticketNumber + ", " +
            displayedTicket!.purchasedDateTime + ", "
        
        let vc = UIActivityViewController(activityItems: [shareString], applicationActivities: nil)
        self.present(vc, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    

}
