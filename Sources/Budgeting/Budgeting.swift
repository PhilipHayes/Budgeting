import Foundation
import SwiftData

/// Represents the unit type that can be budgeted
public enum BudgetUnit: Codable {
    case money(currency: String)
    case time(unit: String)
    case numeric(unit: String)
    
    private enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    private enum UnitType: String, Codable {
        case money, time, numeric
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .money(let currency):
            try container.encode(UnitType.money, forKey: .type)
            try container.encode(currency, forKey: .value)
        case .time(let unit):
            try container.encode(UnitType.time, forKey: .type)
            try container.encode(unit, forKey: .value)
        case .numeric(let unit):
            try container.encode(UnitType.numeric, forKey: .type)
            try container.encode(unit, forKey: .value)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(UnitType.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)
        
        switch type {
        case .money:
            self = .money(currency: value)
        case .time:
            self = .time(unit: value)
        case .numeric:
            self = .numeric(unit: value)
        }
    }
}

/// Represents a single transaction in the budget
@Model
public final class Transaction {
    public var category: String
    public var amount: Double
    public var date: Date
    public var details: String?
    public var startTime: Date?
    public var endTime: Date?
    
    public var timeRange: ClosedRange<Date>? {
        guard let start = startTime, let end = endTime else { return nil }
        return start...end
    }
    
    public init(category: String, amount: Double, date: Date = Date(), description: String? = nil, timeRange: ClosedRange<Date>? = nil) {
        self.category = category
        self.amount = amount
        self.date = date
        self.details = description
        self.startTime = timeRange?.lowerBound
        self.endTime = timeRange?.upperBound
    }
}

/// Stores and manages transaction history
public struct Ledger {
    private var transactions: [Transaction]
    
    public init() {
        self.transactions = []
    }
    
    public mutating func record(_ transaction: Transaction) {
        transactions.append(transaction)
    }
    
    public func transactions(for category: String) -> [Transaction] {
        transactions.filter { $0.category == category }
    }
    
    public func totalSpent(for category: String) -> Double {
        transactions(for: category).reduce(0) { $0 + $1.amount }
    }
}

/// Represents a category in the budget
@Model
public final class BudgetCategory {
    public var name: String
    public var allocated: Double
    @Relationship(deleteRule: .cascade) public var transactions: [Transaction]
    
    public var spent: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    public var remaining: Double {
        allocated - spent
    }
    
    public init(name: String, allocated: Double) {
        self.name = name
        self.allocated = allocated
        self.transactions = []
    }
}

/// Main budget structure that manages categories and tracks spending
@Model
public final class Budget {
    public var name: String
    public var unit: BudgetUnit
    @Relationship(deleteRule: .cascade) public var categories: [BudgetCategory]
    
    public init(name: String, unit: BudgetUnit) {
        self.name = name
        self.unit = unit
        self.categories = []
    }
    
    /// Convenience initializer for money budgets
    public convenience init(name: String, currency: String) {
        self.init(name: name, unit: .money(currency: currency))
    }
    
    /// Convenience initializer for time budgets
    public convenience init(name: String, timeUnit: String) {
        self.init(name: name, unit: .time(unit: timeUnit))
    }
    
    public func allocate(category: String, amount: Double) {
        if let existing = categories.first(where: { $0.name == category }) {
            existing.allocated = amount
        } else {
            categories.append(BudgetCategory(name: category, allocated: amount))
        }
    }
    
    public func record(amount: Double, category: String, description: String? = nil, timeRange: ClosedRange<Date>? = nil) throws {
        guard let cat = categories.first(where: { $0.name == category }) else {
            throw BudgetError.categoryNotFound
        }
        
        let transaction = Transaction(
            category: category,
            amount: amount,
            description: description,
            timeRange: timeRange
        )
        
        cat.transactions.append(transaction)
    }
    
    public func remaining(for category: String) throws -> Double {
        guard let cat = categories.first(where: { $0.name == category }) else {
            throw BudgetError.categoryNotFound
        }
        return cat.remaining
    }
    
    public func transactions(for category: String) throws -> [Transaction] {
        guard let cat = categories.first(where: { $0.name == category }) else {
            throw BudgetError.categoryNotFound
        }
        return cat.transactions
    }
    
    public var allTransactions: [Transaction] {
        categories.flatMap { $0.transactions }
    }
    
    public func report() -> [(String, Double, Double, Double)] {
        categories.map { cat in
            (cat.name, cat.allocated, cat.spent, cat.remaining)
        }
    }
}

/// Errors that can occur during budget operations
public enum BudgetError: Error {
    case categoryNotFound
}


