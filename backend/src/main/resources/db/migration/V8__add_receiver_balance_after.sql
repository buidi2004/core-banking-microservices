-- Add receiver_balance_after to store target wallet's snapshot balance
ALTER TABLE transactions
ADD COLUMN receiver_balance_after DECIMAL(19, 2);
