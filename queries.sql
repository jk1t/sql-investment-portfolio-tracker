-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

-- SELECT
-- Which stocks paid the most dividends last year, with the total per ticker.
SELECT "dividends"."ticker", SUM("amount_per_share") AS "total" FROM "dividends"
JOIN "stocks" ON "stocks"."ticker" = "dividends"."ticker"
WHERE "pay_date" LIKE '2025-%'
GROUP BY "dividends"."ticker"
ORDER BY "total" DESC;

-- Shares currently held per ticker and account (total bought minus total sold)
SELECT "bought"."ticker", "bought"."account_id",
"bought"."shares" - "sold"."shares" AS "shares"
FROM (
    SELECT "ticker", "account_id", SUM("shares") AS "shares"
    FROM "transactions"
    WHERE "type" = 'buy'
    GROUP BY "ticker", "account_id"
) AS "bought"
JOIN (
    SELECT "ticker", "account_id", SUM("shares") AS "shares"
    FROM "transactions"
    WHERE "type" = 'sell'
    GROUP BY "ticker", "account_id"
) AS "sold"
ON "bought"."ticker" = "sold"."ticker"
AND "bought"."account_id" = "sold"."account_id"
ORDER BY "shares" DESC;

-- Gross cost of all buys per account (ignores sells, so not the cost of shares still held)
SELECT "account_id", SUM ("shares" * "price") AS "cost" FROM "transactions"
WHERE "type" = 'buy'
GROUP BY "account_id";

-- Current value of each holding at its latest closing price
SELECT "holdings"."ticker", "holdings"."account_id",
"holdings"."shares" * "latest"."close" AS "value"
FROM (
    SELECT "bought"."ticker", "bought"."account_id",
    "bought"."shares" - "sold"."shares" AS "shares"
    FROM (
        SELECT "ticker", "account_id", SUM("shares") AS "shares"
        FROM "transactions"
        WHERE "type" = 'buy'
        GROUP BY "ticker", "account_id"
    ) AS "bought"
    JOIN (
        SELECT "ticker", "account_id", SUM("shares") AS "shares"
        FROM "transactions"
        WHERE "type" = 'sell'
        GROUP BY "ticker", "account_id"
    ) AS "sold"
    ON "bought"."ticker" = "sold"."ticker"
    AND "bought"."account_id" = "sold"."account_id"
) AS "holdings"
JOIN (
    SELECT "ticker", "close"
    FROM "prices"
    WHERE "date" = (
        SELECT MAX("date") FROM "prices" AS "p"
        WHERE "p"."ticker" = "prices"."ticker"
        )
) AS "latest"
ON "holdings"."ticker" = "latest"."ticker"
ORDER BY "value" DESC;

-- Dividends received in 2025, grouped by sector
SELECT "sector", SUM ("amount_per_share") AS "total" FROM "dividends"
JOIN "stocks" ON "stocks"."ticker" = "dividends"."ticker"
WHERE "pay_date" LIKE '2025-%'
GROUP BY "sector"
ORDER BY "total" DESC;

-- Dividends received in 2025 per month, using substr to extract the YYYY-MM part of pay_date
SELECT substr ("pay_date", 1, 7) AS "month", SUM ("amount_per_share") AS "total" FROM "dividends"
JOIN "stocks" ON "stocks"."ticker" = "dividends"."ticker"
WHERE "pay_date" LIKE '2025-%'
GROUP BY substr ("pay_date", 1, 7)
ORDER BY "month";

-- Dividend yield per holding: dividends per share divided by gross buy cost, per ticker and account
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
) AS "cost_total"
ON "dividend_total"."ticker" = "cost_total"."ticker"
AND "dividend_total"."account_id" = "cost_total"."account_id"
ORDER BY "yield" DESC;

-- Total dividends per share and total gross buy cost for each account, side by side
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
) AS "buy_total"
ON "dividend_total"."account_id" = "buy_total"."account_id";

-- Tickers in dividends or transactions that have no matching stock (should return no rows)
SELECT "dividends"."ticker"
FROM "dividends"
LEFT JOIN "stocks" ON "stocks"."ticker" = "dividends"."ticker"
WHERE "stocks"."ticker" IS NULL
UNION
SELECT "transactions"."ticker"
FROM "transactions"
LEFT JOIN "stocks" ON "stocks"."ticker" = "transactions"."ticker"
WHERE "stocks"."ticker" IS NULL;

-- All transactions for one account, sorted by date (can have any account id)
SELECT "date", "ticker", "type", "shares", "price"
FROM "transactions"
WHERE "account_id" = 1
ORDER BY "date";

-- Dividends received in 2025 as a list (tax-season view)
SELECT "ticker", "pay_date", "amount_per_share"
FROM "dividends"
WHERE "pay_date" LIKE '2025-%'
ORDER BY "pay_date";

-- Stocks in one sector (can have any sector)
SELECT "ticker", "name"
FROM "stocks"
WHERE "sector" = 'Technology'
ORDER BY "ticker";

-- Latest closing price for one ticker (can have any ticker)
SELECT "date", "close"
FROM "prices"
WHERE "ticker" = 'AAPL'
ORDER BY "date" DESC
LIMIT 1;


-- INSERT
-- Add a second brokerage account (can have any name and type)
INSERT INTO "accounts" ("name", "type")
VALUES ('Second Brokerage', 'brokerage');

-- Record a buy of 5 shares of AAPL in the new account (account_id 2)
INSERT INTO "transactions" ("account_id", "ticker", "date", "type", "shares", "price")
VALUES (2, 'AAPL', '2026-11-09', 'buy', 5, 350.69);


-- UPDATE
-- Correct a bad closing price for AAPL on 2026-11-09
UPDATE "prices"
SET "close" = 350.69
WHERE "ticker" = 'AAPL' AND "date" = '2026-11-09';

-- Change the sector of MSFT (can be replace with any stock's correct sector and ticker)
UPDATE "stocks"
SET "sector" = 'Technology'
WHERE "ticker" = 'MSFT';


-- DELETE
-- Remove one buy transaction by id (can be replaced with any id)
DELETE FROM "transactions"
WHERE "id" = 3;
