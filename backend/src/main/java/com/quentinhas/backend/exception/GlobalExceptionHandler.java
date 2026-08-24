package com.quentinhas.backend.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.net.URI;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler({org.springframework.security.core.AuthenticationException.class, io.jsonwebtoken.JwtException.class})
    public ProblemDetail handleAuthenticationException(Exception ex) {
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(HttpStatus.UNAUTHORIZED, "Credenciais inválidas ou token expirado");
        problemDetail.setTitle("Unauthorized");
        problemDetail.setType(URI.create("https://api.quentinhas.com/errors/unauthorized"));
        return problemDetail;
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ProblemDetail handleIllegalArgumentException(IllegalArgumentException ex) {
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, ex.getMessage());
        problemDetail.setTitle("Bad Request");
        problemDetail.setType(URI.create("https://api.quentinhas.com/errors/bad-request"));
        return problemDetail;
    }

    @ExceptionHandler(java.util.NoSuchElementException.class)
    public ProblemDetail handleNoSuchElementException(java.util.NoSuchElementException ex) {
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        problemDetail.setTitle("Not Found");
        problemDetail.setType(URI.create("https://api.quentinhas.com/errors/not-found"));
        return problemDetail;
    }

    @ExceptionHandler(com.quentinhas.backend.exception.BusinessRuleException.class)
    public ProblemDetail handleBusinessRuleException(com.quentinhas.backend.exception.BusinessRuleException ex) {
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(HttpStatus.UNPROCESSABLE_ENTITY, ex.getMessage());
        problemDetail.setTitle("Unprocessable Entity");
        problemDetail.setType(URI.create("https://api.quentinhas.com/errors/unprocessable-entity"));
        return problemDetail;
    }

    @ExceptionHandler({com.quentinhas.backend.exception.IdempotencyException.class, com.quentinhas.backend.exception.StockEsgotadoException.class})
    public ProblemDetail handleConflictException(RuntimeException ex) {
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, ex.getMessage());
        problemDetail.setTitle("Conflict");
        problemDetail.setType(URI.create("https://api.quentinhas.com/errors/conflict"));
        return problemDetail;
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleAllUncaughtException(Exception ex) {
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR, ex.getMessage());
        problemDetail.setTitle("Internal Server Error");
        problemDetail.setType(URI.create("https://api.quentinhas.com/errors/internal-server-error"));
        return problemDetail;
    }
}
