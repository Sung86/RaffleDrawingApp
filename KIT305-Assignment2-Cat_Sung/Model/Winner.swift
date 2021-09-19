public struct Winner
{
    var id :Int32
    var prize: String
    var ticketNumber: String //ticket number format: raffleID + "@" + raffleName + "#" + sequenceNumber
    var raffleId:Int32 //the raffle that this ticket belongs to
    var drawnTime: String
    var customerIdentity:String //customer personal id - can be any
    var customerName: String
    var customerPhone: String
    var customerEmail: String
    
}
