# Expense Tracker - Development Notes

## Money/Currency Handling

### Current Approach

- **Decimal Type**: Used Elixir's `Decimal` library for all monetary amounts to avoid floating-point precision issues
- **Storage**: Amounts stored as `DECIMAL(10,2)` type in PostgreSQL with proper precision and scale
- **Validation**: Comprehensive validation including:
  - All amounts must be greater than 0
  - Maximum 2 decimal places for currency precision
  - Reasonable amount limits (up to $99,999,999.99)
  - Date constraints (10 years past to 1 year future)
- **Database Constraints**: Check constraints at DB level for positive amounts
- **Concurrency Safety**: Database transactions for atomic operations
- **Budget Tracking**: Real-time budget analysis with over-budget detection
- **Performance**: Optimized indexes for financial calculations

### Multi-Currency Extension Strategy

If extending for multiple currencies, I would implement:

1. **Currency Entity**:

   ```elixir
   defmodule ExpenseTracker.Expenses.Currency do
     schema "currencies" do
       field :code, :string  # USD, EUR, GBP
       field :name, :string  # US Dollar, Euro, British Pound
       field :symbol, :string # $, €, £
       field :decimal_places, :integer # 2 for most, 0 for JPY
     end
   end
   ```

2. **Modified Schemas**:

   ```elixir
   # Add to both Category and Expense schemas
   belongs_to :currency, Currency
   ```

3. **Exchange Rate Service**:

   - External API integration (e.g., Open Exchange Rates)
   - Cached rates with periodic updates
   - Historical rate storage for accurate reporting

4. **Money Library Integration**:

   - Consider using the `money` library for Elixir
   - Provides built-in currency conversion and formatting
   - Better handling of currency-specific decimal places

5. **Reporting Considerations**:
   - Base currency selection for consolidated reports
   - Real-time vs historical rate conversions
   - Multi-currency budget tracking

## Architectural Decisions

### 1. Phoenix LiveView Architecture

- **Choice**: Used Phoenix LiveView for real-time UI updates
- **Benefits**:
  - Rich interactive experience without JavaScript complexity
  - Real-time updates when expenses are added/modified
  - Server-side rendering with client-side interactivity
- **Trade-offs**:
  - Requires WebSocket connection
  - More server memory usage per connection

### 2. Context-Driven Design

- **Structure**: Followed Phoenix contexts pattern with `ExpenseTracker.Expenses`
- **Benefits**:
  - Clear business logic boundaries
  - Easy to test and maintain
  - Follows Phoenix conventions
- **Implementation**: All database operations go through context functions

### 3. Database Design

- **UUIDs**: Used binary UUIDs for primary keys for better distributed system support
- **Associations**:
  - Category `has_many` Expenses
  - Expense `belongs_to` Category
- **Constraints**:
  - Foreign key constraints for data integrity
  - Unique constraints on category names

### 4. Real-time Updates

- **PubSub**: Implemented Phoenix.PubSub for broadcasting expense changes
- **Subscriptions**: LiveViews subscribe to relevant topics
- **Scope**: Updates filtered by category relevance to avoid unnecessary re-renders

## Trade-offs and Shortcuts

### Due to Time Constraints

1. **Authentication/Authorization**:

   - **Shortcut**: No user authentication implemented
   - **Production Need**: Would add Phoenix.LiveView.Auth or similar
   - **Multi-tenancy**: Each user should only see their own data

2. **Error Handling**:

   - **Current**: Basic error handling in LiveViews
   - **Improvement**: More comprehensive error boundaries and user-friendly messages

3. **Data Validation**:

   - **Current**: Basic Ecto validations
   - **Enhancement**: More sophisticated business rules (e.g., expense date validation, budget limits)

4. **UI/UX**:

   - **Current**: Basic Tailwind CSS styling
   - **Enhancement**: More polished design, better mobile responsiveness

5. **Performance Optimizations**:

   - **Current**: Basic database queries
   - **Improvement**: Query optimization, pagination for large datasets, database indexing

6. **Testing Coverage**:
   - **Current**: Schema tests and basic LiveView tests
   - **Missing**: Integration tests, property-based tests, performance tests

## Testing Strategy

### Current Implementation

1. **Schema Tests** (`test/expense_tracker/expenses/`):

   - **Category Tests**: Validation rules, associations, constraints
   - **Expense Tests**: All changeset validations, foreign key constraints
   - **Coverage**: Field validation, edge cases, database constraints

2. **Test Structure**:

   ```elixir
   describe "changeset/2" do
     # Valid/invalid attribute tests
     # Required field validations
     # Business rule validations (amount > 0, length limits)
     # Database constraint tests (uniqueness, foreign keys)
   end

   describe "schema associations" do
     # Association type verification
     # Preloading tests
   end

   describe "schema fields" do
     # Field type verification
     # Primary key configuration
   end
   ```

### Testing Philosophy

1. **Fast Feedback**: Unit tests for business logic run quickly
2. **Comprehensive Coverage**: Test both happy path and edge cases
3. **Database Integration**: Use `ExpenseTracker.DataCase` for tests requiring DB
4. **Realistic Data**: Use proper data types (Decimal for money, Date for dates)

### Future Testing Enhancements

1. **Context Tests**:

   ```elixir
   # Test the Expenses context functions
   test "create_expense/1 with valid data creates expense"
   test "list_expenses/0 returns all expenses"
   test "total_expenses_by_category/1 calculates correctly"
   ```

2. **LiveView Integration Tests**:

   ```elixir
   # Test user workflows
   test "user can create category and add expenses"
   test "budget tracking updates in real-time"
   ```

3. **Property-Based Testing**:

   ```elixir
   # Using StreamData for comprehensive testing
   property "expense amounts are always positive"
   property "budget calculations are mathematically correct"
   ```

4. **Performance Tests**:
   - Large dataset handling
   - Concurrent user scenarios
   - Memory usage monitoring

## Future Improvements

### Immediate (Next Sprint)

1. Add user authentication
2. Improve error handling and user feedback
3. Add data export functionality
4. Implement expense search and filtering

### Medium Term

1. Multi-currency support
2. Recurring expense templates
3. Expense categories with subcategories
4. Receipt image attachments
5. Budget alerts and notifications

### Long Term

1. Mobile app development
2. Advanced reporting and analytics
3. Integration with banking APIs
4. Machine learning for expense categorization
5. Team/family expense sharing

## Development Environment

- **Elixir Version**: 1.15+
- **Phoenix Version**: 1.7+
- **Database**: PostgreSQL with Decimal support
- **Testing**: ExUnit with Phoenix.ConnCase and Phoenix.LiveViewTest
- **Code Quality**: Mix format, Credo for static analysis

## Deployment Considerations

- **Environment Variables**: Database credentials, secret keys
- **Database Migrations**: Ensure proper rollback strategies
- **Asset Compilation**: Tailwind CSS and esbuild configuration
- **Health Checks**: Database connectivity, application status
- **Monitoring**: Error tracking, performance metrics
