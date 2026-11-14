-- Sample data for the investment portfolio tracker (data was provided by AI).
-- Loads one account, three stocks, buys, sells, dividends, and prices.

-- Accounts
INSERT INTO "accounts" ("name", "type") VALUES
    ('Main Brokerage', 'brokerage');

-- Stocks
INSERT INTO "stocks" ("ticker", "name", "sector") VALUES
    ('AAPL', 'Apple Inc.', 'Technology'),
    ('MSFT', 'Microsoft Corp.', 'Technology'),
    ('JNJ', 'Johnson & Johnson', 'Healthcare');

-- Buys (must come before sells, so the sell check has holdings to compare against)
INSERT INTO "transactions" ("account_id", "ticker", "date", "type", "shares", "price") VALUES
    (1, 'AAPL', '2025-01-15', 'buy', 10, 180.00),
    (1, 'MSFT', '2025-02-10', 'buy', 5, 400.00),
    (1, 'JNJ', '2025-03-01', 'buy', 8, 150.00);

-- Sells
INSERT INTO "transactions" ("account_id", "ticker", "date", "type", "shares", "price") VALUES
    (1, 'AAPL', '2025-07-01', 'sell', 4, 205.00),
    (1, 'JNJ', '2025-09-15', 'sell', 3, 158.00);

-- Dividends (amount per share)
INSERT INTO "dividends" ("account_id", "ticker", "pay_date", "amount_per_share") VALUES
    (1, 'AAPL', '2025-02-14', 0.25),
    (1, 'AAPL', '2025-05-15', 0.25),
    (1, 'MSFT', '2025-03-10', 0.75),
    (1, 'JNJ', '2025-06-01', 1.19);

-- Closing prices at year end
INSERT INTO "prices" ("ticker", "date", "close") VALUES
    ('AAPL', '2025-12-31', 195.00),
    ('MSFT', '2025-12-31', 420.00),
    ('JNJ', '2025-12-31', 160.00);
