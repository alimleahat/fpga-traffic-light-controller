`timescale 1ns/1ps
module regression_tb;
    reg [3:0] a, b;
    reg carry_in;
    wire [3:0] sum, difference, tens, ones;
    wire carry_out;
    wire [6:0] high_segments, low_segments;
    FourBitFullAdder adder(a, b, carry_in, sum, carry_out);
    Subtractor subtractor(a, b, difference);
    BinaryBCD bcd(a, tens, ones);
    SevenSegDisplay display(a, high_segments, low_segments);

    reg clk = 0;
    reg rst_n = 1;
    reg button = 1;
    wire [5:0] control;
    wire pending, extend;
    wire [3:0] remaining;
    wire green, red, amber;
    CoreLogic core(clk, rst_n, button, control, pending, extend);
    Decoder decoder(control, extend, remaining, green, red, amber);
    integer i, j, c, phase_index, tick_index, duration;

    function [6:0] segments(input integer digit);
        case (digit)
            0: segments=7'b1000000;
            1: segments=7'b1111001;
            2: segments=7'b0100100;
            3: segments=7'b0110000;
            4: segments=7'b0011001;
            5: segments=7'b0010010;
            6: segments=7'b0000010;
            7: segments=7'b1111000;
            8: segments=7'b0000000;
            9: segments=7'b0010000;
            default: segments=7'b1111111;
        endcase
    endfunction

    task tick;
        begin #5; clk=1; #5; clk=0; #1; end
    endtask

    task check_phase(input integer expected_phase, input integer elapsed,
                     input integer expected_remaining);
        begin
            if (control !== ((expected_phase << 4) | elapsed))
                $fatal(1, "phase/count mismatch: got %h", control);
            if (remaining !== expected_remaining)
                $fatal(1, "countdown mismatch: got %d", remaining);
            if ({red, amber, green} !==
                (expected_phase == 0 ? 3'b100 : expected_phase == 2 ? 3'b001 : 3'b010))
                $fatal(1, "lamp mismatch");
        end
    endtask

    initial begin
        // Exhaustive arithmetic and valid decimal display conversion.
        for (i=0; i<16; i=i+1) begin
            a=i; #1;
            if (tens !== i/10 || ones !== i%10)
                $fatal(1, "BCD mismatch for %d", i);
            if (high_segments !== segments(i/10) || low_segments !== segments(i%10))
                $fatal(1, "display mismatch for %d", i);
            for (j=0; j<16; j=j+1)
                for (c=0; c<2; c=c+1) begin
                    b=j; carry_in=c; #1;
                    if ({carry_out, sum} !== i+j+c)
                        $fatal(1, "adder mismatch");
                    if (difference !== ((i-j) & 15))
                        $fatal(1, "subtractor mismatch");
                end
        end

        rst_n=0; #1; rst_n=1; #1;
        // Two complete nominal cycles, checking every count and lamp.
        for (i=0; i<2; i=i+1)
            for (phase_index=0; phase_index<4; phase_index=phase_index+1) begin
                duration=(phase_index % 2 == 0) ? 10 : 3;
                for (tick_index=0; tick_index<duration; tick_index=tick_index+1) begin
                    check_phase(phase_index, tick_index, duration-tick_index);
                    if (pending !== 0 || extend !== 0) $fatal(1, "unexpected request");
                    tick;
                end
            end

        // Enter green, latch a request, and carry it through amber to red.
        repeat (13) tick;
        check_phase(2, 0, 10);
        button=0; tick; button=1;
        if (pending !== 1 || extend !== 0) $fatal(1, "request not latched in green");
        repeat (12) tick;
        for (tick_index=0; tick_index<15; tick_index=tick_index+1) begin
            check_phase(0, tick_index, 15-tick_index);
            if (pending !== 1 || extend !== 1) $fatal(1, "red not extended");
            tick;
        end
        check_phase(1, 0, 3);
        if (pending !== 0 || extend !== 0) $fatal(1, "request not cleared");
        $display("PASS: exhaustive arithmetic/display, normal cycles, pedestrian extension");
        $finish;
    end
endmodule
