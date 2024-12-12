import Testing
@testable import Budgeting
import Foundation

/// Test suite for the Budgeting library
struct BudgetingTests {
    
    /// Test budget initialization with different unit types
    @Test func testBudgetInitialization() throws {
        let moneyBudget = Budget(name: "Monthly", currency: "USD")
        #expect(moneyBudget.name == "Monthly")
        
        let timeBudget = Budget(name: "Project", timeUnit: "hours")
        #expect(timeBudget.name == "Project")
        
        let customBudget = Budget(name: "Resources", unit: .numeric(unit: "items"))
        #expect(customBudget.name == "Resources")
    }
    
    /// Test category allocation and updates
    @Test func testCategoryAllocation() throws {
        let budget = Budget(name: "Test", currency: "USD")
        
        budget.allocate(category: "Food", amount: 500)
        #expect(try budget.remaining(for: "Food") == 500)
        
        // Test updating existing category
        budget.allocate(category: "Food", amount: 600)
        #expect(try budget.remaining(for: "Food") == 600)
    }
    
    /// Test spending recording and remaining balance
    @Test func testSpendingAndRemaining() throws {
        let budget = Budget(name: "Test", currency: "USD")
        budget.allocate(category: "Entertainment", amount: 200)
        
        try budget.record(amount: 50, category: "Entertainment")
        #expect(try budget.remaining(for: "Entertainment") == 150)
        
        try budget.record(amount: 25, category: "Entertainment")
        #expect(try budget.remaining(for: "Entertainment") == 125)
    }
    
    /// Test error handling for non-existent categories
    @Test func testErrorHandling() throws {
        let budget = Budget(name: "Test", currency: "USD")
        
        #expect(throws: BudgetError.categoryNotFound) {
            _ = try budget.remaining(for: "NonExistent")
        }
        
