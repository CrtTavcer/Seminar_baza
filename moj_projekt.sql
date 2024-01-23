-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Gostitelj: 127.0.0.1
-- Čas nastanka: 23. jan 2024 ob 14.31
-- Različica strežnika: 10.4.28-MariaDB
-- Različica PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Zbirka podatkov: `moj_projekt`
--

-- --------------------------------------------------------

--
-- Struktura tabele `bilanca`
--

CREATE TABLE `bilanca` (
  `ID_bilanca` int(11) NOT NULL,
  `ID_uporabnika` int(11) NOT NULL,
  `vsota_prihodki` decimal(11,2) NOT NULL,
  `vsota_odhodki` decimal(11,2) NOT NULL,
  `datum` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Odloži podatke za tabelo `bilanca`
--

INSERT INTO `bilanca` (`ID_bilanca`, `ID_uporabnika`, `vsota_prihodki`, `vsota_odhodki`, `datum`) VALUES
(16, 18, 966.70, 962.54, '2024-01-01'),
(17, 23, 1200.00, 1030.00, '2024-01-01'),
(18, 24, 0.00, 15.00, '2024-01-01');

--
-- Sprožilci `bilanca`
--
DELIMITER $$
CREATE TRIGGER `bilanca_delete` BEFORE DELETE ON `bilanca` FOR EACH ROW BEGIN
    DECLARE bilanca_count INT;
    
    SELECT COUNT(*)
    INTO bilanca_count
    FROM ledger
    WHERE ID_uporabnika = OLD.ID_uporabnika;
    
    IF bilanca_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete from uporabniki table because related records exist in the ledger table';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabele `ledger`
--

CREATE TABLE `ledger` (
  `ID_ledger` int(11) NOT NULL,
  `ID_vrsta` int(11) NOT NULL,
  `ID_namen` int(11) NOT NULL,
  `ID_uporabnika` int(11) NOT NULL,
  `vsota` decimal(10,2) NOT NULL,
  `datum` date NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Odloži podatke za tabelo `ledger`
--

INSERT INTO `ledger` (`ID_ledger`, `ID_vrsta`, `ID_namen`, `ID_uporabnika`, `vsota`, `datum`) VALUES
(55, 1, 10, 18, 100.00, '2024-01-15'),
(56, 2, 2, 18, 90.00, '2024-01-15'),
(57, 1, 2, 18, 100.00, '2024-01-15'),
(58, 1, 2, 18, 100.00, '2024-01-16'),
(61, 1, 2, 18, 100.00, '2024-01-16'),
(62, 1, 2, 18, 190.00, '2024-01-17'),
(64, 1, 1, 18, 1.00, '2024-01-17'),
(65, 1, 1, 18, 1.00, '2024-01-17'),
(67, 1, 1, 18, 1.00, '2024-01-17'),
(69, 2, 1, 18, 765.00, '2024-01-18'),
(70, 2, 4, 18, 56.70, '2024-01-18'),
(75, 2, 1, 18, 55.00, '2024-01-18'),
(76, 1, 1, 18, 45.00, '2024-01-18'),
(78, 1, 1, 18, 66.00, '2024-01-18'),
(80, 1, 1, 18, 12.00, '2024-01-18'),
(83, 1, 1, 23, 555.00, '2024-01-19'),
(84, 1, 1, 23, 45.00, '2024-01-19'),
(86, 2, 2, 23, 800.00, '2024-01-19'),
(87, 1, 1, 18, 246.54, '2024-01-19'),
(88, 1, 1, 24, 15.00, '2024-01-19'),
(89, 1, 1, 23, 300.00, '2024-01-20'),
(90, 2, 2, 23, 400.00, '2024-01-20'),
(91, 1, 1, 23, 100.00, '2024-01-20'),
(92, 1, 1, 23, 10.00, '2024-01-20'),
(93, 1, 1, 23, 10.00, '2024-01-20'),
(94, 1, 1, 23, 10.00, '2024-01-20');

--
-- Sprožilci `ledger`
--
DELIMITER $$
CREATE TRIGGER `izbris_vnosa` AFTER DELETE ON `ledger` FOR EACH ROW BEGIN
    DECLARE datum DATE;
    DECLARE user_balance DECIMAL(10, 2);
    
    SET datum = DATE_FORMAT(NOW(), '%Y-%m-01');
    
    SELECT vsota_odhodki INTO user_balance
    FROM bilanca
    WHERE ID_uporabnika = OLD.ID_uporabnika
    AND datum = datum;
    
    IF OLD.ID_vrsta = 1 THEN
            UPDATE bilanca
            SET vsota_odhodki = vsota_odhodki - OLD.vsota
            WHERE ID_uporabnika = OLD.ID_uporabnika
            AND datum = datum;
    END IF;
    IF OLD.ID_vrsta = 2 THEN
            UPDATE bilanca
            SET vsota_prihodki = vsota_prihodki - OLD.vsota
            WHERE ID_uporabnika = OLD.ID_uporabnika
            AND datum = datum;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `odhodki` AFTER INSERT ON `ledger` FOR EACH ROW BEGIN
    DECLARE datum DATE;
    DECLARE user_balance DECIMAL(10, 2);
    
    SET datum = DATE_FORMAT(NOW(), '%Y-%m-01');
    
    IF NEW.ID_vrsta = 1 THEN
        SELECT vsota_odhodki INTO user_balance
        FROM bilanca
        WHERE ID_uporabnika = NEW.ID_uporabnika
        AND datum = datum;
        
        IF user_balance IS NOT NULL THEN
            -- Update the existing balance for the current month
            UPDATE bilanca
            SET vsota_odhodki = vsota_odhodki + NEW.vsota
            WHERE ID_uporabnika = NEW.ID_uporabnika
            AND datum = datum;
        ELSE
            -- Insert a new balance for the next month
            INSERT INTO bilanca (ID_uporabnika, datum, vsota_odhodki)
            VALUES (NEW.ID_uporabnika, datum, NEW.vsota);
        END IF;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `prihodki` AFTER INSERT ON `ledger` FOR EACH ROW BEGIN
    DECLARE datum DATE;
    DECLARE user_balance DECIMAL(10, 2);
    
    #SET datum = DATE_FORMAT(NOW(), '%Y-%m-01');
    SET datum = DATE_FORMAT(NEW.datum, '%Y-%m-01');
    
    IF NEW.ID_vrsta = 2 THEN
        SELECT vsota_prihodki INTO user_balance
        FROM bilanca
        WHERE ID_uporabnika = NEW.ID_uporabnika
        AND datum = datum;
        
        IF user_balance IS NOT NULL THEN
            -- Update the existing balance for the current month
            UPDATE bilanca
            SET vsota_prihodki = vsota_prihodki + NEW.vsota
            WHERE ID_uporabnika = NEW.ID_uporabnika
            AND datum = datum;
        ELSE
            -- Insert a new balance for the next month
            INSERT INTO bilanca (ID_uporabnika, datum, vsota_prihodki)
            VALUES (NEW.ID_uporabnika, datum, NEW.vsota);
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabele `namen`
--

CREATE TABLE `namen` (
  `ID_namen` int(11) NOT NULL,
  `ID_vrsta` int(11) NOT NULL,
  `kategorija` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Odloži podatke za tabelo `namen`
--

INSERT INTO `namen` (`ID_namen`, `ID_vrsta`, `kategorija`) VALUES
(1, 1, 'avto'),
(2, 2, 'placa'),
(4, 1, 'Hrana'),
(5, 1, 'Pijača'),
(6, 1, 'Telovadba'),
(7, 1, 'Zabava'),
(10, 1, 'Elektrika'),
(11, 1, 'Voda'),
(12, 2, 'žepnina'),
(13, 2, 'Regres'),
(14, 2, 'Najemnina'),
(15, 1, 'Najemnina'),
(16, 2, 'Obresti'),
(17, 2, 'Bolha');

-- --------------------------------------------------------

--
-- Struktura tabele `uporabniki`
--

CREATE TABLE `uporabniki` (
  `ID` int(11) NOT NULL,
  `ime` varchar(20) NOT NULL,
  `priimek` varchar(20) NOT NULL,
  `vzdevek` varchar(20) NOT NULL,
  `geslo` varchar(255) NOT NULL,
  `email` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Odloži podatke za tabelo `uporabniki`
--

INSERT INTO `uporabniki` (`ID`, `ime`, `priimek`, `vzdevek`, `geslo`, `email`) VALUES
(18, 'Marjan', 'Klobasa', 'mare', '$2y$10$Y3VKcTP5vAKy7fz1Z9CuNOx.opAaLRYvms11HvnHl4K9FcqX9jl62', 'mare@mare.com'),
(19, 'Maks', 'Rog', 'maks', '$2y$10$kJxA6RfE/tQa32FZWpkTHuek1shyr0M4d9wxOosF3PIniRL7ZDET6', 'maks@email.com'),
(20, 'Jure', 'Goba', 'jure', '$2y$10$lmNTzHy/yss9RvPkPfI8J.bLEnGRcPhCke3OBHWCJY3exqKKcJqeG', 'JG@g.com'),
(21, 'Jure', 'Goba', 'jure1', '$2y$10$nuCS9s.ej8YpyUXNbFIzJu5Z6cmK5G5StFh2l7QZVZbiRM3Rf3SrS', 'JG@g.com'),
(22, 'Maja', 'Snoj', 'maja', '$2y$10$jk3/IgrZGZ5aK7mOwtfR.OK92Lg88UXTC5arlHrPJiLL68Cqccduq', 'ms@g.com'),
(23, 'NinaNana', 'Snoj', 'nina', '$2y$10$rkew58qykRPb3ZTeMWLsqeZnm5mir1VehgyXlIjkmpV8M7wPC7Juq', 'nina@nana.com'),
(24, 'm', 'm', 'mihec', '$2y$10$LidnQl3HLOzVP1zPmFkBEux4XD4JAStY848Vh8rqtPZO5eRRdYvVm', 'MM@m.com');

-- --------------------------------------------------------

--
-- Struktura tabele `vrsta`
--

CREATE TABLE `vrsta` (
  `ID_vrsta` int(11) NOT NULL,
  `vrsta` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Odloži podatke za tabelo `vrsta`
--

INSERT INTO `vrsta` (`ID_vrsta`, `vrsta`) VALUES
(1, 'odhodek (-)'),
(2, 'prihodek (+)');

--
-- Indeksi zavrženih tabel
--

--
-- Indeksi tabele `bilanca`
--
ALTER TABLE `bilanca`
  ADD PRIMARY KEY (`ID_bilanca`),
  ADD KEY `ID_uporabnika` (`ID_uporabnika`);

--
-- Indeksi tabele `ledger`
--
ALTER TABLE `ledger`
  ADD PRIMARY KEY (`ID_ledger`),
  ADD KEY `ID_vrsta` (`ID_vrsta`,`ID_namen`,`ID_uporabnika`),
  ADD KEY `user` (`ID_uporabnika`),
  ADD KEY `fk_ledger_namen` (`ID_namen`);

--
-- Indeksi tabele `namen`
--
ALTER TABLE `namen`
  ADD PRIMARY KEY (`ID_namen`),
  ADD KEY `ID_vrsta` (`ID_vrsta`);

--
-- Indeksi tabele `uporabniki`
--
ALTER TABLE `uporabniki`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `vzdevek` (`vzdevek`);

--
-- Indeksi tabele `vrsta`
--
ALTER TABLE `vrsta`
  ADD PRIMARY KEY (`ID_vrsta`);

--
-- AUTO_INCREMENT zavrženih tabel
--

--
-- AUTO_INCREMENT tabele `bilanca`
--
ALTER TABLE `bilanca`
  MODIFY `ID_bilanca` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT tabele `ledger`
--
ALTER TABLE `ledger`
  MODIFY `ID_ledger` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=95;

--
-- AUTO_INCREMENT tabele `namen`
--
ALTER TABLE `namen`
  MODIFY `ID_namen` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT tabele `uporabniki`
--
ALTER TABLE `uporabniki`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT tabele `vrsta`
--
ALTER TABLE `vrsta`
  MODIFY `ID_vrsta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Omejitve tabel za povzetek stanja
--

--
-- Omejitve za tabelo `bilanca`
--
ALTER TABLE `bilanca`
  ADD CONSTRAINT `uporabnik` FOREIGN KEY (`ID_uporabnika`) REFERENCES `uporabniki` (`ID`);

--
-- Omejitve za tabelo `ledger`
--
ALTER TABLE `ledger`
  ADD CONSTRAINT `fk_ledger_namen` FOREIGN KEY (`ID_namen`) REFERENCES `namen` (`ID_namen`),
  ADD CONSTRAINT `fk_ledger_vrsta` FOREIGN KEY (`ID_vrsta`) REFERENCES `vrsta` (`ID_vrsta`),
  ADD CONSTRAINT `user` FOREIGN KEY (`ID_uporabnika`) REFERENCES `uporabniki` (`ID`);

--
-- Omejitve za tabelo `namen`
--
ALTER TABLE `namen`
  ADD CONSTRAINT `fk_namen_vrsta` FOREIGN KEY (`ID_vrsta`) REFERENCES `vrsta` (`ID_vrsta`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
