import UIKit

class TicketsListTableViewCell: UITableViewCell {

    @IBOutlet var ticketIdLabel: UILabel!
    @IBOutlet var customerNameLabel: UILabel!
    @IBOutlet var purchaseTimeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
