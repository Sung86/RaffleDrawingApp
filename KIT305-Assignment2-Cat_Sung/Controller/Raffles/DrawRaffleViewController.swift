import UIKit

class DrawRaffleViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet var image: UIImageView!
    @IBOutlet var raffleName: UILabel!

    @IBOutlet var selectPrize: UITextField!
    @IBOutlet var winnerName: UILabel!
    @IBOutlet var winnerMobile: UILabel!
    @IBOutlet var winnerEmail: UILabel!
    @IBOutlet var winnerID: UILabel!
    @IBOutlet var ticketNumber: UILabel!
    @IBOutlet var winPrizeLabel: UILabel!
    
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "RaffleDatabase")
    var raffle: Raffle?
    var tickets = [Ticket]()

    
    let prizePicker = UIPickerView()
    var prizeTitle = ["Select Prize", "1st Prize","2nd Prize","3rd Prize","4th Prize","5th Prize"]
    
    var shareString : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        prizePicker.dataSource = self
        prizePicker.delegate = self
        
        selectPrize.inputView = prizePicker
        if let displayRaffle = self.raffle {
            if !displayRaffle.image.isEmpty {
                image.image =  UIImage(data: Data.init(base64Encoded: displayRaffle.image, options: .init(rawValue: 0))!)
            }
            raffleName.text = displayRaffle.name
        
            let mainPrize = Double(displayRaffle.award)!
            let firstPrize = mainPrize
            let secondPrize = mainPrize * 0.75
            let thirdPrize =  mainPrize * 0.5
            let fourthPrize =  mainPrize * 0.25
            let fifthPrize =  mainPrize * 0.125
        
            prizeTitle[1] = "$"+String(firstPrize)
            prizeTitle[2] = "$"+String(secondPrize)
            prizeTitle[3] = "$"+String(thirdPrize)
            prizeTitle[4] = "$"+String(fourthPrize)
            prizeTitle[5] = "$"+String(fifthPrize)
            
        }
    }

    func drawWinnerByMargin(raffleTickets: [Ticket], winnerTickets: [Winner]) -> Ticket? {
        let pickedMargin  = Int32.random(in: 1 ... ((raffle?.tickets)! * 3))
        var forDrawTickets = [Ticket]()
        if winnerTickets.count > 0 {
            forDrawTickets = differenceBetween(ticket1:raffleTickets, ticket2:winnerTickets)
        }
        else{
            forDrawTickets = raffleTickets
        }
        var winnerTicket:Ticket? = nil
        for ticket in forDrawTickets {
            if(ticket.marginValue == String(pickedMargin)){
                winnerTicket = ticket
                break
            }
        }
        return winnerTicket
    }
    
    func drawWinnerAtRandom(raffleTickets: [Ticket], winnerTickets: [Winner]) -> Ticket {
    
        var forDrawTickets = [Ticket]()
        if winnerTickets.count > 0 {
            forDrawTickets = differenceBetween(ticket1:raffleTickets, ticket2:winnerTickets)
        }
        else{
            forDrawTickets = raffleTickets
        }
        let pickedIndex  = Int(arc4random() % UInt32(forDrawTickets.count))
        let winnerTicket = forDrawTickets[pickedIndex]
        return winnerTicket
       
    }
    
    /**
     * Get the non-drawn tickets
     * @param ticket1 all sold tickets of the raffle
     * @param ticket2 all drawn tickets of the raffle
     * @return the non-drawn tickets
     */
    func differenceBetween(ticket1:[Ticket], ticket2:[Winner]) -> [Ticket] {
        
        var selectedTicket = [Ticket]()
        var winnerTickets = [String]()
        
        for ticket in ticket2 {
            winnerTickets.append(ticket.ticketNumber)
        }
        
        for soldTicket in ticket1 {
            if  !winnerTickets.contains(soldTicket.ticketNumber){
                selectedTicket.append(soldTicket)
            }
        }
        
        return selectedTicket
    }
    
    func displayWinnerInfo(ticket: Ticket) {
        winnerName.text = ticket.customerName
        if ticket.customerEmail == "" {
            winnerEmail.text = "n/a"
        } else {
            winnerEmail.text = ticket.customerEmail
        }
        
        if ticket.customerIdentity == "" {
            winnerID.text = "n/a"
        } else {
            winnerID.text = ticket.customerIdentity
        }
        
        winnerMobile.text = String(ticket.customerPhone)
        ticketNumber.text = ticket.ticketNumber
        winPrizeLabel.text = selectPrize.text!
        
        shareString =   "Winner info \n" +
                        "Name: " + winnerName.text! +
                        " Email: " + winnerEmail.text! +
                        " ID: " + winnerID.text! +
                        " Mobile: " + winnerMobile.text! +
                        " Ticket No: " + ticketNumber.text! +
                        " Prize: " + winPrizeLabel.text!
    }

  
    /*
        Funcs Handle the picker view
     */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return prizeTitle.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return prizeTitle[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectPrize.text = prizeTitle[row]
        selectPrize.resignFirstResponder()
    }
    
    /*
        Handle action when Draw Winner button tapped
     */
    @IBAction func drawWinnerBtnTapped(_ sender: UIButton) {

        if var selectedPrize = selectPrize.text {
            selectedPrize = String(selectedPrize.dropFirst())
            if Double(selectedPrize) != nil {//check if a prize has been selected
                let raffleTickets = database.selectAllTicketByRaffle(ID: (raffle?.id)!)!
                let winnerTickets = database.selectAllWinnerByRaffle(ID: raffle!.id)!
                
                
                if winnerTickets.count != raffleTickets.count {
                    var winnerTicket: Ticket? = nil
                    //pick winner base on condition
                    if raffle?.drawType == "Random" {
                        winnerTicket = drawWinnerAtRandom(raffleTickets: raffleTickets, winnerTickets: winnerTickets)
                    }else if raffle?.drawType == "Margin"{
                        winnerTicket = drawWinnerByMargin(raffleTickets: raffleTickets, winnerTickets: winnerTickets)
                    }
                    
                    if winnerTicket != nil {
                        let dateFormat = DateFormatter()
                        dateFormat.dateFormat = "HH:mm dd-MM-yyyy"
                        let drawnTime = dateFormat.string(from: Date())
            
                        database.insertWinner(winner: Winner(id: -1, prize: selectedPrize, ticketNumber: (winnerTicket?.ticketNumber)!, raffleId: (winnerTicket?.raffleId)!, drawnTime: drawnTime, customerIdentity: (winnerTicket?.customerIdentity)!, customerName: (winnerTicket?.customerName)!, customerPhone: (winnerTicket?.customerPhone)!, customerEmail: (winnerTicket?.customerEmail)!))
                        
                        displayWinnerInfo(ticket: winnerTicket!)
                        let alert = UIAlertController(title: nil, message: "One winner has been selected!", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: {
                            self.selectPrize.text = "Select Prize"
                        })
                        
                    }else {
                        let alert = UIAlertController(title: nil, message: "No one has matched the margin picked! No one wins!", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }else{
                    let alert = UIAlertController(title: "Error", message: "No more tickets to draw!", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                
            }
            else {
                let alert = UIAlertController(title: "Error", message: "Please select a prize!", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    /*
        Handle action when share button tapped
     */
    @IBAction func shareBtnTapped(_ sender: UIBarButtonItem) {
        let vc = UIActivityViewController(activityItems: [shareString], applicationActivities: nil)
        self.present(vc, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