        #expect(throws: BudgetError.categoryNotFound) {
            try budget.record(amount: 50, category: "NonExistent")
        }
    }
    
    /// Test budget report generation
    @Test func testBudgetReport() throws {
        let budget = Budget(name: "Test", currency: "USD")
        budget.allocate(category: "Food", amount: 500)
        budget.allocate(category: "Transport", amount: 300)
        
        try budget.record(amount: 150, category: "Food")
        try budget.record(amount: 50, category: "Transport")
        
        let report = budget.report()
        #expect(report.count == 2)
        
        let foodReport = report.first { $0.0 == "Food" }
        #expect(foodReport?.1 == 500) // allocated
        #expect(foodReport?.2 == 150) // spent
        #expect(foodReport?.3 == 350) // remaining
    }
    
    /// Test transaction recording with descriptions
    @Test func testTransactionRecording() throws {
        let budget = Budget(name: "Test", currency: "USD")
        budget.allocate(category: "Food", amount: 500)
        
        try budget.record(
            amount: 50,
            category: "Food",
            description: "Grocery shopping"
        )
        
        let transactions = try budget.transactions(for: "Food")
        #expect(transactions.count == 1)
        #expect(transactions[0].amount == 50)
        #expect(transactions[0].details == "Grocery shopping")
    }
    
    /// Test time budget functionality
    @Test func testTimeBudget() throws {
        let budget = Budget(name: "Project", timeUnit: "hours")
        budget.allocate(category: "Development", amount: 40)
        
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(2.5 * 3600) // 2.5 hours
        
        try budget.record(
            amount: 2.5,
            category: "Development",
            description: "Feature implementation",
            timeRange: startTime...endTime
        )
        
        let transactions = try budget.transactions(for: "Development")
        #expect(transactions.count == 1)
        #expect(transactions[0].timeRange?.lowerBound == startTime)
        #expect(transactions[0].timeRange?.upperBound == endTime)
    }
    
    /// Test Ledger functionality
    @Test func testLedger() throws {
        var ledger = Ledger()
        
        let transaction1 = Transaction(category: "Food", amount: 50, description: "Lunch")
        let transaction2 = Transaction(category: "Food", amount: 30, description: "Dinner")
        let transaction3 = Transaction(category: "Transport", amount: 20)
        
        ledger.record(transaction1)
        ledger.record(transaction2)
        ledger.record(transaction3)
        
        let foodTransactions = ledger.transactions(for: "Food")
        #expect(foodTransactions.count == 2)
        #expect(ledger.totalSpent(for: "Food") == 80)
        #expect(ledger.totalSpent(for: "Transport") == 20)
        #expect(ledger.transactions(for: "NonExistent").isEmpty)
    }
    
    /// Test BudgetUnit coding
    @Test func testBudgetUnitCoding() throws {
        let moneyUnit = BudgetUnit.money(currency: "USD")
        let timeUnit = BudgetUnit.time(unit: "hours")
        let numericUnit = BudgetUnit.numeric(unit: "items")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test money unit
        let moneyData = try encoder.encode(moneyUnit)
        let decodedMoney = try decoder.decode(BudgetUnit.self, from: moneyData)
        if case .money(let currency) = decodedMoney {
            #expect(currency == "USD")
        }
        
        // Test time unit
        let timeData = try encoder.encode(timeUnit)
        let decodedTime = try decoder.decode(BudgetUnit.self, from: timeData)
        if case .time(let unit) = decodedTime {
            #expect(unit == "hours")
        }
        
        // Test numeric unit
        let numericData = try encoder.encode(numericUnit)
        let decodedNumeric = try decoder.decode(BudgetUnit.self, from: numericData)
        if case .numeric(let unit) = decodedNumeric {
            #expect(unit == "items")
        }
    }
    
    /// Test Transaction time range handling
    @Test func testTransactionTimeRange() throws {
        let now = Date()
        let later = now.addingTimeInterval(3600)
        
        let transaction1 = Transaction(
            category: "Work",
            amount: 2.0,
            timeRange: now...later
        )
        #expect(transaction1.timeRange?.lowerBound == now)
        #expect(transaction1.timeRange?.upperBound == later)
        
        let transaction2 = Transaction(category: "Work", amount: 1.0)
        #expect(transaction2.timeRange == nil)
    }
    
    /// Test BudgetCategory calculations
    @Test func testBudgetCategoryCalculations() throws {
        let category = BudgetCategory(name: "Test", allocated: 100)
        #expect(category.spent == 0)
        #expect(category.remaining == 100)
        
        category.transactions.append(
            Transaction(category: "Test", amount: 30)
        )
        #expect(category.spent == 30)
        #expect(category.remaining == 70)
        
        category.transactions.append(
            Transaction(category: "Test", amount: 50)
        )
        #expect(category.spent == 80)
        #expect(category.remaining == 20)
    }
    
    /// Test transaction history retrieval
    @Test func testTransactionHistory() throws {
        let budget = Budget(name: "Test", currency: "USD")
        budget.allocate(category: "Food", amount: 500)
        
        try budget.record(amount: 50, category: "Food", description: "Lunch")
        try budget.record(amount: 30, category: "Food", description: "Dinner")
        
        let transactions = try budget.transactions(for: "Food")
        #expect(transactions.count == 2)
        #expect(transactions[0].details == "Lunch")
        #expect(transactions[1].details == "Dinner")
        #expect(transactions[0].amount + transactions[1].amount == 80)
    }
    
    /// Test all transactions across categories
    @Test func testAllTransactions() throws {
        let budget = Budget(name: "Test", currency: "USD")
        budget.allocate(category: "Food", amount: 500)
        budget.allocate(category: "Transport", amount: 200)
        
        try budget.record(amount: 50, category: "Food")
        try budget.record(amount: 30, category: "Transport")
        
        let allTransactions = budget.allTransactions
        #expect(allTransactions.count == 2)
        
        let totalSpent = allTransactions.reduce(0) { $0 + $1.amount }
        #expect(totalSpent == 80)
    }
    
    /// Test transactions retrieval error handling
    @Test func testTransactionsErrorHandling() throws {
        let budget = Budget(name: "Test", currency: "USD")
        
        // Test non-existent category
        #expect(throws: BudgetError.categoryNotFound) {
            _ = try budget.transactions(for: "NonExistent")
        }
        
        // Test successful case
        budget.allocate(category: "Food", amount: 500)
        try budget.record(amount: 50, category: "Food")
        let transactions = try budget.transactions(for: "Food")
        #expect(transactions.count == 1)
    }
}
