public struct Ticket
{
    var id :Int32
    var ticketNumber: String //ticket number format: raffleID + "@" + raffleName + "#" + sequenceNumber
    var price: Double
    var purchasedDateTime:String
    var marginValue: String // if it is not margin ticket then value is none 
    var raffleId:Int32 //the raffle that this ticket belongs to
    var customerIdentity:String //customer personal id - can be any
    var customerName: String
    var customerPhone: String
    var customerEmail: String

}
