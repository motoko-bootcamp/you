import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import TFriends "./canisters/friends/types";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Bool "mo:base/Bool";
import Float "mo:base/Float";
import Http "http";
import Prim "mo:⛔";
import FriendsCan "canisters/friends/main";
import Friends "libs/friends";

shared ({ caller = creator }) actor class UserCanister(
    yourName : Text,
) = this {
    let NANOSECONDS_PER_DAY = 24 * 60 * 60 * 1_000_000_000;

    stable let version : (Nat, Nat, Nat) = (0, 0, 1);
    stable let birth : Time.Time = Time.now();
    stable let owner : Principal = creator;
    stable let name : Name = yourName;

    public type Mood = Text;
    public type Name = Text;
    public type Friend = TFriends.Friend;
    public type FriendRequest = TFriends.FriendRequest;
    public type FriendRequestResult = TFriends.FriendRequestResult;
    public type Result<Ok, Err> = Result.Result<Ok, Err>;

    stable var alive : Bool = true;
    stable var latestPing : Time.Time = Time.now();
    stable var modules : [(Text, Principal)] = [];
    
//-----------------------BASE-----------------------

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


//-----------------------END BASE-------------------
//-----------------------Friends--------------------

    public shared func reboot_user_receiveFriendRequest(
        name : Text,
        message : Text,
        senderPrincipal : Principal
    ) : async FriendRequestResult {

        assert(modules.size() > 0);
        let friendsCanisterId = getModule("friends");

        await Friends.reboot_user_receiveFriendRequest(name, message, senderPrincipal, friendsCanisterId);
    };

    public shared ({ caller }) func reboot_user_sendFriendRequest(
        receiver : Principal,
        message : Text,
    ) : async FriendRequestResult {

        assert(modules.size() > 0);
        assert (caller == owner);
        let friendsCanisterId = getModule("friends");

        await Friends.reboot_user_sendFriendRequest(receiver, message, friendsCanisterId);
    };

    public shared query func reboot_user_getModules () : async [(Text, Principal)] {
        return modules;
    };

    //Composite query has been removed given the necessity to call this function from others non-composite.
    public shared ({ caller }) func reboot_user_getFriendRequests() : async [FriendRequest] {
        assert (caller == owner);
        assert(modules.size() > 0);
        let friendsCanisterId = getModule("friends");

        await Friends.reboot_user_getFriendRequests(friendsCanisterId);
    };
    
    public shared ({ caller }) func reboot_user_handleFriendRequest(
        id : Nat,
        accept : Bool,
    ) : async Result<(), Text> {

        assert (caller == owner);
        assert(modules.size() > 0);
        let friendsCanisterId = getModule("friends");

        await Friends.reboot_user_handleFriendRequest(id, accept, friendsCanisterId);
    };
    
    //Composite query has been removed given the necessity to call this function from others non-composite.
    public shared ({ caller }) func reboot_user_getFriends() : async [Friend] {
        assert (caller == owner);
        let friendsCanisterId = getModule("friends");

        await Friends.reboot_user_getFriends(friendsCanisterId);
    };

    public shared ({ caller }) func reboot_user_removeFriend(
        canisterId : Principal
    ) : async Result<(), Text> {
        
        assert (caller == owner);
        let friendsCanisterId = getModule("friends");

        await Friends.reboot_user_removeFriend(canisterId, friendsCanisterId);
    };

//-----------------------END Friends----------------
//-----------------------Messages-------------------

    stable var messagesId : Nat = 0;
    var messages : [(Nat, Text)] = [];

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

        let messageBuffer : Buffer.Buffer<(Nat, Text)> = Buffer.fromArray(messages);

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

        let friends = await reboot_user_getFriends();

        // Check if the caller is already a friend
        for (friend in friends.vals()) {
            if (friend.canisterId == caller) {
                messageBuffer.add((messagesId, message));
                messages := Buffer.toArray(messageBuffer);
                messagesId += 1;
                return #ok();
            };
        };
        return #err(#NotAllowed);
    };

    public shared ({ caller }) func reboot_user_getMessages() : async [(Nat, Text)] {
        assert (caller == owner);
        return messages;
    };

    public shared ({ caller }) func reboot_user_readMessage(
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

    public shared ({ caller }) func reboot_user_readAllMessages() : async Result<(), Text> {
        assert (caller == owner);
        messages := [];
        return #ok();
    };

//-----------------------END Messages---------------
//-----------------------Admin----------------------

    public query func reboot_user_version() : async (Nat, Nat, Nat) {
        return version;
    };

    public shared ({ caller }) func reboot_user_installModule_friends () : async () {

        assert(caller == owner);

        let modulesBuff : Buffer.Buffer<(Text, Principal)> = Buffer.fromArray(modules);
        
        //Spawn a new friend canister
        try {
            Cycles.add<system>(1_000_000_000_000);
            
            let friendsCan = await FriendsCan.FriendsCanister(name);
            let friendsCanisterId = await friendsCan.reboot_friends_getCanisterId();

            modulesBuff.add(("friends", friendsCanisterId));
            modules := Buffer.toArray(modulesBuff);
        } catch (e) {
            throw e;
        };
    };

    public shared ({ caller }) func reboot_user_upgradeModule_friends() : async () {
        assert(caller == owner);

        //Spawn a new friend canister
        try {
            Cycles.add<system>(1_000_000_000_000);
            
                let Actor : FriendsCan.FriendsCanister = actor (Principal.toText(getModule("friends")));
                ignore await (system FriendsCan.FriendsCanister)(#upgrade Actor)("friends");

            return ();
        } catch (e) {
            throw e;
        };
    };

    private func getModule(moduleName : Text) : Principal {
        for (mod in modules.vals()) {
            if (mod.0 == moduleName) {
                return mod.1;
            };
        };
        return Principal.fromActor(this);
    };

    public type HttpRequest = Http.Request;
    public type HttpResponse = Http.Response;
    public shared func http_request(_request : HttpRequest) : async HttpResponse {

        let friendRequests = await reboot_user_getFriendRequests();
        let friends = await reboot_user_getFriends();

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

//-----------------------END Admin------------------

};
