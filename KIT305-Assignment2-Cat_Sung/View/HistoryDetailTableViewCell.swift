import UIKit

class HistoryDetailTableViewCell: UITableViewCell {
    @IBOutlet var customerName: UILabel!
    @IBOutlet var ticketNumber: UILabel!
    @IBOutlet var prize: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
