`timescale 1ns/1ps

module vending_machine (
    input wire clk,
    input wire reset,
    input wire [1:0] product_select,
    input wire coin_5,
    input wire coin_10,
    input wire coin_20,
    input wire cancel,

    output reg [1:0] dispense_product,
    output reg dispense,
    output reg [7:0] change_amount,
    output reg [7:0] refund_amount,
    output wire insufficient_money,
    output reg transaction_complete,
    output wire invalid_selection,
    output wire invalid_coin,
    output wire coin_overflow
);

    localparam [7:0] PRICE_A = 8'd10;
    localparam [7:0] PRICE_B = 8'd15;
    localparam [7:0] PRICE_C = 8'd20;
    localparam [7:0] MAX_BALANCE = 8'd255;

    reg [7:0] balance;
    reg [7:0] product_price;
    reg product_valid;

    reg [1:0] coin_count;
    reg [7:0] coin_value;
    reg coin_valid;

    reg purchase_ready;
    reg coin_accept;
    reg overflow_detected;

    always @(*) begin
        product_price = 8'd0;
        product_valid = 1'b0;

        case (product_select)
            2'b01: begin
                product_price = PRICE_A;
                product_valid = 1'b1;
            end
            2'b10: begin
                product_price = PRICE_B;
                product_valid = 1'b1;
            end
            2'b11: begin
                product_price = PRICE_C;
                product_valid = 1'b1;
            end
            default: begin
                product_price = 8'd0;
                product_valid = 1'b0;
            end
        endcase
    end

    assign invalid_selection = ~product_valid;

    always @(*) begin
        coin_count = {1'b0, coin_5} +
                     {1'b0, coin_10} +
                     {1'b0, coin_20};

        coin_value = 8'd0;

        if (coin_5)
            coin_value = 8'd5;
        else if (coin_10)
            coin_value = 8'd10;
        else if (coin_20)
            coin_value = 8'd20;

        coin_valid = (coin_count == 2'd1);
    end

    assign invalid_coin = (coin_count > 2'd1);

    always @(*) begin
        if (product_valid && (balance >= product_price))
            purchase_ready = 1'b1;
        else
            purchase_ready = 1'b0;
    end

    assign insufficient_money =
        product_valid &&
        (balance != 8'd0) &&
        (balance < product_price);

    always @(*) begin
        overflow_detected = 1'b0;

        if (product_valid &&
            coin_valid &&
            !purchase_ready &&
            !cancel) begin

            if (({1'b0, balance} + {1'b0, coin_value}) >
                {1'b0, MAX_BALANCE})
                overflow_detected = 1'b1;
        end
    end

    assign coin_overflow = overflow_detected;

    always @(*) begin
        coin_accept = 1'b0;

        if (product_valid &&
            coin_valid &&
            !purchase_ready &&
            !cancel &&
            !overflow_detected)
            coin_accept = 1'b1;
    end

    always @(posedge clk) begin
        if (reset) begin
            balance <= 8'd0;
            dispense_product <= 2'b00;
            dispense <= 1'b0;
            change_amount <= 8'd0;
            refund_amount <= 8'd0;
            transaction_complete <= 1'b0;
        end
        else begin
            dispense_product <= 2'b00;
            dispense <= 1'b0;
            change_amount <= 8'd0;
            refund_amount <= 8'd0;
            transaction_complete <= 1'b0;

            if (cancel) begin
                refund_amount <= balance;
                balance <= 8'd0;
                transaction_complete <= 1'b1;
            end
            else if (purchase_ready) begin
                dispense_product <= product_select;
                dispense <= 1'b1;
                change_amount <= balance - product_price;
                balance <= 8'd0;
                transaction_complete <= 1'b1;
            end
            else if (coin_accept) begin
                balance <= balance + coin_value;
            end
        end
    end

endmodule