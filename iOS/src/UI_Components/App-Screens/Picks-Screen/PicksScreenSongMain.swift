//
//  PicksScreenMain.swift
//  Music-Appreciation-Mobile-App-iOs
//
//  Created by Mark Preschern on 3/14/19.
//  Copyright © 2019 Mark Preschern. All rights reserved.
//

import UIKit
import Alamofire

// represents a pick as it's pick id, the item picked, the votes for this item, and the user that picked this item
struct Pick {
    let pickID: Int!
    let itemData: ItemData!
    var voteData: VoteData!
    let userData: UserData!
}

// represents a vote for a pick
struct VoteData {
    var totalVotes: Int! // upVotes - downvotes
    let upVoteData: JSONStandard!
    let downVoteData: JSONStandard!
    var userVoteID: Int? // the voteID of a user's vote
}

// Represents the picks screen. Holds information regarding:
// - continously updated song top picks across the entire club
// - ability to vote on songs and albums
class PicksScreenSongMain: UIViewController, UITableViewDelegate {
    
    // user picked songs and their votes
    var userSongPicks = [Pick]()
    // club picked songs and their votes
    var clubSongPicks = [Pick]()
    
    // cell's containing club songs
    var clubSongCells = [Int: SongCell]()
    
    // if vote data has already been parsed at this index
    var voteDataParsed = [Bool]()

    @IBOutlet weak var view_outlet: UIView!
    @IBOutlet weak var songLabel_outlet: UIButton!
    @IBOutlet weak var albumLabel_outlet: UIButton!
    @IBOutlet weak var myPicksView_outlet: UIView!
    @IBOutlet weak var clubPicksView_outlet: UIView!
    
    @IBOutlet weak var myPicksTable_outlet: UITableView!
    @IBOutlet weak var clubPicksTable_outlet: UITableView!
    
    // initialization on view loading
    override func viewDidLoad() {
        super.viewDidLoad()

        //sets task bar border
        self.view_outlet.layer.addBorder(edge: UIRectEdge.top, color: UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1), thickness: 1)
        
