import UIKit

class HistoryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
  
    @IBOutlet var historyRaffleCollectionView: UICollectionView!
    var raffles = [Raffle]()
    var filteredRaffle = [Raffle]()
    var endedRaffles = [Raffle]()
    var allWinnerTickets = [[Winner]]()
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "RaffleDatabase")
    override func viewDidLoad() {
        
        raffles = [Raffle]()
        filteredRaffle = [Raffle]()
        endedRaffles = [Raffle]()
        allWinnerTickets = [[Winner]]()
        
        super.viewDidLoad()
        raffles = database.selectAllRaffles()
        print(raffles.count)
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "HH:mm dd-MM-yyyy"
        endedRaffles = raffles.filter{Date() >= dateFormat.date(from: $0.end)!}
         print(endedRaffles.count)
        filteredRaffle = endedRaffles
        for raffle in endedRaffles {
            if let winnerTickets = database.selectAllWinnerByRaffle(ID: raffle.id){
                allWinnerTickets.append(winnerTickets)
                
            }
        }
 
        let raffleCollectionViewLayout = historyRaffleCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        raffleCollectionViewLayout?.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 0, right: 5)
        raffleCollectionViewLayout?.itemSize = CGSize(width: (view.frame.width/2)-10, height: 250)
        raffleCollectionViewLayout?.invalidateLayout()
        self.historyRaffleCollectionView.reloadData()
        
    }
    override func viewDidAppear(_ animated: Bool) {
    
        self.viewDidLoad()
        print("h")
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return endedRaffles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HistoryRaffleCell", for: indexPath) as! HistoryCollectionViewCell
        
        
        let raffle = endedRaffles[indexPath.row]
        if let raffleCell = cell as? HistoryCollectionViewCell
        {
            if !raffle.image.isEmpty{
                raffleCell.imageView.image =  UIImage(data: Data.init(base64Encoded: raffle.image, options: .init(rawValue: 0))!)
            }
            raffleCell.price.text = "$"+String(raffle.price)
            raffleCell.raffleName.text = raffle.name
            
            if allWinnerTickets.count > 0 {
                let winner  = allWinnerTickets[indexPath.row]
                if winner.indices.contains(0) {
                    raffleCell.firstWinner.text = winner[0].customerName
                }else{
                    raffleCell.firstWinner.text = "No Winner Yet!"
                }
                if winner.indices.contains(1){
                    raffleCell.secondWinner.text = winner[1].customerName
                }else{
                     raffleCell.secondWinner.text  = "No Winner Yet!"
                }
                if winner.indices.contains(2){
                    raffleCell.thirdWinner.text = winner[2].customerName
                }else{
                    raffleCell.thirdWinner.text  = "No Winner Yet!"
                }
            
            }
        }
        
        return cell
        
    }
    //Filter raffle collection view based on searched text
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.endedRaffles.removeAll()
        self.allWinnerTickets.removeAll()
        if searchBar.text!.isEmpty{
            self.endedRaffles = self.filteredRaffle

        }
        else {
            for raffle in self.filteredRaffle{
                if raffle.name.lowercased().contains(searchBar.text!.lowercased()){
                    self.endedRaffles.append(raffle)
                    self.allWinnerTickets.append(database.selectAllWinnerByRaffle(ID: raffle.id)!)
                }
            }
            
        }
        self.historyRaffleCollectionView.reloadData()
    }

    //Dismiss keyboard when search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        guard let historyDetailViewController = segue.destination as? HistoryDetailViewController else
        {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        guard let selectedRaffleCell = sender as? HistoryCollectionViewCell else
        {
            fatalError("Unexpected sender: \( String(describing: sender))")
        }
        guard let indexPath = historyRaffleCollectionView.indexPath(for: selectedRaffleCell)else
        {
            fatalError("The selected cell is not being displayed by the table")
        }
        
        let selectedRaffle = endedRaffles[indexPath.row]
        historyDetailViewController.raffle = selectedRaffle
    }
 

}
