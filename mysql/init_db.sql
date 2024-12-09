CREATE DATABASE visayakpo;
CREATE DATABASE exceture;
-- CREATE USER 'visaya'@'%' IDENTIFIED WITH mysql_native_password BY 'LetmeIn';

GRANT ALL PRIVILEGES ON exceture.* TO 'wordpress'@'%';
GRANT ALL PRIVILEGES ON visayakpo.* TO 'wordpress'@'%';

FLUSH PRIVILEGES;
