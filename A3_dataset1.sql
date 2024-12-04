-- title: Assignment 3 Part 1 Scripts
-- author: Tianzi Cui
DECLARE
 -- constants
    k_debit                CONSTANT transaction_detail.transaction_type%type:='D';
 -- explicit cursor for new_transactions
    CURSOR c_new_transaction IS
    SELECT
        *
    FROM
        new_transactions;
    r_new_transaction      new_transactions%rowtype;
 -- variable to check how many rows are there in transaction_history with a specific transaction_no
    v_exist_transaction_no NUMBER:=0;
 --varibale to store the default transaction type of an account
    v_default_account_type account_type.default_trans_type%type;
BEGIN
    OPEN c_new_transaction;
    LOOP
        FETCH c_new_transaction INTO r_new_transaction;
        EXIT WHEN c_new_transaction%notfound;
 -- check if the transaction_no already exists in transaction_history
        SELECT
            COUNT(*) INTO v_exist_transaction_no
        FROM
            transaction_history
        WHERE
            r_new_transaction.transaction_no = transaction_no;
        IF(v_exist_transaction_no = 0) THEN
 -- Insert into transaction_history
            INSERT INTO transaction_history VALUES(
                r_new_transaction.transaction_no,
                r_new_transaction.transaction_date,
                r_new_transaction.description
            );
            COMMIT;
        END IF;
 -- Insert into transaction_details
        INSERT INTO transaction_detail VALUES(
            r_new_transaction.account_no,
            r_new_transaction.transaction_no,
            r_new_transaction.transaction_type,
            r_new_transaction.transaction_amount
        );
        COMMIT;
 -- update account balance
        SELECT
            account_type.default_trans_type INTO v_default_account_type
        FROM
            account_type
        WHERE
            account_type_code = (
                SELECT
                    account_type_code
                FROM
                    account
                WHERE
                    account_no = r_new_transaction.account_no
            );
        IF(v_default_account_type = k_debit) THEN
            IF(r_new_transaction.transaction_type=k_debit) THEN
                UPDATE account
                SET
                    account_balance = account_balance + r_new_transaction.transaction_amount
                WHERE
                    account_no = r_new_transaction.account_no;
                COMMIT;
            ELSE
                UPDATE account
                SET
                    account_balance = account_balance - r_new_transaction.transaction_amount
                WHERE
                    account_no = r_new_transaction.account_no;
                COMMIT;
            END IF;
        ELSE
            IF(r_new_transaction.transaction_type=k_debit) THEN
                UPDATE account
                SET
                    account_balance = account_balance - r_new_transaction.transaction_amount
                WHERE
                    account_no = r_new_transaction.account_no;
                COMMIT;
            ELSE
                UPDATE account
                SET
                    account_balance = account_balance + r_new_transaction.transaction_amount
                WHERE
                    account_no = r_new_transaction.account_no;
                COMMIT;
            END IF;
        END IF;
 -- delete current transaction from new_transactions
        DELETE FROM new_transactions
        WHERE
            transaction_no = r_new_transaction.transaction_no;
        COMMIT;
    END LOOP;

    CLOSE c_new_transaction;
END;
/