        //sets myPicks and clubPicks borders
        self.myPicksView_outlet.layer.borderWidth = 1
        self.myPicksView_outlet.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        self.clubPicksView_outlet.layer.borderWidth = 1
        self.clubPicksView_outlet.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        
        //sets task song and album borders just on the top and bottom
        self.songLabel_outlet.layer.addBorder(edge: UIRectEdge.top, color: UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1), thickness: 1)
        self.songLabel_outlet.layer.addBorder(edge: UIRectEdge.bottom, color: UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1), thickness: 1)
        self.albumLabel_outlet.layer.addBorder(edge: UIRectEdge.top, color: UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1), thickness: 1)
        self.albumLabel_outlet.layer.addBorder(edge: UIRectEdge.bottom, color: UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1), thickness: 1)
        
        //sets song and album button colors
        self.songLabel_outlet.backgroundColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 0.5)
        self.albumLabel_outlet.backgroundColor = UIColor.white
        
        //sets table outlet's datasource to this class's extension
        self.myPicksTable_outlet.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.myPicksTable_outlet.dataSource = self
        self.myPicksTable_outlet.delegate = self

        self.clubPicksTable_outlet.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.clubPicksTable_outlet.dataSource = self
        self.clubPicksTable_outlet.delegate = self

        self.requestUserAndClubSongData()
    }
    
    // requests user and club song data from mac api
    func requestUserAndClubSongData() {
        self.requestUserData()
        self.requestClubData()
    }
    
    // requests user song data from the mac api
    func requestUserData() {
        self.myPicksTable_outlet.reloadData()
        self.macRequest(urlName: "userSongPicks", httpMethod: .get, header: [:], successAlert: false, attempt: 0, callback: { jsonData -> Void in
            self.parsePickData(jsonData: jsonData, table: self.myPicksTable_outlet, callback: { (picks : [Pick]?) -> Void in
                if (jsonData?["statusCode"] as? String == "200") {
                    if (picks == nil || picks![0].itemData == nil) {
                        self.userSongPicks = []
                    } else {
                        self.userSongPicks = picks!
                    }
                }
            })
        })
    }
    
    // requests club song data from the mac api
    func requestClubData() {
        self.clubPicksTable_outlet.reloadData()
        self.macRequest(urlName: "clubSongPicks", httpMethod: .get, header: [:], successAlert: false, attempt: 0, callback: { jsonData -> Void in
            self.parsePickData(jsonData: jsonData, table: self.clubPicksTable_outlet, callback: { (picks : [Pick]?) -> Void in
                if (jsonData?["statusCode"] as? String == "200") {
                    if (picks == nil || picks![0].itemData == nil) {
                        self.clubSongPicks = []
                    } else {
                        self.clubSongPicks = picks!
                    }
                }
            })
        })
    }
    
    // when table view cell is tapped, move to controller of cell type
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView.restorationIdentifier == "MySongPicksTable") {
            let nextVC = self.storyboard!.instantiateViewController(withIdentifier: "songViewID") as? SongView
            nextVC!.songData = userSongPicks[indexPath.row].itemData
            nextVC!.previousRestorationIdentifier = "picksScreenSongID"
            self.present(nextVC!, animated:true, completion: nil)
        } else if (tableView.restorationIdentifier == "ClubSongPicksTable") {
            let nextVC = self.storyboard!.instantiateViewController(withIdentifier: "songViewID") as? SongView
            nextVC!.songData = clubSongPicks[indexPath.row].itemData
            nextVC!.previousRestorationIdentifier = "picksScreenSongID"
            self.present(nextVC!, animated:true, completion: nil)
        }
    }
    
    // handles an up vote click
    @objc func upVote(gesture: VoteTapGesture) {
        if (gesture.view as? UIImageView) != nil {
            let cell = clubSongCells[gesture.index]
            let imageDataUp = cell?.upVote_outlet.image?.pngData()
            let imageDataDown = cell?.downVote_outlet.image?.pngData()
            
            // up arrow green and down arrow red should never occur, throw error
            if UIImage(named: "ArrowGreen")?.pngData() == imageDataUp && UIImage(named: "ArrowRed")?.pngData() == imageDataDown {
                self.displayVoteFailure(message: "Voting for and against a song should never happen", action: "Close")
            // delete up vote due to up arrow green
            } else if UIImage(named: "ArrowGreen")?.pngData() == imageDataUp && UIImage(named: "ArrowGreyDown")?.pngData() == imageDataDown {
                self.deleteVote(gesture: gesture, callback: { (response) -> Void in
                    if (response == "Success") {
                        self.clubSongPicks[gesture.index].voteData.totalVotes -= 1
                        self.updateVoteLable(index: gesture.index, cell: nil)
                        cell?.upVote_outlet.image = UIImage(named: "ArrowGreyUp")
                    }
                })
            // delete down vote due to down arrow red and post up vote
            } else if UIImage(named: "ArrowGreyUp")?.pngData() == imageDataUp && UIImage(named: "ArrowRed")?.pngData() == imageDataDown {
                self.deleteVote(gesture: gesture, callback: { (response) -> Void in
                    if (response == "Success") {
                        self.clubSongPicks[gesture.index].voteData.totalVotes += 1
                        self.updateVoteLable(index: gesture.index, cell: nil)
                        cell?.downVote_outlet.image = UIImage(named: "ArrowGreyDown")
                        self.postVote(gesture: gesture, up: 1, comment: "", callback: {(response) -> Void in
                            if (response == "Success") {
                                self.clubSongPicks[gesture.index].voteData.totalVotes += 1
                                self.updateVoteLable(index: gesture.index, cell: nil)
                                cell?.upVote_outlet.image = UIImage(named: "ArrowGreen")
                            }
                        })
                    }
                })
            // post up vote
            } else if UIImage(named: "ArrowGreyUp")?.pngData() == imageDataUp && UIImage(named: "ArrowGreyDown")?.pngData() == imageDataDown {
                self.postVote(gesture: gesture, up: 1, comment: "", callback: {(response) -> Void in
                    if (response == "Success") {
                        self.clubSongPicks[gesture.index].voteData.totalVotes += 1
                        self.updateVoteLable(index: gesture.index, cell: nil)
                        cell?.upVote_outlet.image = UIImage(named: "ArrowGreen")
                    }
                })
            // invalid button click
            } else {
                self.displayVoteFailure(message: "Invalid Button Click", action: "Try Again")
            }
        }
    }
    
    // handles a down vote click
    @objc func downVote(gesture: VoteTapGesture) {
        if (gesture.view as? UIImageView) != nil {
            let cell = clubSongCells[gesture.index]
            let imageDataUp = cell?.upVote_outlet.image?.pngData()
            let imageDataDown = cell?.downVote_outlet.image?.pngData()
            
            // up arrow green and down arrow red should never occur, throw error
            if UIImage(named: "ArrowGreen")?.pngData() == imageDataUp && UIImage(named: "ArrowRed")?.pngData() == imageDataDown {
                self.displayVoteFailure(message: "Voting for and against a song should never happen", action: "Close")
            // delete up vote due to up arrow green and post down vote
            } else if UIImage(named: "ArrowGreen")?.pngData() == imageDataUp && UIImage(named: "ArrowGreyDown")?.pngData() == imageDataDown {
                self.deleteVote(gesture: gesture, callback: { (response) -> Void in
                    if (response == "Success") {
                        self.clubSongPicks[gesture.index].voteData.totalVotes -= 1
                        self.updateVoteLable(index: gesture.index, cell: nil)
                        cell?.upVote_outlet.image = UIImage(named: "ArrowGreyUp")
                        self.postVote(gesture: gesture, up: 0, comment: "", callback: {(response) -> Void in
                            if (response == "Success") {
                                self.clubSongPicks[gesture.index].voteData.totalVotes -= 1
                                self.updateVoteLable(index: gesture.index, cell: nil)
                                cell?.downVote_outlet.image = UIImage(named: "ArrowRed")
                            }
                        })
                    }
                })
            // delete down vote due to down arrow red
            } else if UIImage(named: "ArrowGreyUp")?.pngData() == imageDataUp && UIImage(named: "ArrowRed")?.pngData() == imageDataDown {
                self.deleteVote(gesture: gesture, callback: { (response) -> Void in
                    if (response == "Success") {
                        self.clubSongPicks[gesture.index].voteData.totalVotes += 1
                        self.updateVoteLable(index: gesture.index, cell: nil)
                        cell?.downVote_outlet.image = UIImage(named: "ArrowGreyDown")
                    }
                })
            // post down vote
            } else if UIImage(named: "ArrowGreyUp")?.pngData() == imageDataUp && UIImage(named: "ArrowGreyDown")?.pngData() == imageDataDown {
                self.postVote(gesture: gesture, up: 0, comment: "", callback: {(response) -> Void in
                    if (response == "Success") {
                        self.clubSongPicks[gesture.index].voteData.totalVotes -= 1
                        self.updateVoteLable(index: gesture.index, cell: nil)
                        cell?.downVote_outlet.image = UIImage(named: "ArrowRed")
                    }
                })
            // invalid button click
            } else {
                self.displayVoteFailure(message: "Invalid Button Click", action: "Try Again")
            }
        }
    }
    
    // deletes a vote
    func deleteVote(gesture: VoteTapGesture, callback: @escaping (String) -> Void) {
        if self.clubSongPicks[gesture.index].voteData.userVoteID == nil {
            let alert = createAlert(
                title: "Vote Failed",
                message: "Missing vote data.",
                actionTitle: "Try Again")
            self.present(alert, animated: true, completion: nil)
        } else {
            let header: HTTPHeaders = [
                "vote_id": String(clubSongPicks[gesture.index].voteData.userVoteID!)
            ]
            self.macRequest(urlName: "deleteVote", httpMethod: .post, header: header, successAlert: false, attempt: 0, callback: { jsonData -> Void in
                if (jsonData?["statusCode"] as? String == "200") {
                    callback("Success")
                } else {
                    let alert = createAlert(title: jsonData?["title"] as? String, message: jsonData?["description"] as? String, actionTitle: "Try Again")
                    self.present(alert, animated: true, completion: nil)
                }
            })
        }
    }
    
    // posts a vote
    func postVote(gesture: VoteTapGesture, up: Int, comment: String, callback: @escaping (String) -> Void) {
        let header: HTTPHeaders = [
            "pick_id": String(clubSongPicks[gesture.index].pickID),
            "up": String(up),
            "comment": comment
        ]
        self.macRequest(urlName: "vote", httpMethod: .post, header: header, successAlert: false, attempt: 0, callback: { jsonData -> Void in
            if (jsonData?["statusCode"] as? String == "200") {
                self.clubSongPicks[gesture.index].voteData.userVoteID = jsonData?["vote_id"] as? Int
                callback("Success")
            } else {
                let alert = createAlert(title: jsonData?["title"] as? String, message: jsonData?["description"] as? String, actionTitle: "Try Again")
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    // presents vote failure message
    func displayVoteFailure(message: String, action: String) {
        let alert = createAlert(
            title: "Vote Failed",
            message: message,
            actionTitle: action)
        self.present(alert, animated: true, completion: nil)
    }
    
    // updates the vote label at this index based on it's vote count or the specified cell
    func updateVoteLable(index: Int, cell: UITableViewCell?) {
        let voteLabel: UILabel
        let votes: Int
        if (cell == nil) {
            voteLabel = self.clubSongCells[index]?.viewWithTag(4) as! UILabel
            votes = self.clubSongPicks[index].voteData.totalVotes ?? 0
        } else {
            voteLabel = cell?.viewWithTag(4) as! UILabel
            votes = self.userSongPicks[index].voteData.totalVotes ?? 0
        }
        voteLabel.text = String(abs(votes))
        if votes > 0 {
            voteLabel.textColor = UIColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0)
        } else if votes < 0 {
            voteLabel.textColor = UIColor.red
        } else {
            voteLabel.textColor = UIColor.gray
        }
    }
    
    // handles when a user clicks the trash icon, prompting the user to delete the pick
    @objc func trash(gesture: VoteTapGesture) {
        if (gesture.view as? UIImageView) != nil {
            self.showSpinner(onView: self.view)
            UIAlertController(title: "", message: "", preferredStyle: UIAlertController.Style.alert)
                .deleteItemAlert(pick: self.userSongPicks[gesture.index], type: ItemType.SONG, sender: self, callback: { response -> Void in
                    if (response == "Success") {
                        self.userSongPicks = [Pick]()
                        self.clubSongPicks = [Pick]()
                        self.clubSongCells = [Int: SongCell]()
                        self.requestUserAndClubSongData()
                        self.removeSpinner()
                    }
                })
        }
    }
}


// extension handles table data
extension PicksScreenSongMain: UITableViewDataSource {
        
    //sets the number of rows in the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView.restorationIdentifier == "MySongPicksTable") {
            return userSongPicks.count
        } else if (tableView.restorationIdentifier == "ClubSongPicksTable") {
            return clubSongPicks.count
        } else {
            return 0
        }
    }
    
    //updates table view data including the image and label
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (tableView.restorationIdentifier == "MySongPicksTable") {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell") as! UserSongCell
            //sets the label
            let mainLabel = cell.viewWithTag(1) as! UILabel
            mainLabel.text = userSongPicks[indexPath.row].itemData.name
            //sets the image
            let mainImageView = cell.viewWithTag(2) as! UIImageView
            mainImageView.image = userSongPicks[indexPath.row].itemData.image
            // sets the vote label
            self.updateVoteLable(index: indexPath.row, cell: cell)
            
            // creates a trash icon image gesture recognizer
            let tapGestureTrash = VoteTapGesture(target: self, action: #selector(PicksScreenSongMain.trash(gesture:)))
            tapGestureTrash.index = indexPath.row
            cell.trash_outlet.addGestureRecognizer(tapGestureTrash)

            return cell
        } else if (tableView.restorationIdentifier == "ClubSongPicksTable") {
            let cell = tableView.dequeueReusableCell(withIdentifier: "clubSongsCell") as! SongCell
            self.clubSongCells.updateValue(cell, forKey: indexPath.row)
            //sets the label
            let mainLabel = cell.viewWithTag(1) as! UILabel
            mainLabel.text = clubSongPicks[indexPath.row].itemData.name
            //sets the image
            let mainImageView = cell.viewWithTag(2) as! UIImageView
            mainImageView.image = clubSongPicks[indexPath.row].itemData.image
            // sets the name label
            let nameLabel = cell.viewWithTag(3) as! UILabel
            nameLabel.text = clubSongPicks[indexPath.row].userData.user_name
            // sets the vote label
            self.updateVoteLable(index: indexPath.row, cell: nil)
            
            // creates up vote image gesture recognizers
            let tapGestureUp = VoteTapGesture(target: self, action: #selector(PicksScreenSongMain.upVote(gesture:)))
            tapGestureUp.index = indexPath.row
            cell.upVote_outlet.addGestureRecognizer(tapGestureUp)
            cell.upVote_outlet.isUserInteractionEnabled = true
            
            // creates down vote image gesture recognizers
            let tapGestureDown = VoteTapGesture(target: self, action: #selector(PicksScreenSongMain.downVote(gesture:)))
            tapGestureDown.index = indexPath.row
            cell.downVote_outlet.addGestureRecognizer(tapGestureDown)
            cell.downVote_outlet.isUserInteractionEnabled = true
            
            // parses vote data
            self.parseVoteDataAt(index: indexPath.row)
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    // parses vote data for a userVoteID
    func parseVoteDataAt(index: Int) {
        let voteData = self.clubSongPicks[index].voteData
        if let up = voteData?.upVoteData["votesData"] as? [JSONStandard] {
            for i in 0..<up.count {
                let item = up[i]
                if item["user_id"] as! Int == userData.user_id! {
                    self.clubSongPicks[index].voteData.userVoteID = item["vote_id"] as? Int
                    self.clubSongCells[index]?.upVote_outlet.image = UIImage(named: "ArrowGreen")
                    return
                }
            }
        }
        if let down = voteData?.downVoteData["votesData"] as? [JSONStandard] {
            for i in 0..<down.count {
                let item = down[i]
                if item["user_id"] as! Int == userData.user_id! {
                    self.clubSongPicks[index].voteData.userVoteID = item["vote_id"] as? Int
                    self.clubSongCells[index]?.downVote_outlet.image = UIImage(named: "ArrowRed")
                    return
                }
            }
        }
    }
}

// custom table cell containing song vote outlets
class SongCell: UITableViewCell {
    @IBOutlet weak var upVote_outlet: UIImageView!
    @IBOutlet weak var downVote_outlet: UIImageView!
}

// custom table cell containing trash icon outlet
class UserSongCell: UITableViewCell {
    @IBOutlet weak var trash_outlet: UIImageView!
}

// custom tap gesture wtih the index of the table column
class VoteTapGesture: UITapGestureRecognizer {
    var index = Int()
}

