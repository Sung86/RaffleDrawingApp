import UIKit

class SellRaffleTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet var nameInput: UITextField!
    @IBOutlet var mobileInput: UITextField!
    @IBOutlet var emailInput: UITextField!
    @IBOutlet var customerIdInput: UITextField!
    @IBOutlet var ticketInput: UITextField!
    @IBOutlet var totalPriceLabel: UILabel!
    @IBOutlet var ticketAvailable: UILabel!
    @IBOutlet var maximumTickets: UILabel!
    
    @IBOutlet var ticketStepper: UIStepper!
    
    var raffle : Raffle?
    var ticket : Ticket?
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "RaffleDatabase")
    var tickets = [Ticket]()
    var filteredTickets = [Ticket]()
    @IBOutlet var customerListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        customerListTableView.delegate = self
        customerListTableView.dataSource = self
        
        tickets  = database.selectAllTicketBy(groupByColumn: "Customer_Name")
        
         filteredTickets = tickets //initial filtered tickets
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        //
        let selectedRaffle : Raffle = database.selectRaffleBy(ID:(raffle?.id)!)!
        //diplay the number of ticket(s) available
        ticketAvailable.text = String(selectedRaffle.tickets - selectedRaffle.numberOfSoldTicket) + " ticket(s) available"
        //diplay the maximum ticket limit
        maximumTickets.text = "maximum " + String(selectedRaffle.limited) + " ticket(s) per customer."
        ticketInput.addTarget(self, action: #selector(SellRaffleTableViewController.textFieldDidChange(_:)),
                            for: .editingChanged)
        ticketStepper.maximumValue = 10000000000.0
        ticketInput.text = "0"
        
    }
    
    // Handling search box
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.tickets.removeAll()
        
        if searchBar.text!.isEmpty {
            self.tickets = self.filteredTickets
        }
        else {
            for ticket in self.filteredTickets {
                let searchedText = searchBar.text!.lowercased()
                let customerName = ticket.customerName.lowercased()

                if customerName.contains(searchedText) ||
                    ticket.customerPhone.contains(searchedText) || (customerName + ticket.customerPhone).contains(searchedText) ||
                        (ticket.customerPhone + customerName).contains(searchedText) {
                    self.tickets.append(ticket)
                }
            }
        }
        self.customerListTableView.reloadData()
    }
    
    //Dismiss the keyboard when finish search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //When table view cell get clicked / tapped, then fill in the text fields with selected ticket info
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectTicket = tickets[indexPath.row]
        
        nameInput.text = selectTicket.customerName
        mobileInput.text = selectTicket.customerPhone
        emailInput.text = selectTicket.customerEmail
        customerIdInput.text = selectTicket.customerIdentity
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tickets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExistingBuyerListCell", for: indexPath)
        cell.selectionStyle = .none
        // Configure the cell...
        let ticket = tickets[indexPath.row]
        if let ticketCell = cell as? ExistingBuyerTableViewCell {
            ticketCell.customerName.text = ticket.customerName
            ticketCell.customerPhone.text = ticket.customerPhone
        }
        
        return cell
    }
   
    /* Clear all of the input information in the form
     */
    @IBAction func clearFormBtnTapped(_ sender: UIButton) {
        nameInput.text = nil
        mobileInput.text = nil
        emailInput.text = nil
        customerIdInput.text = nil
        ticketInput.text = nil
    }
    /**
     *When user type on ticketInput
     */
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            
            var v1 : Double
            let v2 = Double((raffle?.price)!)
            
            if text.isEmpty {
                v1 = 0.0
                totalPriceLabel.text = String(v1 * v2)
            }else{
                if Int(text) != nil {
                    if Double(text)! > self.ticketStepper.maximumValue {
                        let alert = UIAlertController(title: "Error", message: "Too much tickets!! System can't handle!", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: { action in
                            self.ticketInput.text = String(Int(self.ticketStepper.maximumValue))
                            self.totalPriceLabel.text = String(Double(text)! * self.ticketStepper.maximumValue)
                            self.ticketStepper.value = Double(self.ticketStepper.maximumValue)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                    else{
                        v1 = Double(text)!
                        totalPriceLabel.text = String(v1 * v2)
                        ticketStepper.value = v1
                    }
                }
                else {
                    let alert = UIAlertController(title: "Error", message: "Positive Number only!", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: { action in
                        self.ticketInput.text = ""
                        self.totalPriceLabel.text = "0.0"
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
        }
    }
    @IBAction func stepperTapped(_ sender: UIStepper) {
        ticketInput.text = Int(sender.value).description
        let v1 = sender.value
        let v2 = Double((raffle?.price)!)
        totalPriceLabel.text = String(v1 * v2)
    }
    
    /* Clear all information and get back to the previous page
     */
    @IBAction func cancelBtnTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*  Validate input data
     */
    func validation() -> String {
        var result: String = "true"
        
        // Retrieve the raffle info
        let selectedRaffle : Raffle = database.selectRaffleBy(ID:(raffle?.id)!)!
        
        //number of ticket(s) available
        let numTicketsAvailable = selectedRaffle.tickets - selectedRaffle.numberOfSoldTicket
        
        /*  Check emptiness
         */
        if nameInput.text == "" {
            result = "Name cannot empty."
            return result
        }
        else if mobileInput.text == "" {
            result = "Mobile number cannot empty."
            return result
        }
        else if !isValidPhone(phone: String(mobileInput.text!)) {
            result = "Please input valid mobile number."
            return result
        }
        else if emailInput.text != "" && !isValidEmail(email: String(emailInput.text!)){
            result = "Please input valid email."
            return result
        }
        else if ticketInput.text == "" {
            result = "How many ticket do you want to sell?"
            return result
        }
        else if Int(ticketInput.text!)! == 0 {
            result = "Please input a valid ticket number."
            return result
        }
        else if Int(ticketInput.text!)! > numTicketsAvailable {
            result = "There are only " + String(numTicketsAvailable) + " ticket(s) left!"
            return result
        }
        
        /*  Check logic condition before selling ticket
         */
        if nameInput.text != nil { //this should be check with their mobile number, name can be duplicate
            let buyerTickets : [Ticket] = database.selectAllTicketByBuyerAndRaffle(Name: nameInput.text!, ID: selectedRaffle.id) ?? []
            print(buyerTickets.count)
            //check how many ticket(s) they have bought
            if (buyerTickets.count + Int(ticketInput.text!)!) > selectedRaffle.limited {
                result =
                    "You have bought " + String(buyerTickets.count) + " ticket(s). You cannot buy more than the limitation (" + String(selectedRaffle.limited) + ")."
                return result
            }
        }
        
        return result
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
    
    // Handling selling a ticket
    func sellTickets() {
        
        var selectedRaffle : Raffle = database.selectRaffleBy(ID:(raffle?.id)!)!
        
        var numberOfSoldTicket = selectedRaffle.numberOfSoldTicket
        let totalTicket = selectedRaffle.tickets
        
        if numberOfSoldTicket < totalTicket
        {
            let buyerTickets : [Ticket] = database.selectAllTicketByBuyerAndRaffle(Name: nameInput.text!, ID: selectedRaffle.id) ?? []
            
            //make sure buyer does not exceed the ticket limit per customer rule
            if buyerTickets.count < selectedRaffle.limited
            {
                var numTicketAfterPurchased = 0
                if let numTicketBuying =  Int(ticketInput.text!)
                {
                    numTicketAfterPurchased = buyerTickets.count + numTicketBuying
                }
                if numTicketAfterPurchased <= selectedRaffle.limited
                {
                    //get current date time
                    let dateObj = Date()
                    let dateFormat = DateFormatter()
                    dateFormat.dateFormat = "HH:mm dd-MM-yyyy"
                    let currentDateTime = dateFormat.string(from: dateObj)
                    
                    //inset ticket 1 by 1
                    if let numInsertion = Int32((ticketInput?.text)!)
                    {
                        for _ in 0..<numInsertion
                        {
                            //format ticket number
                            var seqNumber : Int32 = 0
                            var ticketNumber : String = ""
                            var marginValue: String = ""
                            
                            numberOfSoldTicket += 1
                            if selectedRaffle.drawType == "Random" {
                                seqNumber = numberOfSoldTicket
                                marginValue = "None"
                                
                            }else if selectedRaffle.drawType == "Margin" {
                              
                                //Format Ticket sequence
                                let allRaffleTickets : [Ticket] = database.selectAllTicketByRaffle(ID: selectedRaffle.id)!
                                var allTicketNumbers = [String]()
                                for ticket in allRaffleTickets {
                                    allTicketNumbers.append(ticket.ticketNumber.components(separatedBy: "#")[1])
                                }
                                repeat {
                                    seqNumber = Int32.random(in: 1 ... selectedRaffle.tickets)
                                    
                                }while (allTicketNumbers.contains(String(seqNumber))) //make sure ticket numbers are unique
                                
                                // Format margin value
                                var allMarginValues = [String]()
                                for ticket in allRaffleTickets {
                                    allMarginValues.append(ticket.marginValue)
                                }
                                repeat {
                                    marginValue = String(Int32.random(in: 1 ... ((raffle?.tickets)! * 3)))
                                    
                                }while (allMarginValues.contains(String(marginValue))) //only one or none winner per draw
                                
                            }
                            ticketNumber = String(describing: selectedRaffle.id) + "@" + (selectedRaffle.name) + "#" + String(seqNumber)
                            
                            database.insertTicket(ticket: Ticket(id: -1, ticketNumber: ticketNumber, price: Double(self.totalPriceLabel!.text ?? "0")!, purchasedDateTime: currentDateTime, marginValue: marginValue, raffleId: (selectedRaffle.id) ,customerIdentity: customerIdInput.text!, customerName: nameInput.text!, customerPhone: mobileInput.text!, customerEmail: emailInput.text!))
                            
                            selectedRaffle.numberOfSoldTicket += 1
                        }
                    }
                    database.updateRaffle(raffle:selectedRaffle)

                    for i in database.selectAllTicketByRaffle(ID: selectedRaffle.id)! {
                        print(i)
                    }
                }
            }
        }
        //unwind to Raffle Detail
        self.performSegue(withIdentifier: "unwindToRaffleDetail", sender: self)
    }
    
    /* Sell button tapped
     */
    @IBAction func sellBtnTapped(_ sender: UIBarButtonItem) {
        /*  Check all of the valid input
            Check all of selling condition
         */
        let validationResult: String = validation()
        
        if validationResult == "true" {
            //twoButtonAlert(on: self, with: "Selling Ticket(s)", message: "You are selling ticket(s)", handler: sellTickets())
            let alert = UIAlertController(title: "Selling Ticket(s)", message: "You are selling ticket(s)", preferredStyle: UIAlertController.Style.alert)
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default, handler: { action in
                self.sellTickets()
                //unwind to Detail Raffle
                self.performSegue(withIdentifier: "unwindToRaffleDetail", sender: self)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
        } else {
            print(validationResult)
            oneButtonAlert(on: self, with: "Input Error", message: validationResult)
        }
    }
    
    /*  1 button alert
     */
    func oneButtonAlert(on vc: UIViewController, with title: String, message: String) {
        // create the alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        // show the alert
        vc.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
}
    


/*
 References
 
 Unwind programmatically https://www.andrewcbancroft.com/2015/12/18/working-with-unwind-segues-programmatically-in-swift/
 
 Two buttons alert: https://medium.com/@suragch/making-an-alert-in-ios-ac36ed5af6d6
 
 Alert with function as a parameter https://stackoverflow.com/questions/52931887/how-to-pass-function-as-parameter-to-alert-action
 
 Mobile and Email RegEx https://manual.limesurvey.org/Using_regular_expressions#Email_validation
 
 Validation Information https://stackoverflow.com/questions/27998409/email-phone-validation-in-swift
 
 */
