import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Text "mo:base/Text";
import Friends "friends";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
shared ({ caller = creator }) actor class UserCanister(
    yourName : Text
) = this {

    public type Result<Ok, Err> = Result.Result<Ok, Err>;
    public type Mood = Text;
    public type Name = Text;
    public type Friend = Friends.Friend;
    public type FriendRequest = Friends.FriendRequest;
    public type FriendRequestResult = Friends.FriendRequestResult;

    stable let birth : Time.Time = Time.now();

    stable var friendRequestId : Nat = 0;
    stable var friendRequests : [Friends.FriendRequest] = [];
    stable var friends : [Friends.Friend] = [];

    let name : Name = yourName;
    let owner : Principal = creator;
    let nanosecondsPerDay = 24 * 60 * 60 * 1_000_000_000;

    let board = actor ("q3gy3-sqaaa-aaaas-aaajq-cai") : actor {
        reboot_writeDailyCheck : (name : Name, mood : Mood) -> async ();
    };

    stable var alive : Bool = true;
    stable var latestPing : Time.Time = Time.now();

    func _kill() : async () {
        let now = Time.now();
        if (now - latestPing > nanosecondsPerDay) {
            alive := false;
        };
    };

    // Timer to reset the alive status every 24 hours
    let _daily = Timer.recurringTimer<system>(#nanoseconds(nanosecondsPerDay), _kill);

    // The idea here is to have a function to call every 24 hours to indicate that you are alive
    public shared ({ caller }) func reboot_dailyCheck(
        mood : Mood
    ) : async () {
        assert (caller == owner);
        alive := true;
        latestPing := Time.now();

        // Write the daily check to the board
        try {
            await board.reboot_writeDailyCheck(name, mood);
        } catch (e) {
            throw e;
        };
    };

    public query func reboot_isAlive() : async Bool {
        return alive;
    };

    public query func reboot_supportedStandards() : async [{
        name : Text;
        url : Text;
    }] {
        return ([{
            name = "Reboot";
            url = "https://github.com/motoko-bootcamp/reboot/blob/main/standards/reboot.md";
        }]);
    };

    // public query func reboot_getName() : async Name {
    //     return name;
    // };

    // public query func reboot_getOwner() : async Principal {
    //     return owner;
    // };

    // public query func reboot_getBirth() : async Int {
    //     return birth;
    // };

    // public query func reboot_getAge() : async Int {
    //     return Time.now() - birth;
    // };

    public shared ({ caller }) func reboot_friends_receiveFriendRequest(
        name : Text,
        message : Text,
    ) : async FriendRequestResult {
        // Check if there is enough cycles attached (Fee for Friend Request) and accept them
        let availableCycles = Cycles.available();
        let acceptedCycles = Cycles.accept<system>(availableCycles);
        if (acceptedCycles < 1_000_000_000) {
            return #err(#NotEnoughCycles);
        };

        let request : FriendRequest = {
            id = friendRequestId;
            name = name;
            sender = caller;
            message = message;
        };

        // Check if the user is already a friend
        for (friend in friends.vals()) {
            if (friend.canisterId == caller) {
                return #err(#AlreadyFriend);
            };
        };

        // Check if the user has already sent a friend request
        for (request in friendRequests.vals()) {
            if (request.sender == caller) {
                return #err(#AlreadyRequested);
            };
        };

        friendRequests := Array.append<FriendRequest>(friendRequests, [request]);
        friendRequestId += 1;
        return #ok();
    };

    public shared ({ caller }) func reboot_friends_sendFriendRequest(
        receiver : Principal,
        message : Text,
    ) : async FriendRequestResult {
        assert (caller == owner);
        // Create the actor reference
        let friendActor = actor (Principal.toText(receiver)) : actor {
            reboot_friends_receiveFriendRequest : (name : Text, message : Text) -> async FriendRequestResult;
        };
        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);
        // Call the function (handle potential errors)
        try {
            return await friendActor.reboot_friends_receiveFriendRequest(name, message);
        } catch (e) {
            throw e;
        };
    };

    public shared query ({ caller }) func reboot_friends_getFriendRequests() : async [FriendRequest] {
        assert (caller == owner);
        return friendRequests;
    };

    public shared ({ caller }) func reboot_friends_handleFriendRequest(
        id : Nat,
        accept : Bool,
    ) : async Result<(), Text> {
        assert (caller == owner);
        // Check that the friend request exists
        for (request in friendRequests.vals()) {
            if (request.id == id) {
                // If the request is accepted
                if (accept) {
                    // Add the friend to the list
                    friends := Array.append<Friend>(friends, [{ name = request.name; canisterId = request.sender }]);
                    // Remove the request from the list
                    friendRequests := Array.filter<FriendRequest>(friendRequests, func(x) { x == id });
                    return #ok();
                } else {
                    // Remove the request from the list
                    friendRequests := Array.filter<FriendRequest>(friendRequests, func(x) { x == id });
                    return #ok();
                };
            };
        };
        return #err("Friend request not found for id " # Nat.toText(id));
    };

    public shared ({ caller }) func reboot_friends_getFriends() : async [Friend] {
        assert (caller == owner);
        return friends;
    };

    public shared ({ caller }) func reboot_friends_removeFriend(
        canisterId : Principal
    ) : async Result<(), Text> {
        assert (caller == owner);
        for (friend in friends.vals()) {
            if (friend.canisterId == canisterId) {
                friends := Array.filter<Friends.Friend>(friends, func(x : Friend) { x.canisterId == canisterId });
                return #ok();
            };
        };
        return #err("Friend not found with canisterId " # Principal.toText(canisterId));
    };

};
