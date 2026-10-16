# SFIFO-DESIGN-VERIFICATION



## Overview

This project implements and verifies a synchronous FIFO using
Verilog/SystemVerilog.

## Features

- Read and write operations
- Full flag generation
- Empty flag generation
- FIFO occupancy tracking
- Synchronous operation

## Design

The FIFO uses memory storage along with read and write pointers
to manage data transfer.

## Verification

A SystemVerilog testbench was developed using:

- Transaction
- Generator
- Driver
- Monitor
- Scoreboard
- Constrained-random verification

## Files

- `rtl/` - RTL design
- `tb/` - SystemVerilog testbench

## Tools

- Verilog
- SystemVerilog
- Vivado
