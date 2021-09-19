import UIKit

class TicketsListTableViewController: UITableViewController, UISearchBarDelegate {
    
    var tickets = [Ticket]()
    var filteredTickets = [Ticket]()
    var raffleId: Int32?
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "RaffleDatabase")

    @IBOutlet var ticketTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tickets = database.selectAllTicketByRaffle(ID: (self.raffleId)!)!
        filteredTickets = tickets //initial filtered tickets
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
    }
  
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tickets.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketsListTableViewCell", for: indexPath)
        
        let ticket = tickets[indexPath.row]
        print("1")
        if let ticketCell = cell as? TicketsListTableViewCell {
            ticketCell.ticketIdLabel.text = ticket.ticketNumber
            ticketCell.customerNameLabel.text = ticket.customerName
            ticketCell.purchaseTimeLabel.text = String(ticket.purchasedDateTime)
            //ticketCell.purchaseTimeLabel.text =  String((ticket.purchasedDateTime.prefix(16)))//remove the time unit 'sec'
        }
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.tickets.removeAll()
        
        if searchBar.text!.isEmpty{
            self.tickets = self.filteredTickets
        }
        else {
            for ticket in self.filteredTickets{
                if ticket.customerName.lowercased().contains(searchBar.text!.lowercased()){
                    self.tickets.append(ticket)
                }
            }
        }
        self.ticketTableView.reloadData()
    }
    
    //Dismiss keyboard when search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    @IBAction func unwindToTicketsList(_ sender: UIStoryboardSegue){
        //reload datas
        tickets = database.selectAllTicketByRaffle(ID: (self.raffleId)!)!
        self.ticketTableView.reloadData()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        
        if segue.identifier == "TicketDetailSegue" {
            
            guard let ticketsDetailViewController = segue.destination as? TicketDetailViewController else
            {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedTicketCell = sender as? TicketsListTableViewCell else
            {
                fatalError("Unexpected sender: \( String(describing: sender))")
            }
            guard let indexPath = ticketTableView.indexPath(for: selectedTicketCell)else
            {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedTicket = tickets[indexPath.row]
            ticketsDetailViewController.ticket = selectedTicket
        }
    }
}
