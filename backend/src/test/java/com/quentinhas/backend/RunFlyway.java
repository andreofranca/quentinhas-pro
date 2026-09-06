package com.quentinhas.backend;

import org.flywaydb.core.Flyway;

public class RunFlyway {
    public static void main(String[] args) {
        Flyway flyway = Flyway.configure()
            .dataSource("jdbc:postgresql://localhost:5440/quentinhas", "quentinhas_app", "app_password")
            .locations("classpath:db/migration")
            .baselineOnMigrate(true)
            .load();
        flyway.migrate();
        System.out.println("FLYWAY COMPLETED SUCCESSFULLY");
    }
}
