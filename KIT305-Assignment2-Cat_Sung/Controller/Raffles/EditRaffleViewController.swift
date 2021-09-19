import UIKit

class EditRaffleViewController: UIViewController, UIImagePickerControllerDelegate,  UINavigationControllerDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var uploadImageBtn: UIButton!
    @IBOutlet var nameInput: UITextField!
    @IBOutlet var awardInput: UITextField!
    @IBOutlet var ticketsInput: UITextField!
    @IBOutlet var startInput: UITextField!
    @IBOutlet var endInput: UITextField!
    @IBOutlet var priceInput: UITextField!
    @IBOutlet var limitInput: UITextField!
    @IBOutlet var drawTypeSelection: UISegmentedControl!
    @IBOutlet var descriptionInput: UITextView!
    
    var imagePicker = UIImagePickerController()
    var raffle : Raffle?
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "RaffleDatabase")
    
    private var startDateTimePicker = UIDatePicker()
    private var endDateTimePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        assignRaffleDetail()
 
        startInput.inputView = startDateTimePicker
        endInput.inputView = endDateTimePicker
        
        startDateTimePicker.addTarget(self , action: #selector(EditRaffleViewController.startDateTimeChanged(dateTimePicker:)), for: .valueChanged)
        
        endDateTimePicker.addTarget(self , action: #selector(EditRaffleViewController.endDateTimeChanged(dateTimePicker:)), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(EditRaffleViewController.viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    func assignRaffleDetail() {
       if raffle != nil
       {
            imageView.image = UIImage(data: Data.init(base64Encoded: (raffle?.image)!, options: .init(rawValue: 0))!)
            nameInput.text = raffle!.name
            awardInput.text = raffle!.award
        print(raffle!.tickets)
            ticketsInput.text = String(raffle!.tickets)
            startInput.text = raffle!.start
            endInput.text = raffle!.end
            priceInput.text = String(raffle!.price)
            limitInput.text = String(raffle!.limited)
        
            if drawTypeSelection.titleForSegment(at: 0)! == raffle?.drawType
            {
                drawTypeSelection.selectedSegmentIndex = 0
            }
            else
            {
                drawTypeSelection.selectedSegmentIndex = 1
            }
            descriptionInput.text = raffle?.description
        }
    }
    
    @IBAction func uploadImageBtnClicked(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
    
    /*  Check if user tapped on the view area
     */
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    /*  Get date and time data from the picker
     and display in the startInput text view
     */
    @objc func startDateTimeChanged(dateTimePicker: UIDatePicker) {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "HH:mm dd-MM-yyyy"
        
        let startDateTime =  dateFormat.string(from: dateTimePicker.date)
        
        if !(endInput.text?.isEmpty)! {
            
            if  let start = dateFormat.date(from: startDateTime), let endDateTime = dateFormat.date(from: endInput.text!),
                start < endDateTime {
                
                startInput.text = startDateTime
            }else{
                let alert = UIAlertController(title: "Error!", message: "Start time should before End time", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            }
        }else{
            startInput.text = startDateTime
        }
    }
    /*  Get date and time data from the picker
     and display in the endInput text view
     */
    @objc func endDateTimeChanged(dateTimePicker: UIDatePicker) {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "HH:mm dd-MM-yyyy"
        
        let endDateTime =  dateFormat.string(from: dateTimePicker.date)
        
        if !(startInput.text?.isEmpty)! {
            
            if  let end = dateFormat.date(from: endDateTime), let startDateTime = dateFormat.date(from: startInput.text!),
                end > startDateTime {
                
                endInput.text = endDateTime
            }else{
                let alert = UIAlertController(title: "Error!", message: "End time should after Start time", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }else{
            endInput.text = endDateTime
        }
    }
    
    @IBAction func deleteRaffleBtnTapped(_ sender: UIButton) {
        /*  Check the condition before delete a raffle
            The startDate of the raffle must > the current date
         */
        //get current date time
        let currentDate = Date()

        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "HH:mm dd-MM-yyyy "
        
        /*conver endDate to Date()
         */
        let raffleStartDateString = (raffle?.start)!
        let raffleStartDate = dateFormat.date(from: raffleStartDateString)!
        let raffleEndDateString  = (raffle?.end)!
        let raffleEndDate = dateFormat.date(from: raffleEndDateString)!
        
        
        if currentDate < raffleStartDate || currentDate > raffleEndDate {
            //Delete the raffle
            let alert = UIAlertController(title: "Deleting Raffle", message: "You are deleting a raffle. Are you sure?", preferredStyle: UIAlertController.Style.alert)
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "Delete", style: UIAlertAction.Style.default, handler: { action in
                self.deleteRaffle()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
        } else {
            //prompt the alert that user can not delete
            oneButtonAlert(on: self, with: "Delete Error", message: "You cannot delete an ongoing raffle")
        }
    }
    
    @IBAction func backBtnClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveBtnTapped(_ sender: UIBarButtonItem) {

        let validationResult: String = validation()
        
        if validationResult == "true" {
            //twoButtonAlert(on: self, with: "Selling Ticket(s)", message: "You are selling ticket(s)", handler: sellTickets())
            let alert = UIAlertController(title: "Edit Raffle Info", message: "You are editing a raffle.", preferredStyle: UIAlertController.Style.alert)
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default, handler: { action in
                self.self.editRaffle()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
        } else {
            oneButtonAlert(on: self, with: "Input Error", message: validationResult)
        }
    }
    
    func editRaffle(){
        let encodedImage = imageView.image?.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
        database.updateRaffle(raffle:Raffle(id: (self.raffle?.id)!, image: encodedImage, name: nameInput.text!, award: awardInput.text!, numberOfSoldTicket: (raffle?.numberOfSoldTicket)!,tickets:Int32(ticketsInput.text!)!, start: startInput.text!, end:endInput.text!,price:Int32(priceInput.text!)!, limited: Int32(limitInput.text!)!, drawType: drawTypeSelection.titleForSegment(at: drawTypeSelection.selectedSegmentIndex)!, description:descriptionInput.text))
        
        updateTicketNumber()
        
        //unwind to Detail Raffle
        self.performSegue(withIdentifier: "unwindToRaffleDetail", sender: self)
    }
    
    func deleteRaffle() {
        database.deleteRaffleBy(ID: (self.raffle?.id)!)
        //unwind to Detail Raffle
        self.performSegue(withIdentifier: "unwindToRaffles", sender: self)
    }
    
    func updateTicketNumber(){
        //print(database.selectAllTicketByRaffle(ID: (raffle?.id)!))
        print(database.selectAllTickets())
        if let tickets = database.selectAllTicketByRaffle(ID: (raffle?.id)!)
        {
            print(tickets)
            for ticket in tickets
            {
                let ticketSeq = ticket.ticketNumber.components(separatedBy: "#")[1]
                let ticketNumber = String(describing: ticket.raffleId) + "@" + nameInput.text! + "#" + ticketSeq
                print(ticketNumber)
                database.updateTicketNumberBy(ticketID: ticket.id, ticketNumber: ticketNumber)
            }
        }
    }
    
    /*  Validate input value
     */
    func validation() -> String {
        var result: String = "true"
        
        /*  Check emptiness
         */
        if nameInput.text == "" {
            result = "Name cannot empty."
            return result
        }
        else if awardInput.text == "" {
            result = "Award cannot empty."
            return result
        }
        else if !isPositiveNumber(award: String(awardInput.text!)) {
            result = "Award accepts positive number only."
            return result
        }
        else if ticketsInput.text == "" {
            result = "Tickets cannot empty."
            return result
        }
        else if !isPositiveNumber(award: String(ticketsInput.text!)) {
            result = "Number of ticket accecpts positive number only."
            return result
        }
        else if startInput.text == "" {
            result = "Select a Start date for the raffle."
            return result
        }
        else if endInput.text == "" {
            result = "Select an End date for the raffle."
            return result
        }
        else if priceInput.text == "" {
            result = "Please set a ticket price."
            return result
        }
        else if !isPositiveNumber(award: String(priceInput.text!)) {
            result = "Price accepts positive number only."
            return result
        }
        else if limitInput.text == "" {
            result = "Please set a maximum number of ticket that a person can purchase."
            return result
        }
        else if !isPositiveNumber(award: String(limitInput.text!)) {
            result = "Limit accepts positive number only."
            return result
        }
        
        return result
    }
    
    // Check positive number
    private func isPositiveNumber(award: String) -> Bool {
        let awardRegEx = "^[1-9]+[0-9]*$"
        
        let result = NSPredicate(format: "SELF MATCHES %@", awardRegEx)
        return result.evaluate(with: award)
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
