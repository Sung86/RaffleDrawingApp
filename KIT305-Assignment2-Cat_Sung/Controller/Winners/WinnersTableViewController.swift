import UIKit

class WinnersTableViewController: UITableViewController,UISearchBarDelegate  {
    var winnerTickets = [Winner]()
    let database : SQLiteDatabase = SQLiteDatabase(databaseName:"RaffleDatabase")
    var filteredWinner = [Winner]()
    @IBOutlet var winnerListTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.winnerTickets = database.selectAllWinner()!
        self.filteredWinner = winnerTickets
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
       
    }
    override func viewDidAppear(_ animated: Bool) {
        self.winnerTickets = database.selectAllWinner()!
        self.filteredWinner = winnerTickets
        winnerListTableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.winnerTickets.removeAll()
        if searchBar.text!.isEmpty{
            self.winnerTickets = self.filteredWinner
        }
        else {
            for winner in self.filteredWinner{
                if winner.customerName.lowercased().contains(searchBar.text!.lowercased()){
                    self.winnerTickets.append(winner)
                }
            }
            
        }
        self.winnerListTableView.reloadData()
    }
    
    //Dismiss keyboard when search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (winnerTickets.count)
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WinnersTableViewCell", for: indexPath)
        cell.selectionStyle = .none
        if (winnerTickets.count) > 0 {
            let winner = winnerTickets[indexPath.row]
            if let winnerCell = cell as? WinnersTableViewCell
            {
                if winner.customerIdentity == "" {
                    winnerCell.identity.text = "n/a"
                } else {
                    winnerCell.identity.text = winner.customerIdentity
                }
                
                if winner.customerEmail == "" {
                    winnerCell.email.text = "n/a"
                } else {
                    winnerCell.email.text = winner.customerEmail
                }
                
                winnerCell.name.text = winner.customerName
                winnerCell.phoneNumber.text = String(winner.customerPhone)
                winnerCell.prize.text = "$" + String(winner.prize)
            }
        }
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
