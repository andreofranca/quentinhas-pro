package com.quentinhas.backend.exception;

public class StockEsgotadoException extends RuntimeException {
    public StockEsgotadoException(String message) {
        super(message);
    }
}
