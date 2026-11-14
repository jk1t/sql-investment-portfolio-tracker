-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it

-- TABLES
-- Table 1: accounts. Shows each account that holds stocks
CREATE TABLE "accounts" (
    "id" INTEGER,
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    PRIMARY KEY ("id")
);

-- Table 2: stocks. Shows each stocks that can be held, identified by ticker
CREATE TABLE "stocks" (
    "id" INTEGER,
    "ticker" TEXT NOT NULL UNIQUE,
    "name" TEXT NOT NULL,
    "sector" TEXT NOT NULL,
    PRIMARY KEY ("id")
);

-- Table 3: transactions. Shows buys and sells of a stock
CREATE TABLE "transactions" (
    "id" INTEGER,
    "account_id" INTEGER NOT NULL,
    "ticker" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "type" TEXT NOT NULL CHECK ("type" IN ('buy', 'sell')),
    "shares" NUMERIC NOT NULL CHECK ("shares" > 0),
    "price" NUMERIC NOT NULL CHECK ("price" > 0),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("account_id") REFERENCES "accounts"("id"),
    FOREIGN KEY ("ticker") REFERENCES "stocks"("ticker")
);

-- Table 4: dividends. Shows cash paid per share on each pay date in account
CREATE TABLE "dividends" (
    "id" INTEGER,
    "account_id" INTEGER NOT NULL,
    "ticker" TEXT NOT NULL,
    "pay_date" DATE NOT NULL,
    "amount_per_share" NUMERIC NOT NULL CHECK ("amount_per_share" > 0),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("account_id") REFERENCES "accounts"("id"),
    FOREIGN KEY ("ticker") REFERENCES "stocks"("ticker")
);

-- Table 5: prices. Shows daily closing price of each stock
CREATE TABLE "prices" (
    "id" INTEGER,
    "ticker" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "close" NUMERIC NOT NULL CHECK ("close" > 0),
    PRIMARY KEY ("id"),
    UNIQUE ("ticker", "date"),
    FOREIGN KEY ("ticker") REFERENCES "stocks"("ticker")
);

-- VIEWS
-- View 1: holdings. Shows shares owned per ticker and account.
CREATE VIEW "holdings" AS
SELECT "bought"."ticker", "bought"."account_id",
"bought"."shares" - COALESCE("sold"."shares", 0) AS "shares"
FROM (
    SELECT "ticker", "account_id", SUM("shares") AS "shares"
    FROM "transactions"
    WHERE "type" = 'buy'
    GROUP BY "ticker", "account_id"
) AS "bought"
LEFT JOIN (
    SELECT "ticker", "account_id", SUM("shares") AS "shares"
    FROM "transactions"
    WHERE "type" = 'sell'
    GROUP BY "ticker", "account_id"
) AS "sold"
ON "bought"."ticker" = "sold"."ticker"
AND "bought"."account_id" = "sold"."account_id";

-- View 2: current values. Shows the current market value of each holding.
CREATE VIEW "current_values" AS
SELECT "holdings"."ticker", "holdings"."account_id",
"holdings"."shares" * "latest"."close" AS "value"
FROM "holdings"
JOIN (
    SELECT "ticker", "close"
    FROM "prices"
    WHERE "date" = (
        SELECT MAX("date") FROM "prices" AS "p"
        WHERE "p"."ticker" = "prices"."ticker"
    )
) AS "latest"
ON "holdings"."ticker" = "latest"."ticker";

-- View 3: dividends by sector. Shows dividends received in 2025, grouped by sector.
CREATE VIEW "dividends_by_sector" AS
SELECT "sector", SUM("amount_per_share") AS "total"
FROM "dividends"
JOIN "stocks" ON "stocks"."ticker" = "dividends"."ticker"
WHERE "pay_date" LIKE '2025-%'
GROUP BY "sector";

-- View 4: monthly income. Shows dividends received in 2025 per month, using substr to extract the YYYY-MM part of pay_date.
CREATE VIEW "monthly_income" AS
SELECT substr("pay_date", 1, 7) AS "month", SUM("amount_per_share") AS "total"
FROM "dividends"
JOIN "stocks" ON "stocks"."ticker" = "dividends"."ticker"
WHERE "pay_date" LIKE '2025-%'
GROUP BY substr("pay_date", 1, 7);

-- View 5: dividend yield. Shows dividend yield per holding (dividends per share divided by gross buy cost, per ticker and account).
CREATE VIEW "dividend_yield" AS
SELECT "dividend_total"."ticker", "dividend_total"."account_id",
CAST("dividend_total"."total" AS REAL) / "cost_total"."cost" AS "yield"
FROM (
    SELECT "ticker", "account_id", SUM("amount_per_share") AS "total"
    FROM "dividends"
    GROUP BY "ticker", "account_id"
) AS "dividend_total"
JOIN (
    SELECT "ticker", "account_id", SUM("shares" * "price") AS "cost"
    FROM "transactions"
    WHERE "type" = 'buy'
    GROUP BY "ticker", "account_id"
) AS "cost_total" ON "dividend_total"."ticker" = "cost_total"."ticker" AND "dividend_total"."account_id" = "cost_total"."account_id";

-- View 6: account summary. Shows total dividends per share and total gross buy cost for each account, side by side.
CREATE VIEW "account_summary" AS
SELECT "dividend_total"."account_id",
"dividend_total"."total" AS "dividends",
"buy_total"."cost" AS "buys"
FROM (
    SELECT "account_id", SUM("amount_per_share") AS "total"
    FROM "dividends"
    GROUP BY "account_id"
) AS "dividend_total"
JOIN (
    SELECT "account_id", SUM("shares" * "price") AS "cost"
    FROM "transactions"
    WHERE "type" = 'buy'
    GROUP BY "account_id"
) AS "buy_total" ON "dividend_total"."account_id" = "buy_total"."account_id";


-- INDEX
-- Index 1: dividends_ticker_pay_date. Speeds up the dividend queries that filter by ticker and pay date
CREATE INDEX "dividends_ticker_pay_date" ON "dividends" ("ticker", "pay_date");

-- Index 2: transactions_type_ticker_account. Speeds up the holdings, cost, yield, and sell-check queries that filter by type and group by ticker and account.
CREATE INDEX "transactions_type_ticker_account" ON "transactions" ("type", "ticker", "account_id");


-- TRIGGERS
-- Trigger 1: sell check. Rejects a sell larger than the shares currently held for that ticker and account.
CREATE TRIGGER "sell_check"
BEFORE INSERT ON "transactions"
WHEN NEW."type" = 'sell'
BEGIN
SELECT RAISE(ABORT, 'Cannot sell more shares than you hold')
WHERE NEW."shares" > COALESCE((
SELECT "shares" FROM "holdings"
WHERE "holdings"."ticker" = NEW."ticker"
AND "holdings"."account_id" = NEW."account_id"
), 0);
END;
