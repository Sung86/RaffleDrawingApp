import UIKit

class ExistingBuyerTableViewCell: UITableViewCell {
    
    @IBOutlet var customerPhone: UILabel!
    @IBOutlet var customerName: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
