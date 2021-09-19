import UIKit
private let reuseIdentifier = "Cell"
class RaffleViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UISearchBarDelegate {
    
    
    @IBOutlet var raffleCollectionView: UICollectionView!
    
    var raffles = [Raffle]()
    var filteredRaffle = [Raffle]()
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "RaffleDatabase")
    override func viewDidLoad() {
        
        super.viewDidLoad()
        raffles = database.selectAllRaffles()
        filteredRaffle = raffles //initial filtered raffles
        self.navigationItem.setHidesBackButton(true, animated:true)
        //Reload the collectionView to update data
        raffleCollectionView.reloadData()
        
        let raffleCollectionViewLayout = raffleCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        raffleCollectionViewLayout?.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 0, right: 5)
        raffleCollectionViewLayout?.itemSize = CGSize(width: (view.frame.width/2)-10, height: 250)
        raffleCollectionViewLayout?.invalidateLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.viewDidLoad()
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return raffles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! RaffleCollectionViewCell

        let raffle = raffles[indexPath.row]
        if let raffleCell = cell as? RaffleCollectionViewCell
        {
            if !raffle.image.isEmpty{
                raffleCell.imageView.image =  UIImage(data: Data.init(base64Encoded: raffle.image, options: .init(rawValue: 0))!)
            }
            raffleCell.price.text = "$"+String(raffle.price)
            raffleCell.raffleName.text = raffle.name
            raffleCell.time.text = raffle.end
            raffleCell.tickets.text = String(raffle.numberOfSoldTicket) + "/" + String(raffle.tickets) 
            raffleCell.award.text = "$" + String(raffle.award)
            raffleCell.ticketSellingProgression.progress = Float(Double(raffle.numberOfSoldTicket)/Double(raffle.tickets))
        }

        return cell
    }
    //Filter raffle collection view based on searched text
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.raffles.removeAll()
        if searchBar.text!.isEmpty{
            self.raffles = self.filteredRaffle
        }
        else {
            for raffle in self.filteredRaffle{
                if raffle.name.lowercased().contains(searchBar.text!.lowercased()){
                    self.raffles.append(raffle)
                }
            }
            
        }
        self.raffleCollectionView.reloadData()
    }
    
    //Dismiss keyboard when search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    @IBAction func unwindToRaffles(_ sender: UIStoryboardSegue){
        viewDidLoad() // call this func to reload the collection view
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "ShowRaffleDetailSegue"
        {
            guard let raffleDetailViewController = segue.destination as? RaffleDetailViewController else
            {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedRaffleCell = sender as? RaffleCollectionViewCell else
            {
                fatalError("Unexpected sender: \( String(describing: sender))")
            }
            guard let indexPath = raffleCollectionView.indexPath(for: selectedRaffleCell)else
            {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedRaffle = raffles[indexPath.row]
            raffleDetailViewController.raffle = selectedRaffle
        }
    }
}
