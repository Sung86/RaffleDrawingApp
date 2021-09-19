import UIKit

class RaffleDetailViewController: UIViewController {

    @IBOutlet var test: UIImageView!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var raffleName: UILabel!
    @IBOutlet var time: UILabel!
    @IBOutlet var tickets: UILabel!
    @IBOutlet var award: UILabel!
    @IBOutlet var price: UILabel!
    @IBOutlet var descr: UITextView! 
    @IBOutlet var ticketSellingProgression: UIProgressView!

    var goingNextView: Bool = false;
    
    
    var raffle : Raffle?
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "RaffleDatabase")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if let displayRaffle = raffle {
            if !displayRaffle.image.isEmpty {
                 imageView.image = UIImage(data: Data.init(base64Encoded: displayRaffle.image, options: .init(rawValue: 0))!)
            }
            
            raffleName.text = displayRaffle.name
            time.text = displayRaffle.end
            tickets.text = String(displayRaffle.numberOfSoldTicket) + "/" + String(displayRaffle.tickets) 
            award.text = "$" + displayRaffle.award
            price.text = "$" + String(displayRaffle.price)
            descr.text = displayRaffle.description
            
            ticketSellingProgression.progress = Float(Double(displayRaffle.numberOfSoldTicket)/Double(displayRaffle.tickets))
        }
        self.setNeedsFocusUpdate()
        self.loadViewIfNeeded()

    }
    override func viewWillDisappear(_ animated: Bool) {
        print("in view will dispaper method")
        print(self.goingNextView)
        if(self.goingNextView == false) {//if it navigates back to Raffles collecion view
             self.performSegue(withIdentifier: "unwindToRaffles", sender: self)
        }
    }
    @IBAction func unwindToRaffleDetail(_ sender: UIStoryboardSegue){
        self.goingNextView = false
        self.raffle = database.selectRaffleBy(ID: (self.raffle?.id)!)
        viewDidLoad()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.goingNextView = true
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowEditRaffleSegue"
        {
            let navigationViewController = segue.destination as? UINavigationController
            (navigationViewController?.viewControllers[0] as? EditRaffleViewController)?.raffle = self.raffle
            
        }
        else if segue.identifier ==  "ShowSellTicketSegue"
        {
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "HH:mm dd-MM-yyyy"
            let currentTime = Date()
            let startTime = dateFormat.date(from: (self.raffle?.start)!)
            let endTime = dateFormat.date(from: (self.raffle?.end)!)
            
            print(currentTime)
            print(startTime)
            print(endTime)
            //Selling ticket is only allowed when raffle is active
            if currentTime >= startTime! && currentTime < endTime! {
                let navigationViewController = segue.destination as? UINavigationController
                (navigationViewController?.viewControllers[0] as? SellRaffleTableViewController)?.raffle = self.raffle
            }else{
                let alert = UIAlertController(title: "Error message", message: "Raffle is not active, you cannot sell tickets! Maybe the raffle has ended or not yet started!", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }else if segue.identifier == "ShowBuyerListSegue"
        {
            print("going to buyer list")
            print(self.raffle?.id as Any)
            let ticketsListTableViewController = segue.destination as? TicketsListTableViewController
            ticketsListTableViewController?.raffleId = self.raffle?.id
        }
        else if segue.identifier == "DrawWinnerSegue" {
            
            let thisRaffle = raffle
            let availableTickets = thisRaffle!.tickets - thisRaffle!.numberOfSoldTicket
            
            /* End Date is String type
             Current date is Date type. Need to compare those two before drawing the raffle
             */
            
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "HH:mm dd-MM-yyyy"
            
            let currentTime = Date()
           // let startTime = dateFormat.date(from: (thisRaffle?.start)!)
            let endTime = dateFormat.date(from: (thisRaffle?.end)!)
            
            // Temporary conditions - there would be more conditions if needed //
            /**
             * Early Drawing - if raffle is still active && all tickets have been sold out
             * Normal Time Drawing - if raffle has ended
             */
            if (currentTime < endTime! && availableTickets == 0) || (currentTime > endTime!)
            {
                let drawRaffleViewController = segue.destination as? DrawRaffleViewController
                drawRaffleViewController?.raffle = self.raffle
                
            }
            else {
                //pop up an alert
                let alert = UIAlertController(title: "Error message", message: "You cannot draw this raffle now!", preferredStyle: UIAlertController.Style.alert)
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                // show the alert
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    

}
