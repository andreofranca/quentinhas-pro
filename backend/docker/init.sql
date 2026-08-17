CREATE DATABASE quentinhas_test;
CREATE USER test WITH ENCRYPTED PASSWORD 'testpassword';
GRANT ALL PRIVILEGES ON DATABASE quentinhas_test TO test;
\c quentinhas_test
GRANT ALL ON SCHEMA public TO test;
