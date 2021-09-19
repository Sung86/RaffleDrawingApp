import UIKit

class HistoryDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var raffleName: UILabel!
    @IBOutlet var raffleStart: UILabel!
    @IBOutlet var raffleEnd: UILabel!
    @IBOutlet var tickets: UILabel!
    
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "RaffleDatabase")
    var raffle : Raffle?
    var winnerTickets = [Winner]()
    @IBOutlet var winnerTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        //print(raffle?.id)
         //print(database.selectAllWinner())
        winnerTickets = database.selectAllWinnerByRaffle(ID: (raffle?.id)!)!
        //print(winnerTickets)
        
        winnerTableView.dataSource = self
        winnerTableView.delegate = self
        
        // Do any additional setup after loading the view.
        if let displayRaffle = raffle {
            if !displayRaffle.image.isEmpty {
                imageView.image = UIImage(data: Data.init(base64Encoded: displayRaffle.image, options: .init(rawValue: 0))!)
            }
            
            raffleName.text = displayRaffle.name
            raffleStart.text = displayRaffle.start
            raffleEnd.text = displayRaffle.end
            tickets.text = "\(displayRaffle.numberOfSoldTicket) / \(displayRaffle.tickets)"
        }
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return winnerTickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryDetailTableViewCell", for: indexPath)
        cell.selectionStyle = .none
        // Configure the cell...
        let ticket = winnerTickets[indexPath.row]
        if let ticketCell = cell as? HistoryDetailTableViewCell {
            ticketCell.customerName.text = ticket.customerName
            ticketCell.ticketNumber.text = ticket.ticketNumber
            ticketCell.prize.text = "$" + String(ticket.prize)
        }
        
        return cell
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
