import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Text "mo:base/Text";
import Friends "friends";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Bool "mo:base/Bool";
import Float "mo:base/Float";
import Http "http";
import Prim "mo:⛔";

shared ({ caller = creator }) actor class UserCanister(
    yourName : Text
) = this {
    let NANOSECONDS_PER_DAY = 24 * 60 * 60 * 1_000_000_000;

    stable let version : (Nat, Nat, Nat) = (0, 0, 1);
    stable let birth : Time.Time = Time.now();
    stable let owner : Principal = creator;
    stable let name : Name = yourName;

    public type Mood = Text;
    public type Name = Text;
    public type Friend = Friends.Friend;
    public type FriendRequest = Friends.FriendRequest;
    public type FriendRequestResult = Friends.FriendRequestResult;
    public type Result<Ok, Err> = Result.Result<Ok, Err>;

    stable var alive : Bool = true;
    stable var latestPing : Time.Time = Time.now();

    // Function to kill the user if they haven't pinged in 24 hours
    func _kill() : async () {
        let now = Time.now();
        if (now - latestPing > NANOSECONDS_PER_DAY) {
            alive := false;
        };
    };

    // Timer to reset the alive status every 24 hours
    let _daily = Timer.recurringTimer<system>(#nanoseconds(NANOSECONDS_PER_DAY), _kill);

    public query func reboot_user_isAlive() : async Bool {
        return alive;
    };

    // Import the board actor and related types
    public type WriteError = {
        #NotEnoughCycles;
        #MemoryFull;
        #NameTooLong;
        #MoodTooLong;
        #NotAllowed;
    };

    public type MessageError = {
        #NotEnoughCycles;
        #MemoryFull;
        #MessageTooLong;
        #NotAllowed;
    };

    let board = actor ("q3gy3-sqaaa-aaaas-aaajq-cai") : actor {
        reboot_board_write : (name : Name, mood : Mood) -> async Result<(), WriteError>;
    };

    public shared ({ caller }) func reboot_user_dailyCheck(
        mood : Mood
    ) : async Result<(), WriteError> {
        assert (caller == owner);
        alive := true;
        latestPing := Time.now();

        // Write the daily check to the board
        try {
            Cycles.add<system>(1_000_000_000);
            await board.reboot_board_write(name, mood);
        } catch (e) {
            throw e;
        };
    };

    stable var friendRequestId : Nat = 0;
    var friendRequests : [Friends.FriendRequest] = [];

    stable var friends : [Friends.Friend] = [];

    stable var messagesId : Nat = 0;
    var messages : [(Nat, Text)] = [];

    public shared ({ caller }) func reboot_user_receiveFriendRequest(
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

    public shared ({ caller }) func reboot_user_sendFriendRequest(
        receiver : Principal,
        message : Text,
    ) : async FriendRequestResult {
        assert (caller == owner);
        // Create the actor reference
        let friendActor = actor (Principal.toText(receiver)) : actor {
            reboot_user_receiveFriendRequest : (name : Text, message : Text) -> async FriendRequestResult;
        };
        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);
        // Call the function (handle potential errors)
        try {
            return await friendActor.reboot_user_receiveFriendRequest(name, message);
        } catch (e) {
            throw e;
        };
    };

    public shared query ({ caller }) func reboot_user_getFriendRequests() : async [FriendRequest] {
        assert (caller == owner);
        return friendRequests;
    };

    public shared ({ caller }) func reboot_user_handleFriendRequest(
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
                    friendRequests := Array.filter<FriendRequest>(friendRequests, func(request : FriendRequest) { request.id == id });
                    return #ok();
                } else {
                    // Remove the request from the list
                    friendRequests := Array.filter<FriendRequest>(friendRequests, func(request : FriendRequest) { request.id == id });
                    return #ok();
                };
            };
        };
        return #err("Friend request not found for id " # Nat.toText(id));
    };

    public shared ({ caller }) func reboot_user_getFriends() : async [Friend] {
        assert (caller == owner);
        return friends;
    };

    public shared ({ caller }) func reboot_user_removeFriend(
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

    public shared ({ caller }) func reboot_user_sendMessage(
        receiver : Principal,
        message : Text,
    ) : async Result<(), MessageError> {
        assert (caller == owner);
        // Create the actor reference
        let friendActor = actor (Principal.toText(receiver)) : actor {
            reboot_user_receiveMessage : (message : Text) -> async Result<(), MessageError>;
        };
        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);
        // Call the function (handle potential errors)
        try {
            return await friendActor.reboot_user_receiveMessage(message);
        } catch (e) {
            throw e;
        };
    };

    public shared ({ caller }) func reboot_user_receiveMessage(
        message : Text
    ) : async Result<(), MessageError> {
        // Check if there is enough cycles attached (Fee for Message) and accept them
        let availableCycles = Cycles.available();
        let acceptedCycles = Cycles.accept<system>(availableCycles);
        if (acceptedCycles < 1_000_000_000) {
            return #err(#NotEnoughCycles);
        };
        // Check that the message is not too long
        if (message.size() > 1024) {
            return #err(#MessageTooLong);
        };

        // Check if the caller is already a friend
        for (friend in friends.vals()) {
            if (friend.canisterId == caller) {
                messages := Array.append<(Nat, Text)>(messages, [(messagesId, message)]);
                messagesId += 1;
                return #ok();
            };
        };
        return #err(#NotAllowed);
    };

    public shared ({ caller }) func reboot_user_readMessages() : async [(Nat, Text)] {
        assert (caller == owner);
        return messages;
    };

    public shared ({ caller }) func reboot_user_clearMessage(
        id : Nat
    ) : async Result<(), Text> {
        assert (caller == owner);
        for (message in messages.vals()) {
            if (message.0 == id) {
                messages := Array.filter<(Nat, Text)>(messages, func(x : (Nat, Text)) { x.0 == id });
                return #ok();
            };
        };
        return #err("Message not found with id " # Nat.toText(id));
    };

    public shared ({ caller }) func reboot_user_clearAllMessages() : async Result<(), Text> {
        assert (caller == owner);
        messages := [];
        return #ok();
    };

    public query func reboot_user_version() : async (Nat, Nat, Nat) {
        return version;
    };

    public type HttpRequest = Http.Request;
    public type HttpResponse = Http.Response;
    public query func http_request(_request : HttpRequest) : async HttpResponse {
        return ({
            body = Text.encodeUtf8(
                "You\n"
                # "---\n"
                # "Name: " # name # "\n"
                # "Owner: " # Principal.toText(owner) # "\n"
                # "Birth: " # Int.toText(birth) # "\n"
                # "Alive: " # Bool.toText(alive) # "\n"
                # "Friends: " # Nat.toText(friends.size()) # "\n"
                # "Pending requests: " # Nat.toText(friendRequests.size()) # "\n"
                # "Pending messages: " # Nat.toText(messages.size()) # "\n"
                # "Version: " # Nat.toText(version.0) # "." # Nat.toText(version.1) # "." # Nat.toText(version.2) # "\n"
                # "Cycle Balance: " # Nat.toText(Cycles.balance()) # " cycles " # "(" # Nat.toText(Cycles.balance() / 1_000_000_000_000) # " T" # ")\n"
                # "Heap size (current): " # Nat.toText(Prim.rts_heap_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_heap_size() / (1024 * 1024))) # " Mb" # ")\n"
                # "Heap size (max): " # Nat.toText(Prim.rts_max_live_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_max_live_size() / (1024 * 1024))) # " Mb" # ")\n"
                # "Memory size: " # Nat.toText(Prim.rts_memory_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_memory_size() / (1024 * 1024))) # " Mb" # ")\n"
            );
            headers = [("Content-Type", "text/plain")];
            status_code = 200;
        });
    };

};
