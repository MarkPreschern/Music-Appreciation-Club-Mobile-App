-- -----------------------------------------------------
-- Schema MacDB
-- Represents the music appreciate club database schema
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `MacDB` DEFAULT CHARACTER SET utf8 ;
USE `MacDB` ;

-- -----------------------------------------------------
-- Table `MacDB`.`role`
-- Represents roles that users in the club can have
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MacDB`.`role` (
  `role_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) NULL,
  PRIMARY KEY (`role_id`),
  UNIQUE INDEX `role_id_UNIQUE` (`role_id` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MacDB`.`access`
-- Represents access rights that a user can have
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MacDB`.`access` (
  `access_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) NULL,
  PRIMARY KEY (`access_id`),
  UNIQUE INDEX `role_id_UNIQUE` (`access_id` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MacDB`.`user`
-- Represents a user in the club
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MacDB`.`user` (
  `user_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `nuid` VARCHAR(10) NOT NULL,
  `authorization` VARCHAR(64),
  `role_id` INT NOT NULL,
  `access_id` INT NOT NULL,
  PRIMARY KEY (`user_id`, `role_id`, `access_id`),
  UNIQUE INDEX `user_id_UNIQUE` (`user_id` ASC),
  INDEX `fk_user_role1_idx` (`role_id` ASC),
  INDEX `fk_user_access1_idx` (`access_id` ASC),
  CONSTRAINT `fk_user_role1`
    FOREIGN KEY (`role_id`)
    REFERENCES `MacDB`.`role` (`role_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_access1`
    FOREIGN KEY (`access_id`)
    REFERENCES `MacDB`.`access` (`access_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `MacDB`.`item`
-- Represents either a song or album and information about it
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MacDB`.`item` (
  `item_id` INT NOT NULL AUTO_INCREMENT,
  `is_album` TINYINT NOT NULL,
  `item_name` VARCHAR(255) NOT NULL,
  `item_artist` VARCHAR(100) NOT NULL,
  `item_spotify_id` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`item_id`),
  UNIQUE INDEX `item_id_UNIQUE` (`item_id` ASC),
  UNIQUE INDEX `item_spotify_id_UNIQUE` (`item_spotify_id` ASC))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `MacDB`.`event`
-- Represents an event timeframe for favorites to be saved in recent favorites
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MacDB`.`event` (
  `event_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL,
  `description` VARCHAR(100) NOT NULL,
  `start_date` DATETIME NOT NULL,
  `end_date` DATETIME NOT NULL,
  PRIMARY KEY (`event_id`),
  UNIQUE INDEX `favorite_recent_id_UNIQUE` (`event_id` ASC))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `MacDB`.`pick`
-- Represents an item that a user picked in the recent event timeframe
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MacDB`.`pick` (
  `pick_id` INT NOT NULL AUTO_INCREMENT,
  `date_picked` DATETIME NOT NULL,
  `user_id` INT NOT NULL,
  `item_id` INT NOT NULL,
  `event_id` INT NOT NULL,
  PRIMARY KEY (`pick_id`, `user_id`, `item_id`, `event_id`),
  UNIQUE INDEX `pick_id_UNIQUE` (`pick_id` ASC),
  INDEX `fk_pick_user1_idx` (`user_id` ASC),
  INDEX `fk_pick_item1_idx` (`item_id` ASC),
  INDEX `fk_pick_event1_idx` (`event_id` ASC),
  CONSTRAINT `fk_pick_user1`
    FOREIGN KEY (`user_id`)
    REFERENCES `MacDB`.`user` (`user_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_pick_item1`
    FOREIGN KEY (`item_id`)
    REFERENCES `MacDB`.`item` (`item_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_pick_event1`
    FOREIGN KEY (`event_id`)
    REFERENCES `MacDB`.`event` (`event_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `MacDB`.`vote`
-- Represents a user's vote for another user's weekly favorite
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MacDB`.`vote` (
  `vote_id` INT NOT NULL AUTO_INCREMENT,
  `up` TINYINT NOT NULL,
  `comment` VARCHAR(255) NULL,
  `user_id` INT NOT NULL,
  `pick_id` INT NOT NULL,
  PRIMARY KEY (`vote_id`, `user_id`, `pick_id`),
  INDEX `fk_vote_user1_idx` (`user_id` ASC),
  UNIQUE INDEX `vote_id_UNIQUE` (`vote_id` ASC),
  INDEX `fk_vote_pick1_idx` (`pick_id` ASC),
  CONSTRAINT `fk_vote_user1`
    FOREIGN KEY (`user_id`)
    REFERENCES `MacDB`.`user` (`user_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_vote_pick1`
    FOREIGN KEY (`pick_id`)
    REFERENCES `MacDB`.`pick` (`pick_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;