import Foundation
import SQLite3

class SQLiteDatabase
{
    /* This variable is of type OpaquePointer, which is effectively the same as a C pointer (recall the SQLite API is a C-library). The variable is declared as an optional, since it is possible that a database connection is not made successfully, and will be nil until such time as we create the connection.*/
    private var db: OpaquePointer?
    
    /* Change this value whenever you make a change to table structure.
     When a version change is detected, the updateDatabase() function is called,
     which in turn calls the createTables() function.
     
     WARNING: DOING THIS WILL WIPE YOUR DATA, unless you modify how updateDatabase() works.
     */
    private let DATABASE_VERSION = 102
    
    // Constructor, Initializes a new connection to the database
    /* This code checks for the existence of a file within the application’s document directory with the name <dbName>.sqlite. If the file doesn’t exist, it attempts to create it for us. Since our application has the ability to write into this directory, this should happen the first time that we run the application without fail (it can still possibly fail if the device is out of storage space).
     The remainder of the function checks to see if we are able to open a successful connection to this database file using the sqlite3_open() function. With all of the SQLite functions we will be using, we can check for success by checking for a return value of SQLITE_OK.
     */
    init(databaseName dbName:String)
    {
        //get a file handle somewhere on this device
        //(if it doesn't exist, this should create the file for us)
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(dbName).sqlite")
        
        //try and open the file path as a database
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK
        {
            print("Successfully opened connection to database at \(fileURL.path)")
            self.dbName = dbName
            checkForUpgrade();
        }
        else
        {
            print("Unable to open database at \(fileURL.path)")
            printCurrentSQLErrorMessage(db)
        }
    }
    
    deinit
    {
        /* We should clean up our memory usage whenever the object is deinitialized, */
        sqlite3_close(db)
    }
    private func printCurrentSQLErrorMessage(_ db: OpaquePointer?)
    {
        let errorMessage = String.init(cString: sqlite3_errmsg(db))
        print("Error:\(errorMessage)")
    }
    
    private func createTables(tableNames: [String])
    {
        for tableName in tableNames {
            createTable(tableName: tableName)
        }
    }
    private func dropTables(tableNames: [String])
    {
        for tableName in tableNames {
            dropTable(tableName:tableName)
        }
    }
    
    /* --------------------------------*/
    /* ----- VERSIONING FUNCTIONS -----*/
    /* --------------------------------*/
    private var dbName:String = ""
    func checkForUpgrade()
    {
        // get the current version number
        let defaults = UserDefaults.standard
        let lastSavedVersion = defaults.integer(forKey: "DATABASE_VERSION_\(dbName)")
        
        // detect a version change
        if (DATABASE_VERSION > lastSavedVersion)
        {
            onUpdateDatabase(previousVersion:lastSavedVersion, newVersion: DATABASE_VERSION);
            
            // set the stored version number
            defaults.set(DATABASE_VERSION, forKey: "DATABASE_VERSION_\(dbName)")
        }
    }
    
    func onUpdateDatabase(previousVersion : Int, newVersion : Int)
    {
        print("Detected Database Version Change (was:\(previousVersion), now:\(newVersion))")
        
        //handle the change (simple version)
        let tableNames = ["Raffle", "Ticket", "Winner"]
        dropTables(tableNames: tableNames)
        createTables(tableNames: tableNames)
    }
    
    
    
    /* --------------------------------*/
    /* ------- HELPER FUNCTIONS -------*/
    /* --------------------------------*/
    
    /* Pass this function a CREATE sql string, and a table name, and it will create a table
     You should call this function from createTables()
     */
    private func createTableWithQuery(_ createTableQuery:String, tableName:String)
    {
        /*
         1.    sqlite3_prepare_v2()
         2.    sqlite3_step()
         3.    sqlite3_finalize()
         */
        //prepare the statement
        var createTableStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, createTableQuery, -1, &createTableStatement, nil) == SQLITE_OK
        {
            //execute the statement
            if sqlite3_step(createTableStatement) == SQLITE_DONE
            {
                print("\(tableName) table created.")
            }
            else
            {
                print("\(tableName) table could not be created.")
                printCurrentSQLErrorMessage(db)
            }
        }
        else
        {
            print("CREATE TABLE statement for \(tableName) could not be prepared.")
            printCurrentSQLErrorMessage(db)
        }
        
        
        
