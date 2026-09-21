`timescale 1ns/1ps

module tb_vending_machine;

    reg clk;
    reg reset;

    reg [1:0] product_select;

    reg coin_5;
    reg coin_10;
    reg coin_20;

    reg cancel;

    wire [1:0] dispense_product;
    wire dispense;

    wire [7:0] change_amount;
    wire [7:0] refund_amount;

    wire insufficient_money;
    wire transaction_complete;
    wire invalid_selection;
    wire invalid_coin;
    wire coin_overflow;

    integer errors;

    vending_machine dut (
        .clk(clk),
        .reset(reset),
        .product_select(product_select),
        .coin_5(coin_5),
        .coin_10(coin_10),
        .coin_20(coin_20),
        .cancel(cancel),
        .dispense_product(dispense_product),
        .dispense(dispense),
        .change_amount(change_amount),
        .refund_amount(refund_amount),
        .insufficient_money(insufficient_money),
        .transaction_complete(transaction_complete),
        .invalid_selection(invalid_selection),
        .invalid_coin(invalid_coin),
        .coin_overflow(coin_overflow)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task reset_dut;
    begin
        @(negedge clk);

        reset = 1'b1;
        coin_5 = 1'b0;
        coin_10 = 1'b0;
        coin_20 = 1'b0;
        cancel = 1'b0;

        @(posedge clk);
        #1;

        reset = 1'b0;
        #1;
    end
    endtask

    task select_product;
        input [1:0] product;
    begin
        @(negedge clk);
        product_select = product;
        #1;
    end
    endtask

    task insert_5;
    begin
        @(negedge clk);
        coin_5 = 1'b1;

        @(posedge clk);
        #1;

        coin_5 = 1'b0;
        #1;
    end
    endtask

    task insert_10;
    begin
        @(negedge clk);
        coin_10 = 1'b1;

        @(posedge clk);
        #1;

        coin_10 = 1'b0;
        #1;
    end
    endtask

    task insert_20;
    begin
        @(negedge clk);
        coin_20 = 1'b1;

        @(posedge clk);
        #1;

        coin_20 = 1'b0;
        #1;
    end
    endtask

    task cancel_transaction;
    begin
        @(negedge clk);
        cancel = 1'b1;

        @(posedge clk);
        #1;

        cancel = 1'b0;
        #1;
    end
    endtask

    task tick;
    begin
        @(posedge clk);
        #1;
    end
    endtask

    task check_balance;
        input [7:0] expected;
        input [255:0] message;
    begin
        if (dut.balance !== expected) begin
            $display("FAIL: %s | Balance=%0d Expected=%0d",
                     message, dut.balance, expected);
            errors = errors + 1;
        end
        else begin
            $display("PASS: %s | Balance=%0d",
                     message, dut.balance);
        end
    end
    endtask

    task check_purchase;
        input [1:0] expected_product;
        input [7:0] expected_change;
        input [255:0] message;
    begin
        if (dispense !== 1'b1) begin
            $display("FAIL: %s | dispense=0", message);
            errors = errors + 1;
        end

        if (dispense_product !== expected_product) begin
            $display("FAIL: %s | Product=%b Expected=%b",
                     message, dispense_product, expected_product);
            errors = errors + 1;
        end

        if (change_amount !== expected_change) begin
            $display("FAIL: %s | Change=%0d Expected=%0d",
                     message, change_amount, expected_change);
            errors = errors + 1;
        end

        if (transaction_complete !== 1'b1) begin
            $display("FAIL: %s | transaction_complete=0", message);
            errors = errors + 1;
        end

        if (dut.balance !== 8'd0) begin
            $display("FAIL: %s | Balance=%0d Expected=0",
                     message, dut.balance);
            errors = errors + 1;
        end

        if ((dispense === 1'b1) &&
            (dispense_product === expected_product) &&
            (change_amount === expected_change) &&
            (transaction_complete === 1'b1) &&
            (dut.balance === 8'd0)) begin

            $display("PASS: %s | PRODUCT=%b CHANGE=%0d",
                     message, dispense_product, change_amount);
        end
    end
    endtask

    initial begin

        errors = 0;

        reset = 1'b0;
        product_select = 2'b00;

        coin_5 = 1'b0;
        coin_10 = 1'b0;
        coin_20 = 1'b0;

        cancel = 1'b0;

        $display("\nTEST 1: RESET");

        reset_dut;

        check_balance(8'd0, "Reset");

        $display("\nTEST 2: PRODUCT A EXACT PAYMENT");

        select_product(2'b01);

        insert_5;
        check_balance(8'd5, "A after 5");

        insert_5;
        check_balance(8'd10, "A after 10");

        tick;

        check_purchase(2'b01, 8'd0, "Product A exact payment");

        tick;

        $display("\nTEST 3: PRODUCT B EXACT PAYMENT");

        select_product(2'b10);

        insert_10;
        check_balance(8'd10, "B after 10");

        insert_5;
        check_balance(8'd15, "B after 15");

        tick;

        check_purchase(2'b10, 8'd0, "Product B exact payment");

        tick;

        $display("\nTEST 4: PRODUCT C EXACT PAYMENT");

        select_product(2'b11);

        insert_20;
        check_balance(8'd20, "C after 20");

        tick;

        check_purchase(2'b11, 8'd0, "Product C exact payment");

        tick;

        $display("\nTEST 5: EXCESS PAYMENT");

        select_product(2'b10);

        insert_20;
        check_balance(8'd20, "B after 20");

        tick;

        check_purchase(2'b10, 8'd5, "B with excess payment");

        tick;

        $display("\nTEST 6: INSUFFICIENT MONEY");

        select_product(2'b11);

        insert_5;

        check_balance(8'd5, "C insufficient balance");

        if (insufficient_money !== 1'b1) begin
            $display("FAIL: insufficient_money not asserted");
            errors = errors + 1;
        end
        else begin
            $display("PASS: insufficient_money asserted");
        end

        if (dispense !== 1'b0) begin
            $display("FAIL: dispense asserted with insufficient money");
            errors = errors + 1;
        end

        $display("\nTEST 7: REFUND");

        cancel_transaction;

        if (refund_amount !== 8'd5) begin
            $display("FAIL: Refund=%0d Expected=5", refund_amount);
            errors = errors + 1;
        end
        else begin
            $display("PASS: Refund=%0d", refund_amount);
        end

        if (transaction_complete !== 1'b1) begin
            $display("FAIL: transaction_complete not asserted for refund");
            errors = errors + 1;
        end
        else begin
            $display("PASS: transaction_complete asserted for refund");
        end

        check_balance(8'd0, "After refund");

        tick;

        $display("\nTEST 8: INVALID PRODUCT");

        select_product(2'b00);

        if (invalid_selection !== 1'b1) begin
            $display("FAIL: invalid_selection not asserted");
            errors = errors + 1;
        end
        else begin
            $display("PASS: invalid_selection asserted");
        end

        insert_10;

        check_balance(8'd0, "Coin rejected with invalid product");

        $display("\nTEST 9: SIMULTANEOUS COINS");

        select_product(2'b01);

        @(negedge clk);

        coin_5 = 1'b1;
        coin_10 = 1'b1;

        #1;

        if (invalid_coin !== 1'b1) begin
            $display("FAIL: invalid_coin not detected");
            errors = errors + 1;
        end
        else begin
            $display("PASS: simultaneous coins detected");
        end

        @(posedge clk);
        #1;

        coin_5 = 1'b0;
        coin_10 = 1'b0;

        #1;

        check_balance(8'd0, "Simultaneous coins rejected");

        $display("\nTEST 10: MULTIPLE TRANSACTIONS");

        select_product(2'b01);

        insert_10;

        tick;

        check_purchase(2'b01, 8'd0, "Transaction 1");

        tick;

        select_product(2'b11);

        insert_20;

        tick;

        check_purchase(2'b11, 8'd0, "Transaction 2");

        tick;

        $display("\nTEST 11: RESET DURING TRANSACTION");

        select_product(2'b10);

        insert_10;

        check_balance(8'd10, "Before reset");

        reset_dut;

        check_balance(8'd0, "After reset");

        if (dispense !== 1'b0) begin
            $display("FAIL: dispense active after reset");
            errors = errors + 1;
        end

        if (transaction_complete !== 1'b0) begin
            $display("FAIL: transaction_complete active after reset");
            errors = errors + 1;
        end

        $display("\nTEST 12: ZERO-BALANCE CANCELLATION");

        select_product(2'b01);

        cancel_transaction;

        if (refund_amount !== 8'd0) begin
            $display("FAIL: Zero-balance refund=%0d",
                     refund_amount);
            errors = errors + 1;
        end
        else begin
            $display("PASS: Zero-balance refund=0");
        end

        if (transaction_complete !== 1'b1) begin
            $display("FAIL: zero-balance cancel did not complete");
            errors = errors + 1;
        end
        else begin
            $display("PASS: zero-balance cancel completed");
        end

        check_balance(8'd0, "Zero-balance cancel");

        tick;

        $display("\nTEST 13: NEW TRANSACTION AFTER COMPLETION");

        select_product(2'b01);

        insert_10;

        tick;

        check_purchase(2'b01, 8'd0, "First transaction");

        tick;

        insert_5;

        check_balance(8'd5, "New transaction");

        if (insufficient_money !== 1'b1) begin
            $display("FAIL: insufficient_money not detected");
            errors = errors + 1;
        end
        else begin
            $display("PASS: New transaction detected insufficient balance");
        end

        $display("\n========================================");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTBENCH FAILED WITH %0d ERRORS", errors);

        $display("========================================\n");

        $finish;

    end

endmodule