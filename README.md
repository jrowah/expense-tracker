# ExpenseTracker

A Phoenix LiveView application for tracking personal expenses and managing budgets with real-time updates.

## Features

- **Category Management**: Create and manage expense categories with monthly budgets
- **Expense Tracking**: Add, edit, and delete expenses with detailed information
- **Budget Monitoring**: Real-time budget tracking with spending percentages
- **Live Updates**: Real-time UI updates using Phoenix LiveView
- **Decimal Precision**: Accurate money handling using Decimal library

## Prerequisites

Before you begin, ensure you have the following installed:

- **Elixir** (1.15 or later) - [Installation Guide](https://elixir-lang.org/install.html)
- **Erlang/OTP** (26 or later) - Usually comes with Elixir
- **Node.js** (16 or later) - For asset compilation
- **PostgreSQL** (12 or later) - [Installation Guide](https://www.postgresql.org/download/)

### Verify Installation

```bash
elixir --version
node --version
psql --version
```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/expense-tracker.git
cd expense-tracker
```

### 2. Install Dependencies

```bash
# Install Elixir dependencies
mix deps.get

# Install Node.js dependencies for assets
npm install --prefix assets
```

### 3. Database Setup

#### Create Database User (if needed)

```bash
# Connect to PostgreSQL as superuser
sudo -u postgres psql

# Create user and database
CREATE USER expense_tracker WITH PASSWORD 'your_password' CREATEDB;
\q
```

#### Configure Database

Update `config/dev.exs` with your database credentials:

```elixir
config :expense_tracker, ExpenseTracker.Repo,
  username: "expense_tracker",
  password: "your_password",
  hostname: "localhost",
  database: "expense_tracker_dev",
  # ... other config
```

#### Run Setup

```bash
# This will create database, run migrations, and seed data
mix setup
```

Or manually:

```bash
# Create the database
mix ecto.create

# Run migrations
mix ecto.migrate

# Optional: Run seeds (if any)
mix run priv/repo/seeds.exs
```

### 4. Start the Application

```bash
# Start Phoenix server
mix phx.server

# Or start with interactive Elixir shell
iex -S mix phx.server
```

The application will be available at [`http://localhost:4000`](http://localhost:4000)

## Development

### Running Tests

```bash
# Run all tests
mix test

# Run specific test files
mix test test/expense_tracker/expenses/
mix test test/expense_tracker_web/live/

# Run tests with coverage
mix test --cover

# Run tests in watch mode (if you have mix_test_watch)
mix test.watch
```

### Code Quality

```bash
# Format code
mix format

# Check for unused dependencies
mix deps.unlock --check-unused

# Static code analysis (if Credo is installed)
mix credo
```

### Database Operations

```bash
# Create a new migration
mix ecto.gen.migration migration_name

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database (drops, creates, migrates)
mix ecto.reset

# Check migration status
mix ecto.migrations
```

## Project Structure

```
expense_tracker/
├── lib/
│   ├── expense_tracker/          # Business logic contexts
│   │   └── expenses/             # Expenses domain
│   │       ├── category.ex      # Category schema
│   │       └── expense.ex       # Expense schema
│   ├── expense_tracker_web/      # Web interface
│   │   └── live/                 # LiveView modules
│   └── expense_tracker.ex        # Application entry point
├── test/                         # Test files
├── priv/
│   └── repo/
│       └── migrations/           # Database migrations
├── assets/                       # Frontend assets
├── config/                       # Configuration files
└── mix.exs                      # Project definition
```

## Usage

### Creating Categories

1. Navigate to "Categories" in the main menu
2. Click "New Category"
3. Fill in the name, description, and monthly budget
4. Save the category

### Adding Expenses

1. Go to a category's detail page
2. Click "New Expense"
3. Enter expense details (description, amount, date, notes)
4. Save the expense

### Budget Tracking

- Each category shows total expenses vs. monthly budget
- Percentage indicators show spending levels
- Real-time updates when expenses are added/modified

## Environment Variables

For production deployment, set these environment variables:

```bash
# Database
DATABASE_URL=postgresql://user:pass@host/database

# Phoenix
SECRET_KEY_BASE=your_secret_key_base
PHX_HOST=your_domain.com

# Optional
PORT=4000
```

## Troubleshooting

### Common Issues

**Database Connection Error**:

- Ensure PostgreSQL is running: `brew services start postgresql` (macOS) or `sudo service postgresql start` (Linux)
- Check database credentials in `config/dev.exs`
- Verify database exists: `mix ecto.create`

**Asset Compilation Error**:

- Ensure Node.js is installed: `node --version`
- Install asset dependencies: `npm install --prefix assets`
- Clear asset cache: `rm -rf _build/dev/lib/*/priv/static/`

**Port Already in Use**:

- Change port in `config/dev.exs`: `port: 4001`
- Or kill process using port 4000: `lsof -ti:4000 | xargs kill -9`

**Mix Dependencies Error**:

- Clean dependencies: `mix deps.clean --all`
- Reinstall: `mix deps.get`

### Getting Help

- Check the [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- Visit [Elixir Forum](https://elixirforum.com/c/phoenix-forum)
- Review the [NOTES.md](./NOTES.md) file for architectural decisions

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes and add tests
4. Run the test suite: `mix test`
5. Format code: `mix format`
6. Commit your changes: `git commit -am 'Add some feature'`
7. Push to the branch: `git push origin feature/my-feature`
8. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