        //clean up
        sqlite3_finalize(createTableStatement)
        
    }
    /* Pass this function a table name.
     You should call this function from dropTables()
     */
    private func dropTable(tableName:String)
    {
        /*
         1.    sqlite3_prepare_v2()
         2.    sqlite3_step()
         3.    sqlite3_finalize()
         */
        
        //prepare the statement
        let query = "DROP TABLE IF EXISTS \(tableName)"
        var statement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil)     == SQLITE_OK
        {
            //run the query
            if sqlite3_step(statement) == SQLITE_DONE {
                print("\(tableName) table deleted.")
            }
        }
        else
        {
            print("\(tableName) table could not be deleted.")
            printCurrentSQLErrorMessage(db)
        }
        
        //clear up
        sqlite3_finalize(statement)
    }
    
    //helper function for handling INSERT statements
    //provide it with a binding function for replacing the ?'s for setting values
    private func insertWithQuery(_ insertStatementQuery : String, bindingFunction:(_ insertStatement: OpaquePointer?)->())
    {
        /*
         Similar to the CREATE statement, the INSERT statement needs the following SQLite functions to be called (note the addition of the binding function calls):
         1.    sqlite3_prepare_v2()
         2.    sqlite3_bind_***()
         3.    sqlite3_step()
         4.    sqlite3_finalize()
         */
        // First, we prepare the statement, and check that this was successful. The result will be a C-
        // pointer to the statement:
        var insertStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, insertStatementQuery, -1, &insertStatement, nil) == SQLITE_OK
        {
            //handle bindings
            bindingFunction(insertStatement)
            
            /* Using the pointer to the statement, we can call the sqlite3_step() function. Again, we only
             step once. We check that this was successful */
            //execute the statement
            if sqlite3_step(insertStatement) == SQLITE_DONE
            {
                print("Successfully inserted row.")
            }
            else
            {
                print("Could not insert row.")
                printCurrentSQLErrorMessage(db)
            }
        }
        else
        {
            print("INSERT statement could not be prepared.")
            printCurrentSQLErrorMessage(db)
        }
        
        //clean up
        sqlite3_finalize(insertStatement)
    }
    
    //helper function to run Select statements
    //provide it with a function to do *something* with each returned row
    //(optionally) Provide it with a binding function for replacing the "?"'s in the WHERE clause
    private func selectWithQuery(
        _ selectStatementQuery : String,
        eachRow: (_ rowHandle: OpaquePointer?)->(),
        bindingFunction: ((_ rowHandle: OpaquePointer?)->())? = nil)
    {
        //prepare the statement
        var selectStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, selectStatementQuery, -1, &selectStatement, nil) == SQLITE_OK
        {
            //do bindings, only if we have a bindingFunction set
            //hint, to do selectMovieBy(id:) you will need to set a bindingFunction (if you don't hardcode the id)
            
            //iterate over the result
            while sqlite3_step(selectStatement) == SQLITE_ROW
            {
                eachRow(selectStatement);
            }
            
        }
        else
        {
            print("SELECT statement could not be prepared.")
            printCurrentSQLErrorMessage(db)
        }
        //clean up
        sqlite3_finalize(selectStatement)
    }
    
    private func deleteWithQuery( _ deleteStatementQuery : String,  bindingFunction: ((_ rowHandle: OpaquePointer?)->()))
    {
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementQuery, -1, &deleteStatement, nil) == SQLITE_OK
        {
             bindingFunction(deleteStatement)
            if sqlite3_step(deleteStatement) == SQLITE_DONE
            {
                print("Successfully delete row.")
            }
            else
            {
                print("Could not delete row.")
                printCurrentSQLErrorMessage(db)
            }
        }
        else
        {
            print("DELETE statement could not be prepared.")
            printCurrentSQLErrorMessage(db)
        }
        sqlite3_finalize(deleteStatement)
    }
    
    //helper function to run update statements.
    //Provide it with a binding function for replacing the "?"'s in the WHERE clause
    private func updateWithQuery(
        _ updateStatementQuery : String,
        bindingFunction: ((_ rowHandle: OpaquePointer?)->()))
    {
        //prepare the statement
        var updateStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, updateStatementQuery, -1, &updateStatement, nil) == SQLITE_OK
        {
            //do bindings
            bindingFunction(updateStatement)
            
            //execute
            if sqlite3_step(updateStatement) == SQLITE_DONE
            {
                print("Successfully inserted row.")
            }
            else
            {
                print("Could not insert row.")
                printCurrentSQLErrorMessage(db)
            }
        }
        else
        {
            print("UPDATE statement could not be prepared.")
            printCurrentSQLErrorMessage(db)
        }
        //clean up
        sqlite3_finalize(updateStatement)
    }
    
   
    /* --------------------------------*/
    /* --- ADD YOUR TABLES ETC HERE ---*/
    /* --------------------------------*/
    let createRaffleTableQuery = """
            CREATE TABLE Raffle (
                ID INTEGER PRIMARY KEY AUTOINCREMENT,
                Image CHAR(255),
                Name CHAR(255),
                Award CHAR(255),
                Number_Of_Sold_Ticket INTEGER,
                Tickets INTEGER,
                Start CHAR(255),
                End CHAR(255),
                Price INTEGER,
                Limited INTEGER,
                Draw_Type CHAR(255),
                Description CHAR(255)
            );
            """
    let createTicketTableQuery = """
            CREATE TABLE Ticket (
                ID INTEGER PRIMARY KEY AUTOINCREMENT,
                Ticket_Number CHAR(255),
                Price DOUBLE,
                Puchased_Date_Time CHAR(255),
                Margin_Value CHAR(255),
                Raffle_ID INTEGER,
                Customer_Identity CHAR(255),
                Customer_Name CHAR(255),
                Customer_Phone CHAR(255),
                Customer_Email CHAR(255)
            );
            """
    let createWinnerTableQuery = """
            CREATE TABLE Winner (
                ID INTEGER PRIMARY KEY AUTOINCREMENT,
                Prize Double,
                Ticket_Number CHAR(255),
                Raffle_ID INTEGER,
                Drawn_Time CHAR(255),
                Customer_Identity CHAR(255),
                Customer_Name CHAR(255),
                Customer_Phone CHAR(255),
                Customer_Email CHAR(255)
            );
            """
    func createTable(tableName:String)
    {
        switch tableName {
            case "Raffle":
                createTableWithQuery(createRaffleTableQuery, tableName: tableName)
                break
            case "Ticket":
                createTableWithQuery(createTicketTableQuery, tableName: tableName)
                break
            case "Winner":
                createTableWithQuery(createWinnerTableQuery, tableName: tableName)
                break
            default:
                break
        }
    }
    
    func insertRaffle(raffle:Raffle) {
        let insertStatementQuery = "INSERT INTO Raffle (image, name, award, number_of_sold_ticket, tickets, start, end, price, limited, draw_type, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?);"
        
        insertWithQuery(insertStatementQuery, bindingFunction: { (insertStatement) in
            sqlite3_bind_text(insertStatement, 1, NSString(string:raffle.image).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, NSString(string:raffle.name).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, NSString(string:raffle.award).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 4, raffle.numberOfSoldTicket)
            sqlite3_bind_int(insertStatement, 5, raffle.tickets)
            sqlite3_bind_text(insertStatement, 6, NSString(string:raffle.start).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, NSString(string:raffle.end).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 8, raffle.price)
            sqlite3_bind_int(insertStatement, 9, raffle.limited)
            sqlite3_bind_text(insertStatement, 10, NSString(string:raffle.drawType).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 11, NSString(string:raffle.description).utf8String, -1, nil)
        })
    }
   
    func insertTicket(ticket:Ticket) {
        let insertStatementQuery = "INSERT INTO Ticket (Ticket_Number, Price, Puchased_Date_Time, Margin_Value, Raffle_ID, Customer_Identity, Customer_Name, Customer_Phone, Customer_Email) VALUES (?,?, ?, ?, ?, ?, ?, ?, ?);"
        
        insertWithQuery(insertStatementQuery, bindingFunction: { (insertStatement) in
            sqlite3_bind_text(insertStatement, 1, NSString(string:ticket.ticketNumber).utf8String, -1, nil)
            sqlite3_bind_double(insertStatement, 2, ticket.price)
            sqlite3_bind_text(insertStatement, 3, NSString(string:ticket.purchasedDateTime).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, NSString(string:ticket.marginValue).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 5, ticket.raffleId)
            sqlite3_bind_text(insertStatement, 6, NSString(string:ticket.customerIdentity).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, NSString(string:ticket.customerName).utf8String, -1, nil)
            //sqlite3_bind_int(insertStatement, 8, ticket.customerPhone)
            sqlite3_bind_text(insertStatement, 8, NSString(string:ticket.customerPhone).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 9, NSString(string:ticket.customerEmail).utf8String, -1, nil)
        })
    }
    func insertWinner(winner:Winner) {
        let insertStatementQuery = "INSERT INTO Winner (Prize, Ticket_Number,  Raffle_ID, Drawn_Time, Customer_Identity, Customer_Name, Customer_Phone, Customer_Email) VALUES (?,?, ?, ?, ?, ?, ?, ?);"
        insertWithQuery(insertStatementQuery, bindingFunction: { (insertStatement) in
            sqlite3_bind_text(insertStatement, 1, NSString(string:winner.prize).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, NSString(string:winner.ticketNumber).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 3, winner.raffleId)
            sqlite3_bind_text(insertStatement, 4, NSString(string:winner.drawnTime).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 5, NSString(string:winner.customerIdentity).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 6, NSString(string:winner.customerName).utf8String, -1, nil)
            //sqlite3_bind_int(insertStatement, 7, winner.customerPhone)
            sqlite3_bind_text(insertStatement, 7, NSString(string:winner.customerPhone).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 8, NSString(string:winner.customerEmail).utf8String, -1, nil)
        })
    }
    
    func selectAllRaffles() -> [Raffle] {
        var result = [Raffle]()
        let selectStatementQuery = "SELECT * FROM Raffle"
        
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
            let raffle = Raffle (
                id: sqlite3_column_int(row, 0),
                image: String(cString:sqlite3_column_text(row, 1)),
                name: String(cString:sqlite3_column_text(row, 2)),
                award: String(cString:sqlite3_column_text(row, 3)),
                numberOfSoldTicket: sqlite3_column_int(row, 4),
                tickets: sqlite3_column_int(row, 5),
                start: String(cString:sqlite3_column_text(row, 6)),
                end: String(cString:sqlite3_column_text(row, 7)),
                price: sqlite3_column_int(row, 8),
                limited: sqlite3_column_int(row, 9),
                drawType: String(cString:sqlite3_column_text(row,10)),
                description: String(cString:sqlite3_column_text(row, 11))
            )
            result += [raffle]
        })
        return result
    }
    
    /**
     * For getting distinct values of column and order by the column name.
     * select all tickets' information with the condition of grouping by and order by the given column
     * @param groupByColumn the given column name for user of group by and order by
     * @return [Ticket] all the retrieved tickets
     */
    func selectAllTicketBy(groupByColumn: String) -> [Ticket]{
        var result = [Ticket]()
        let selectStatementQuery = "SELECT * FROM Ticket Group By \(groupByColumn) ORDER BY \(groupByColumn)"
        
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
            let ticket = Ticket (
                id: sqlite3_column_int(row, 0),
                ticketNumber:  String(cString:sqlite3_column_text(row, 1)),
                price: Double(sqlite3_column_int(row, 2)),
                purchasedDateTime: String(cString:sqlite3_column_text(row, 3)),
                marginValue: String(cString:sqlite3_column_text(row, 4)),
                raffleId: sqlite3_column_int(row, 5),
                customerIdentity: String(cString:sqlite3_column_text(row, 6)),
                customerName:  String(cString:sqlite3_column_text(row, 7)),
                customerPhone: String(cString:sqlite3_column_text(row, 8)),
                customerEmail: String(cString:sqlite3_column_text(row, 9))
            )
            result += [ticket]
        })
        return result
    }
    func selectAllTickets() -> [Ticket] {
        var result = [Ticket]()
        let selectStatementQuery = "SELECT * FROM Ticket"
        
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
            let ticket = Ticket (
                id: sqlite3_column_int(row, 0),
                ticketNumber:  String(cString:sqlite3_column_text(row, 1)),
                price: Double(sqlite3_column_int(row, 2)),
                purchasedDateTime: String(cString:sqlite3_column_text(row, 3)),
                marginValue: String(cString:sqlite3_column_text(row, 4)),
                raffleId: sqlite3_column_int(row, 5),
                customerIdentity: String(cString:sqlite3_column_text(row, 6)),
                customerName:  String(cString:sqlite3_column_text(row, 7)),
                customerPhone: String(cString:sqlite3_column_text(row, 8)),
                customerEmail: String(cString:sqlite3_column_text(row, 9))
            )
            result += [ticket]
        })
        return result
    }
    
    func selectRaffleBy(ID:Int32) -> Raffle? {
        var result: Raffle?
        let selectStatementQuery = "SELECT * FROM Raffle WHERE ID = \(ID)"
        
        selectWithQuery(selectStatementQuery,
                        eachRow: {(row) in
                            let raffle = Raffle (
                                id: sqlite3_column_int(row, 0),
                                image: String(cString:sqlite3_column_text(row, 1)),
                                name: String(cString:sqlite3_column_text(row, 2)),
                                award: String(cString:sqlite3_column_text(row, 3)),
                                numberOfSoldTicket: sqlite3_column_int(row, 4),
                                tickets: sqlite3_column_int(row, 5),
                                start: String(cString:sqlite3_column_text(row, 6)),
                                end: String(cString:sqlite3_column_text(row, 7)),
                                price: sqlite3_column_int(row, 8),
                                limited: sqlite3_column_int(row, 9),
                                drawType: String(cString:sqlite3_column_text(row, 10)),
                                description: String(cString:sqlite3_column_text(row, 11))
                            )
                            result = raffle
                }
        )
        return result
    }

    func selectAllTicketByRaffle(ID:Int32) -> [Ticket]? {
        var result = [Ticket]()
        let selectStatementQuery = "SELECT * FROM Ticket WHERE Raffle_ID = \(ID)"
        
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
            let ticket = Ticket (
                id: sqlite3_column_int(row, 0),
                ticketNumber:  String(cString:sqlite3_column_text(row, 1)),
                price: Double(sqlite3_column_int(row, 2)),
                purchasedDateTime: String(cString:sqlite3_column_text(row, 3)),
                marginValue: String(cString:sqlite3_column_text(row, 4)),
                raffleId: sqlite3_column_int(row, 5),
                customerIdentity: String(cString:sqlite3_column_text(row, 6)),
                customerName:  String(cString:sqlite3_column_text(row, 7)),
                customerPhone: String(cString:sqlite3_column_text(row, 8)),
                customerEmail: String(cString:sqlite3_column_text(row, 9))
            )
            result += [ticket]
        })
        return result
    }
    
    func selectAllTicketByBuyerAndRaffle(Name:String, ID: Int32) -> [Ticket]? {
        var result = [Ticket]()
 
        let selectStatementQuery = "SELECT * FROM Ticket WHERE Customer_Name = '\(Name)' AND Raffle_ID = \(ID)"
        
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
                let ticket = Ticket (
                    id: sqlite3_column_int(row, 0),
                    ticketNumber:  String(cString:sqlite3_column_text(row, 1)),
                    price: Double(sqlite3_column_int(row, 2)),
                    purchasedDateTime: String(cString:sqlite3_column_text(row, 3)),
                    marginValue: String(cString:sqlite3_column_text(row, 4)),
                    raffleId: sqlite3_column_int(row, 5),
                    customerIdentity: String(cString:sqlite3_column_text(row, 6)),
                    customerName:  String(cString:sqlite3_column_text(row, 7)),
                    customerPhone: String(cString:sqlite3_column_text(row, 8)),
                    customerEmail: String(cString:sqlite3_column_text(row, 9))
                )
            result += [ticket]
            })
        return result
    }
    
    func selectAllWinner() -> [Winner]? {
        var result = [Winner]()
        
        let selectStatementQuery = "SELECT * FROM Winner"
        
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
            let winner = Winner (
                id: sqlite3_column_int(row, 0),
                prize: String(cString:sqlite3_column_text(row, 1)),
                ticketNumber:  String(cString:sqlite3_column_text(row, 2)),
                raffleId: sqlite3_column_int(row, 3),
                drawnTime: String(cString:sqlite3_column_text(row, 4)),
                customerIdentity: String(cString:sqlite3_column_text(row, 5)),
                customerName:  String(cString:sqlite3_column_text(row, 6)),
                customerPhone: String(cString:sqlite3_column_text(row, 7)),
                customerEmail: String(cString:sqlite3_column_text(row, 8))
            )
            result += [winner]
        })
        return result
    }
    func selectAllWinnerByRaffle(ID:Int32) -> [Winner]? {
        var result = [Winner]()
        
        let selectStatementQuery = "SELECT * FROM Winner WHERE Raffle_ID = \(ID) ORDER BY Prize DESC" 
        
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
            let winner = Winner (
                id: sqlite3_column_int(row, 0),
                prize: String(cString:sqlite3_column_text(row, 1)),
                ticketNumber:  String(cString:sqlite3_column_text(row, 2)),
                raffleId: sqlite3_column_int(row, 3),
                drawnTime: String(cString:sqlite3_column_text(row, 4)),
                customerIdentity: String(cString:sqlite3_column_text(row, 5)),
                customerName:  String(cString:sqlite3_column_text(row, 6)),
                customerPhone: String(cString:sqlite3_column_text(row, 7)),
                customerEmail: String(cString:sqlite3_column_text(row, 8))
            )
            result += [winner]
        })
        return result
    }
    
    func updateRaffle(raffle:Raffle) {
        let updateStatementQuery = "UPDATE Raffle SET image = ?, name = ?, award = ?, number_of_sold_ticket = ?, tickets = ?, start = ?, end = ?, price = ?, limited = ?, draw_type = ?, description = ? WHERE ID = ?;"
        
        
        updateWithQuery(
            updateStatementQuery,
                    bindingFunction: { (updateStatement) in
                    sqlite3_bind_text(updateStatement, 1, NSString(string:raffle.image).utf8String, -1, nil)
                    sqlite3_bind_text(updateStatement, 2, NSString(string:raffle.name).utf8String, -1, nil)
                    sqlite3_bind_text(updateStatement, 3, NSString(string:raffle.award).utf8String, -1, nil)
                    sqlite3_bind_int(updateStatement, 4, raffle.numberOfSoldTicket)
                    sqlite3_bind_int(updateStatement, 5, raffle.tickets)
                    sqlite3_bind_text(updateStatement, 6, NSString(string:raffle.start).utf8String, -1, nil)
                    sqlite3_bind_text(updateStatement, 7, NSString(string:raffle.end).utf8String, -1, nil)
                    sqlite3_bind_int(updateStatement, 8, raffle.price)
                    sqlite3_bind_int(updateStatement, 9, raffle.limited)
                    sqlite3_bind_text(updateStatement, 10, NSString(string:raffle.drawType).utf8String, -1, nil)
                    sqlite3_bind_text(updateStatement, 11, NSString(string:raffle.description).utf8String, -1, nil)
                    sqlite3_bind_int(updateStatement, 12, raffle.id)
                })
    }
    
    func updateTicketNumberBy(ticketID: Int32, ticketNumber:String) {
        let updateStatementQuery = "UPDATE Ticket SET Ticket_Number = ? WHERE ID = ?"
        
        updateWithQuery(
            updateStatementQuery,
            bindingFunction: { (updateStatement) in
                sqlite3_bind_text(updateStatement, 1, NSString(string:ticketNumber).utf8String, -1, nil)
                sqlite3_bind_int(updateStatement, 2, ticketID)
        })
    }
    
    func updateCustomerInfoBy(ticketNumber:String, ticket: Ticket) {
        let updateStatementQuery = "UPDATE Ticket SET Customer_Identity = ?, Customer_Name  = ?, Customer_Phone = ?, Customer_Email = ? WHERE Ticket_Number = '\(ticketNumber)';"
        
        updateWithQuery(
            updateStatementQuery,
            bindingFunction: { (updateStatement) in
                sqlite3_bind_text(updateStatement, 1, NSString(string:ticket.customerIdentity).utf8String, -1, nil)
                sqlite3_bind_text(updateStatement, 2, NSString(string:ticket.customerName).utf8String, -1, nil)
                sqlite3_bind_text(updateStatement, 3, NSString(string:ticket.customerPhone).utf8String, -1, nil)
                //sqlite3_bind_int(updateStatement, 3, ticket.customerPhone)
                sqlite3_bind_text(updateStatement, 4, NSString(string:ticket.customerEmail).utf8String, -1, nil)
        })
    }

    func deleteRaffleBy(ID:Int32)
    {
        let deleteStatementQuery = "DELETE FROM Raffle WHERE ID = ?"
        deleteWithQuery(deleteStatementQuery, bindingFunction: { (deleteStatement) in
            sqlite3_bind_int(deleteStatement, 1, ID)
        })
    }
}
