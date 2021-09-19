import UIKit

class WinnersTableViewCell: UITableViewCell {

    @IBOutlet var name: UILabel!
    @IBOutlet var email: UILabel!
    @IBOutlet var identity: UILabel!
    @IBOutlet var phoneNumber: UILabel!
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
